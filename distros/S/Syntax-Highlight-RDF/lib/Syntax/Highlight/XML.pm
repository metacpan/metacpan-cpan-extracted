use 5.008;
use strict;
use warnings;

{
	package Syntax::Highlight::XML;

	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	
	our %STYLE = (
		xml_pointy      => '',
		xml_slash       => '',
		xml_equals      => '',
		xml_tagname     => '',
		xml_attributename     => 'color:#009999',
		xml_attributevalue    => 'color:#990099',
		xml_tag_start   => 'color:#0000CC',
		xml_tag_is_pi   => 'font-weight:bold',
		xml_tag_is_doctype    => 'font-weight:bold',
		"xml_attribute_is_xmlns .xml_attributename" => 'color:#009900',
		"xml_attribute_is_core  .xml_attributename" => 'color:#009900',
	);

	use MooX::Struct -retain, -rw,
		Feature                   => [],
		Token                     => [-extends => [qw<Feature>], qw($spelling!)],
		Name                      => [-extends => [qw<Token>]],
		Pointy                    => [-extends => [qw<Token>]],
		Equals                    => [-extends => [qw<Token>]],
		AttributeName             => [-extends => [qw<Name>]],
		AttributeValue            => [-extends => [qw<Token>]],
		Data                      => [-extends => [qw<Token>]],
		Data_Whitespace           => [-extends => [qw<Data>]],
		TagName                   => [-extends => [qw<Name>]],
		Slash                     => [-extends => [qw<Token>]],
		Whitespace                => [-extends => [qw<Token>]],
		Structure_Start           => [-extends => [qw<Feature>], qw($end)],
		Structure_End             => [-extends => [qw<Feature>], q($start) => [weak_ref => 1]],
		Attribute_Start           => [-extends => [qw<Structure_Start>], qw($name $value)],
		Attribute_End             => [-extends => [qw<Structure_End>]],
		Tag_Start                 => [-extends => [qw<Structure_Start>], qw($name +is_opening +is_closing +is_pi +is_doctype)],
		Tag_End                   => [-extends => [qw<Structure_End>]],
	;

	use Throwable::Factory
		Tokenization              => [qw( $remaining -caller )],
		NotImplemented            => [qw( -notimplemented )],
		WTF                       => [],
		WrongInvocant             => [qw( -caller )],
	;

	{
		use HTML::HTML5::Entities qw/encode_entities/;
		
		no strict 'refs';
		*{Feature    . "::tok"}        = sub { sprintf "%s~", $_[0]->TYPE };
		*{Token      . "::tok"}        = sub { sprintf "%s[%s]", $_[0]->TYPE, $_[0]->spelling };
		*{Whitespace . "::tok"}        = sub { $_[0]->TYPE };
		*{Data_Whitespace . "::tok"}   = sub { $_[0]->TYPE };
		*{Feature    . "::TO_STRING"}  = sub { "" };
		*{Token      . "::TO_STRING"}  = sub { $_[0]->spelling };
		*{Token      . "::TO_HTML"}    = sub {
			sprintf "<span class=\"xml_%s\">%s</span>", lc $_[0]->TYPE, encode_entities($_[0]->spelling)
		};
		*{Whitespace . "::TO_HTML"}  = sub { $_[0]->spelling };
		*{Data_Whitespace . "::TO_HTML"} = sub { $_[0]->spelling };
		*{Structure_Start . "::TO_HTML"} = sub {
			my @attrs = sprintf 'class="xml_%s"', lc $_[0]->TYPE;
			sprintf "<span %s>", join " ", @attrs;
		};
		*{Structure_End . "::TO_HTML"} = sub {
			"</span>"
		};
		*{Tag_Start . "::TO_HTML"} = sub {
			my @classes = sprintf 'xml_%s', lc $_[0]->TYPE;
			push @classes, "xml_tag_is_pi"        if $_[0]->is_pi;
			push @classes, "xml_tag_is_doctype"   if $_[0]->is_doctype;
			push @classes, "xml_tag_is_opening"   if $_[0]->is_opening;
			push @classes, "xml_tag_is_closing"   if $_[0]->is_closing;
			push @classes, "xml_tag_self_closing" if $_[0]->is_opening && $_[0]->is_closing;
			my @attrs = sprintf 'data-xml-name="%s"', $_[0]->name->spelling;
			sprintf '<span class="%s" %s>', join(" ", @classes), join(" ", @attrs);
		};
		*{Attribute_Start . "::TO_HTML"} = sub {
			my @classes = sprintf 'xml_%s', lc $_[0]->TYPE;
			push @classes, "xml_attribute_is_xmlns" if $_[0]->name->spelling =~ /^xmlns\b/;
			push @classes, "xml_attribute_is_core"  if $_[0]->name->spelling =~ /^xml\b/;
			my @attrs = sprintf 'data-xml-name="%s"', $_[0]->name->spelling;
			sprintf '<span class="%s" %s>', join(" ", @classes), join(" ", @attrs);
		};
	}

	use Moo;

	has _tokens     => (is => 'rw');
	has _remaining  => (is => 'rw');
	
	use IO::Detect qw( as_filehandle );
	use Scalar::Util qw( blessed );
		
	sub _peek
	{
		my $self = shift;
		my ($regexp) = @_;
		$regexp = qr{^(\Q$regexp\E)} unless ref $regexp;
		
		if (my @m = (${$self->_remaining} =~ $regexp))
		{
			return \@m;
		}
		
		return;
	}

	sub _pull_token
	{
		my $self = shift;
		my ($spelling, $class, %more) = @_;
		defined $spelling or WTF->throw("Tried to pull undef token!");
		substr(${$self->_remaining}, 0, length $spelling, "");
		push @{$self->_tokens}, $class->new(spelling => $spelling, %more);
		return $self->_tokens->[-1];
	}
	
	sub _pull_data
	{
		my $self = shift;
		my $data = (${$self->_remaining} =~ /^(.*?)</ms) ? $1 : ${$self->_remaining};
		$self->_pull_token($data, $data =~ /\S/ms ? Data : Data_Whitespace);
	}
	
	sub _pull_attribute_value
	{
		my $self = shift;
				
		${$self->_remaining} =~ /^(".*?")/m and return $self->_pull_token($1, AttributeValue);
		${$self->_remaining} =~ /^('.*?')/m and return $self->_pull_token($1, AttributeValue);
		
		Tokenization->throw(
			"Called _pull_attribute_value when remaining string doesn't look like an attribute value",
			remaining => ${$self->_remaining},
		);
	}
	
	sub _serializer
	{
		require RDF::Trine::Serializer::RDFXML;
		return "RDF::Trine::Serializer::RDFXML";
	}
	
	sub _scalarref
	{
		my $self = shift;
		my ($thing) = @_;
		
		if (blessed $thing and $thing->isa("RDF::Trine::Model") and $self->can("_serializer"))
		{
			my $t = $self->_serializer->new->serialize_model_to_string($thing);
			$thing = \$t
		}
		
		if (blessed $thing and $thing->isa("RDF::Trine::Iterator") and $thing->can("as_xml"))
		{
			my $t = $thing->as_xml;
			$thing = \$t
		}
		
		if (blessed $thing and $thing->isa("RDF::Trine::Iterator") and $self->can("_serializer"))
		{
			my $t = $self->_serializer->new->serialize_iterator_to_string($thing);
			$thing = \$t
		}
		
		if (blessed $thing and $thing->isa("XML::LibXML::Node"))
		{
			my $t = $thing->toString;
			$thing = \$t
		}
		
		unless (ref $thing eq 'SCALAR')
		{
			my $fh = as_filehandle($thing);
			local $/;
			my $t = <$fh>;
			$thing = \$t;
		}
		
		return $thing;
	}
	
	sub tokenize
	{
		my $self = shift;
		ref $self or WrongInvocant->throw("this is an object method!");
		
		$self->_remaining( $self->_scalarref(@_) );
		$self->_tokens([]);
		
		my ($TAG, $ATTR);
		
		# Declare this ahead of time for use in the big elsif!
		my $matches;
		
		while (length ${ $self->_remaining })
		{
			if ($matches = $self->_peek(qr#^(<[?!]?)#))
			{
				push @{$self->_tokens}, ($TAG = Tag_Start->new);
				$self->_pull_token($matches->[0], Pointy);
				if ($matches->[0] =~ /\!/)
				{
					$TAG->is_doctype(1);
				}
				elsif ($matches->[0] =~ /\?/)
				{
					$TAG->is_pi(1);
				}
			}
			elsif ($TAG and $matches = $self->_peek(qr#^(\??>)#))
			{
				my $end = Tag_End->new(start => $TAG);
				$TAG->end($end);
				$self->_pull_token($matches->[0], Pointy);
				push @{$self->_tokens}, $end;
				undef $TAG;
			}
			elsif ($TAG and $matches = $self->_peek(qr#^(\s+)#s))
			{
				$self->_pull_token($matches->[0], Whitespace);
			}
			elsif ($TAG and !$TAG->name and $matches = $self->_peek(qr#^((?:\w+[:])?\w+)#))
			{
				$TAG->name( $self->_pull_token($matches->[0], TagName) );
				if (!$TAG->is_closing)
				{
					$TAG->is_opening(1);
				}
			}
			elsif ($TAG and $TAG->name and $matches = $self->_peek(qr#^((?:\w+[:])?\w+)#))
			{
				if ($TAG->is_pi or $TAG->is_doctype)
				{
					$self->_pull_token($matches->[0], AttributeName);
				}
				else
				{
					push @{$self->_tokens}, ($ATTR = Attribute_Start->new);
					$ATTR->name( $self->_pull_token($matches->[0], AttributeName) );
				}
			}
			elsif ($TAG and $self->_peek("="))
			{
				$self->_pull_token("=", Equals);
			}
			elsif ($TAG and $self->_peek("/"))
			{
				$self->_pull_token("/", Slash);
				if (!$TAG->name)
				{
					$TAG->is_closing(1);
				}
			}
			elsif ($TAG and $self->_peek(qr{^["']}))
			{
				$self->_pull_attribute_value;
				if ($ATTR) # doctype?? pi??
				{
					my $end = Attribute_End->new(start => $ATTR);
					$ATTR->end($end);
					push @{$self->_tokens}, $end;
				}
			}
			else
			{
				$self->_pull_data;
			}
		}
		
		return $self->_tokens;
	}
	
	sub _fixup { 1 };
	
	sub highlight
	{
		my $self = shift;
		ref $self or WrongInvocant->throw("this is an object method!");
		
		$self->tokenize(@_);
		$self->_fixup;
		return join "", map $_->TO_HTML, @{$self->_tokens};
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Syntax::Highlight::XML - syntax highlighting for XML

=head1 SYNOPSIS

  use Syntax::Highlight::XML;
  my $syntax = "Syntax::Highlight::XML"->new;
  print $syntax->highlight($filehandle);

=head1 DESCRIPTION

Outputs pretty syntax-highlighted HTML for XML. (Actually just
adds C<< <span> >> elements with C<< class >> attributes. You're expected to
bring your own CSS.)

=head2 Methods

=over

=item C<< highlight($input) >>

Highlight some XML.

C<< $input >> may be a file handle, filename or a scalar ref of text.

Returns a string of HTML.

=item C<< tokenize($input) >>

This is mostly intended for subclassing Syntax::Highlight::XML.

C<< $input >> may be a file handle, filename or a scalar ref of text.

Returns an arrayref of token objects. The exact API for the token objects
is subject to change, but currently they support C<< TYPE >> and
C<< spelling >> methods.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Syntax-Highlight-RDF>.

=head1 SEE ALSO

L<Syntax::Highlight::JSON2>,
L<Syntax::Highlight::RDF>.

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

