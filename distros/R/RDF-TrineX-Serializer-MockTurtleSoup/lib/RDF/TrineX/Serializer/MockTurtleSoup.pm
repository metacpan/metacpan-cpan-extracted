package RDF::TrineX::Serializer::MockTurtleSoup;

use 5.010001;
use strict;
use warnings;
use utf8;

BEGIN {
	$RDF::TrineX::Serializer::MockTurtleSoup::AUTHORITY = 'cpan:TOBYINK';
	$RDF::TrineX::Serializer::MockTurtleSoup::VERSION   = '0.006';
}

use Carp;
use Sort::Key;
use RDF::Trine;
use RDF::Trine::Namespace qw( rdf rdfs );
use RDF::Prefixes;
use match::smart qw(match);

use parent 'RDF::Trine::Serializer';

sub new
{
	my $class = shift;
	my $self  = bless { @_==1 ? %{$_[0]} : @_ } => $class;
	
	$self->{prefixes}   ||= delete $self->{namespaces};
	$self->{labelling}  //= $rdfs->label->uri;
	$self->{priorities} ||= undef;
	$self->{abbreviate} //= undef;
	$self->{prefixes}   ||= {};
	$self->{colspace}   //= 20;
	$self->{indent}     ||= "\t";
	$self->{repeats}    //= 0;
	$self->{encoding}   ||= "utf8";
	$self->{apostrophe} //= 0;
	
	croak("Bad indent")
		unless $self->{indent} =~ /^\s+$/;
	croak("Bad encoding: expected 'utf8' or 'ascii'")
		unless $self->{encoding} =~ /^(ascii|utf8)$/;
	
	return $self;
}

sub serialize_model_to_file
{
	my $self = shift;
	my ($fh, $model) = @_;
	
	local $self->{model} = $model;
	local $self->{p}     = RDF::Prefixes->new($self->{prefixes});
	local $self->{B}     = 0;
	local $self->{b}     = {};
	
	my $bunches = $self->_divvy_up;
	$self->_sort_bunches($bunches);
	$self->_serialize_bunches($bunches, $fh);
}

sub _is_labelling
{
	my $self = shift;
	my ($st) = @_;
	return 1 if match($st->predicate->uri, $self->{labelling});
	return;
}

sub _node
{
	my $self = shift;
	my ($c, $t, $n) = @_;
	$n //= $t->$c;
	
	if ($c eq 'predicate' and $n->equal($rdf->type))
	{
		return 'a';
	}
	
	if ($c eq 'object'
	and defined $t
	and $t->predicate->equal($rdf->type)
	and $n->is_resource)
	{
		return $_ for grep defined, $self->{p}->get_qname($n->uri);
	}
	
	if ($n->is_resource
	and $c eq 'predicate' || match($n->uri, $self->{abbreviate}))
	{
		return $_ for grep defined, $self->{p}->get_qname($n->uri);
	}
	
	if ($n->is_literal and $n->has_datatype)
	{
		my $dt = $self->{p}->get_qname($n->literal_datatype);
		if ($dt eq 'xsd:integer' && $n->literal_value =~ /^[+-]?[0-9]+$/
		or  $dt eq 'xsd:decimal' && $n->literal_value =~ /^[+-]?[0-9]*\.[0-9]+$/
		or  $dt eq 'xsd:double'  && $n->literal_value =~ /^(?:(?:[+-]?[0-9]+\.[0-9]+)|(?:[+-]?\.[0-9]+)|(?:[+-]?[0-9]))[Ee][+-]?[0-9]+$/)
		{
			return $n->literal_value;
		}
		elsif ($dt eq 'xsd:boolean' && $n->literal_value =~ /^(true|false)$/i)
		{
			return lc $n->literal_value;
		}
		elsif (defined $dt)
		{
			return sprintf('%s^^%s', $self->_escaped_quoted_string($n->literal_value), $dt);
		}
	}
	elsif ($n->is_literal and $n->has_language)
	{
		return sprintf('%s@%s', $self->_escaped_quoted_string($n->literal_value), $n->literal_value_language);
	}
	elsif ($n->is_literal)
	{
		return $self->_escaped_quoted_string($n->literal_value);
	}
	
	if ($n->is_blank)
	{
		return($self->{b}{$n} //= '_:B' . ++$self->{B});
	}
	
	return $n->as_ntriples;
}

{
	my %ESCAPE = (
		"\t"     => "\\t",
		"\r"     => "\\r",
		"\n"     => "\\n",
		"\""     => "\\\"",
		"\'"     => "\\\'",
		"\\"     => "\\\\",
	);
	
	sub _escaped_quoted_string
	{
		my $self = shift;
		my ($str) = @_;
		
		my $quote = '"';
		my $chars = '\x00-\x1F\x5C';
		
		if ($self->{apostrophe} and $str =~ /\"/ and not $str =~ /\'/)
		{
			$quote = "'";
		}
		else
		{
			$chars .= '\x22'
		}
		
		if ($self->{encoding} eq "ascii")
		{
			$chars .= '\x{0080}-\x{10FFFF}';
		}
		
		$str =~ s{([$chars])}{
			exists($ESCAPE{$1}) ? $ESCAPE{$1} :
			ord($1) <= 0xFFFF   ? sprintf('\u%04X', ord($1)) : sprintf('\U%08X', ord($1))
		}xeg;
		
		"$quote$str$quote";
	}
}

sub _serialize_bunch
{
	my $self = shift;
	my ($bunch, $bunchmap, $indent, $in_brackets) = @_;
	$bunch->{done}++;
	
	my @triples = sort
	{
		($a->predicate->equal($rdf->type)   && !$b->predicate->equal($rdf->type)) ? -1 :
		($b->predicate->equal($rdf->type)   && !$a->predicate->equal($rdf->type)) ?  1 :
		($a->predicate->equal($rdf->type)   && !$b->predicate->equal($rdf->type)) ? -1 :
		($b->predicate->equal($rdf->type)   && !$a->predicate->equal($rdf->type)) ?  1 :
		($self->_is_labelling($a)           && !$self->_is_labelling($b)        ) ? -1 :
		($self->_is_labelling($b)           && !$self->_is_labelling($a)        ) ?  1 :
		($self->_node(predicate => $a) cmp $self->_node(predicate => $b) or $a->object->compare($b->object))
	}
		@{ $bunch->{triples} || [] };
	
	my $str;
	my $last_p;
	
#	$str .= "$indent### $bunch->{subject}\n";
	
	my $smiple = 1;
	if ($in_brackets)
	{
		$str .= "[\n";
		$indent .= $self->{indent};
	}
	elsif ($bunch->{subject}->is_blank
	and $bunch->{inline}
	and !$bunch->{inlist}
	and !$self->{model}->count_statements(undef, undef, $bunch->{subject}))
	{
		$str .= "$indent\[]\n";
	}
	else
	{
		$str .= $indent . $self->_node(subject => undef, $bunch->{subject}) . "\n" ;
	}
	
	for my $t (@triples)
	{
		if (defined $last_p and $last_p->equal($t->predicate) and not $self->{repeats}) {
			$str =~ s/;\n$/,/s;
		}
		else {
			$str .= "$indent$self->{indent}";
			$str .= sprintf($indent?"%s":"%-${\ $self->{colspace} }s", $self->_node(predicate => $t));
		}
		$str .= " ";
		
		$last_p = $t->predicate;
		
		if ($t->object->is_blank
		and $bunchmap->{$t->object}{inline}
		and $bunchmap->{$t->object}{list}
		and not $bunchmap->{$t->object}{done})
		{
			my @str;
			$smiple = 0;
			
			push my(@turds), (my $head = $t->object);
			while ($head)
			{
				my ($next) = $self->{model}->objects($head, $rdf->rest);
				last if $next->equal($rdf->nil);
				push @turds, ($head = $next);
			}
#			$str .= "$indent#TURDS: @turds\n";
			$bunchmap->{$_}{done}++ for @turds;
			
			for my $i (@{$bunchmap->{$t->object}{list}})
			{
				push @str, $self->_node(object => undef, $i);
			}
			
			$str .= "(@str)";
		}
		elsif ($t->object->is_blank
		and $bunchmap->{$t->object}{inline}
		and not $bunchmap->{$t->object}{done})
		{
			if (not @{$bunchmap->{$t->object}{triples}||[]}) {
				$str .= "[]";
			}
			else {
				$smiple = 0;
				$str .= $self->_serialize_bunch($bunchmap->{$t->object}, $bunchmap, "$indent", 1);
			}
		}
		else
		{
			my $x = $self->_node(object => $t);
			$str .= $x;
			$smiple = 0 if length($x) > 40;
		}
		$str .= ";\n";
	}
	
	if ($in_brackets)
	{
		$str .= "$indent]";
	}
	else
	{
		$str =~ s/;\n$/.\n/s ;
	}
	
	if ($in_brackets
	and length($str) < ($smiple ? 60 : 40)
	and $str =~ m{^\s*\[\s*(.+);\s*\]\s*$}sm)
	{
		(my $new = $1)
			=~ s/\;\n\s*/\; /gsm;
		return "[ $new ]";
	}
	
	return $str;
}

sub _serialize_bunches
{
	my $self = shift;
	my ($bunches, $fh) = @_;
	
	my $bunchmap = {};
	$bunchmap->{$_->{subject}} = $_ for @$bunches;
	
	my $str = "";
	
	for my $bunch (@$bunches) {
		next if $bunch->{done};
		next unless @{ $bunch->{triples} || [] };
		$str .= $self->_serialize_bunch($bunch, $bunchmap, "") . "\n";
	}
	
	print {$fh} $self->{p}->turtle, "\n", $str;
}

sub _get_priority
{
	my $self = shift;
	my ($bunch) = @_;
	my $n; $n = $self->{priorities}->($self, $bunch->{subject}, $self->{model}) if $self->{priorities};
	return $n if defined $n;
	return 0;
}

sub _sort_bunches
{
	my $self = shift;
	my ($bunches) = @_;
	
	my $sorter = Sort::Key::multikeysorter_inplace(
		sub {
			no warnings;
			$_->{isturd}+0,
			$self->_get_priority($_),
			ref($_->{subject}),
			$_->{inlist}+0,
			"$_->{subject}",
		},
		qw( int -int -str int str )
	);
	$sorter->($bunches);
}

sub _divvy_up
{
	my $self = shift;
	my $model = $self->{model};
	
	my %bnodes;
	my %d;
	my $stream = $model->as_stream;
	while (my $st = $stream->next)
	{
		$bnodes{$st->subject}//=0 if $st->subject->is_blank;
		$bnodes{$st->object}++ if $st->object->is_blank;
		push @{ $d{$st->subject}{triples} }, $st;
		$d{$st->subject}{subject} = $st->subject;
	}
	
	for my $k (keys %bnodes) {
		$d{$k}{inline}++ if $bnodes{$k}<=1;
		$d{$k}{subject} //= RDF::Trine::Node::Blank->new(substr $k, 2);
		if ($self->_check_valid_rdf_list($d{$k}{subject}, $model))
		{
			$d{$k}{list} = [ $model->get_list($d{$k}{subject}) ];
#			print "#LIST: ", join(" ", @{$d{$k}{list}}), "\n";
			$d{$_}{inlist}++ for grep !$_->is_literal, @{$d{$k}{list}};
		}
	}
	
	$d{$_->subject}{isturd}++ for $model->get_statements(undef, $rdf->rest, undef)->get_all;
		
#	use Data::Dumper; print Dumper \%d;
	[values %d];
}

sub _check_valid_rdf_list {
	require RDF::Trine::Serializer::Turtle;
	goto \&RDF::Trine::Serializer::Turtle::_check_valid_rdf_list;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

RDF::TrineX::Serializer::MockTurtleSoup - he's a bit slow, but he's sure good lookin'

=head1 SYNOPSIS

 use RDF::TrineX::Serializer::MockTurtleSoup;
 
 my $ser = "RDF::TrineX::Serializer::MockTurtleSoup"->new(%opts);
 $ser->serialize_model_to_file($fh, $model);

=head1 DESCRIPTION

Like L<RDF::Trine::Serializer::Turtle> but real pretty.

And slower.

And probably breaks with some complex graphs.

=head2 What's so pretty?

=over

=item *

Output interesting data first. Output URIs before bnodes. Output
rdf:type and rdfs:label before other predicates. Allow the user to
define criteria for what nodes are "interesting".

=item *

Use QNames for predicates, classes and datatypes, use full URIs
elsewhere. But also allow the user to supply a list of additional
URIs that will be abbreviated to QNames:

 "RDF::TrineX::Serializer::MockTurtleSoup"->new(
    abbreviate => [
       qr{^http://ontologi\.es/},
       qr{^http://purl\.org/},
       "http://www.google.com/",
    ],
 );

=item *

Generate those QNames using L<RDF::Prefixes> because it generates
awesome prefixes. (Better than "ns1", "ns2", etc.)

=item *

When data is equally interesting, sort alphabetically by subject,
predicate and object. When sorting by predicate, sort by the
predicate's QName, not its full URI.

=item *

Compact Turtle list syntax (mostly stolen from Greg's
L<RDF::Trine::Serializer::Turtle>)

=item *

Inline simple bnodes.

=item *

Indent nicely.

=back

=head2 Options

The constructor supports the following options:

=over

=item C<abbreviate>

This option will be used as the right-hand side of a smart match to
test URIs to see if they should be abbreviated to QNames.

URIs used as predicates or as the object of rdf:type triples are always
abbreviated anyway. URIs which cannot be abbreviated to a legal QName
will just be output as URIs.

=item C<apostrophe>

Boolean; if true, then the serializer will sometimes quote literals with
an apostrophe instead of double-quote marks. This is allowed by recent
versions of the Turtle spec, but was disallowed by earlier specifications,
and not widely supported yet. Defaults to false.

=item C<colspace>

This allows your predicate-object pairs to line up as nice columns. The
smaller the number, the closer they get. Default is 20.

=item C<encoding>

Either "ascii" or "utf8". Default is "utf8".

=item C<indent>

A whitespace string to indent by. The default is one tab character.
(God's chosen indentation.)

=item C<labelling>

This option will be used as the right-hand side of a smart match to
determine which URIs are considered to be equivalent to C<rdfs:label>.
The default is just C<http://www.w3.org/2000/01/rdf-schema#label>.

=item C<namespaces>

A hashref of prefix => URI pairs to define preferred QName prefixes.
There is no guarantee that these will be honoured, but they usually
will. L<RDF::Prefixes> does a damn good job without any help, so this
is generally pretty unnecessary.

=item C<priorities>

If defined, must be a coderef. The coderef will be called with arguments:
the serializer object itself, a node and the L<RDF::Trine::Model> being
serialized.

The coderef can use data within the model to determine how "interesting"
the node is. High numbers are very interesting. Negitive numbers are very
boring.

Interesting nodes are more likely to appear earlier on in the output.

Default is undef.

=item C<repeats>

Boolean. If false (the default), will output data like:

 <http://example.com/>
    dc:title "Cat"@en, "Chat"@fr.

If true, will output data like:

 <http://example.com/>
    dc:title "Cat"@en;
    dc:title "Chat"@fr.

=back

=head2 Methods

This module provides the same API as L<RDF::Trine::Serializer>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RDF-TrineX-Serializer-MockTurtleSoup>.

=head1 SEE ALSO

L<RDF::Trine::Serializer::Turtle>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

