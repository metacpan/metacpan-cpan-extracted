package RDF::Prefixes;

use 5.010;
use strict;
use constant {
	IDX_USED      => 0,
	IDX_SUGGESTED => 1,
	IDX_OPTIONS   => 2,
	NEXT_IDX      => 3,
};
use overload '%{}' => \&to_hashref;
use overload '""'  => \&to_string;
use utf8;

BEGIN {
	eval 'use Carp qw(carp); 1'
	or eval 'sub carp { warn "$_[0]\n" }'
}

BEGIN {
	$RDF::Prefixes::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Prefixes::VERSION   = '0.005';
}

# These are the rules from Turtle (W3C WD, dated 09 Aug 2011).
# XML 1.0 5e's syntax for XML names (i.e. element names,
# attribute names, etc) appears to be pretty similar except
# that it allows names to start with a colon or full-stop.
# (The former would violate XML namespaces, but is allowed by
# XML itself - apparently.)
#
# So anyway, we go with Turtle as that is the more restrictive
# syntax, thus any valid Turtle names should automatically be
# valid XML names.
#

my $PN_CHARS_BASE = qr<(?:
	[A-Z]
	| [a-z]
	| [\x{00C0}-\x{00D6}]
	| [\x{00D8}-\x{00F6}]
	| [\x{00F8}-\x{02FF}]
	| [\x{0370}-\x{037D}]
	| [\x{037F}-\x{1FFF}]
	| [\x{200C}-\x{200D}]
	| [\x{2070}-\x{218F}]
	| [\x{2C00}-\x{2FEF}]
	| [\x{3001}-\x{D7FF}]
	| [\x{F900}-\x{FDCF}]
	| [\x{FDF0}-\x{FFFD}]
	| [\x{10000}-\x{EFFFF}]
)>x;

my $PN_CHARS_U = qr<(?:
	$PN_CHARS_BASE
	| [_]
)>x;

my $PN_CHARS = qr<(?:
	$PN_CHARS_U
	| [0-9-]
	| [\x{00B7}]
	| [\x{0300}-\x{036F}]
	| [\x{203F}-\x{2040}]
)>x;

my $PN_PREFIX = qr<
	$PN_CHARS_BASE
	(?:
		(?: $PN_CHARS | [.] )*
		$PN_CHARS
	)?
>x;

my $PN_LOCAL = qr<
	(?: $PN_CHARS_U )   # change from Turtle: disallow digits here
	(?:
		(?: $PN_CHARS | [.] )*
		$PN_CHARS
	)?
>x;

sub new
{
	my ($class, $suggested, $options) = @_;
	$suggested ||= {};
	$options   ||= {};
	my $self = [{}, {}, $options];
		
	foreach my $s (reverse sort keys %$suggested)
	{
		if ($s =~ m< ^ $PN_PREFIX $ >ix)
		{
			$self->[IDX_SUGGESTED]{ $suggested->{$s} } = $s;
		}
		else
		{
			carp "Ignored suggestion $s => " . $suggested->{$s};
		}
	}
	
	bless $self, $class;
}

sub get_prefix
{
	my ($self, $url) = @_;
	my $pp = $self->_practical_prefix($url);
	$self->{ $pp } = $url;
	return $pp;
}

sub preview_prefix
{
	shift->_practical_prefix(@_);
}

sub _valid_qname
{
	my ($self, $p, $l) = @_;
	return undef unless defined $p && defined $l;
	return undef unless $l =~ m< ^ $PN_LOCAL $ >x;
	
	join q(:) => ($p, $l);
}

sub get_qname
{
	my ($self, $url) = @_;
	
	my ($p, $s) = $self->_split_qname($url);
	return undef unless defined $p and defined $s;
	
	return $self->_valid_qname($self->get_prefix($p), $s);
}

sub preview_qname
{
	my ($self, $url) = @_;
	
	my ($p, $s) = $self->_split_qname($url);
	return undef unless defined $p and defined $s;
	
	return $self->_valid_qname($self->preview_prefix($p), $s);
}

sub get_curie
{
	my ($self, $url) = @_;
	
	my ($p, $s) = $self->_split_qname($url);
	
	return $self->get_prefix($url) . ':'
		unless defined $p and defined $s;
	
	return $self->get_prefix($p) . ':' .  $s;
}

sub preview_curie
{
	my ($self, $url) = @_;
	
	my ($p, $s) = $self->_split_qname($url);
	
	return $self->preview_prefix($url) . ':'
		unless defined $p and defined $s;
	
	return $self->preview_prefix($p) . ':' . $s;
}

sub to_hashref
{
	my ($self) = @_;
	$self->[IDX_USED] ||= {};
	return $self->[IDX_USED];
}

*TO_JSON = \&to_hashref;

sub rdfa
{
	my ($self) = @_;
	my $rv;
	foreach my $prefix (sort keys %$self)
	{
		$rv .= sprintf("%s: %s ",
			$prefix,
			$self->{$prefix});
	}
	return substr($rv, 0, (length $rv) - 1);
}

sub sparql
{
	my ($self) = @_;
	my $rv;
	foreach my $prefix (sort keys %$self)
	{
		$rv .= sprintf("PREFIX %s: <%s>\n",
			$prefix,
			$self->{$prefix});
	}
	return $rv;
}

sub turtle
{
	my ($self) = @_;
	my $rv;
	foreach my $prefix (sort keys %$self)
	{
		$rv .= sprintf("\@prefix %-6s <%s> .\n",
			$prefix.':',
			$self->{$prefix});
	}
	return $rv;
}

sub xmlns
{
	my ($self) = @_;
	my $rv;
	foreach my $prefix (sort keys %$self)
	{
		$rv .= sprintf(" xmlns:%s=\"%s\"",
			$prefix,
			$self->{$prefix});
	}
	return $rv;
}

sub to_string
{
	my ($self) = @_;
	if (lc $self->[IDX_OPTIONS]{syntax} eq 'rdfa')
	{
		return $self->rdfa;
	}
	elsif (lc $self->[IDX_OPTIONS]{syntax} eq 'sparql')
	{
		return $self->sparql;
	}
	elsif (lc $self->[IDX_OPTIONS]{syntax} eq 'xmlns')
	{
		return $self->xmlns;
	}
	else
	{
		return $self->turtle;
	}
}

sub _split_qname
{
	my ($self, $uri) = @_;
        
   if ($uri =~ m< ($PN_LOCAL) $ >x)
	{
		my $ln  = $1;
		my $ns  = substr($uri, 0, length($uri)-length($ln));
		return ($ns, $ln);
	}
	
	return;
}

my $looks_like_version = qr< ^ [0-9\.-]+ $ >x;
my $too_generic        = qr< ^(?: terms|ns|vocab|vocabulary|rdf|rdfs|owl|schema|xsd )$ >x;

sub _perfect_prefix
{
	my ($self, $url) = @_;
	
	my $chosen = {
		'http://www.w3.org/1999/02/22-rdf-syntax-ns#' => 'rdf',
		'http://www.w3.org/2000/01/rdf-schema#'       => 'rdfs',
		'http://www.w3.org/2002/07/owl#'              => 'owl',
		'http://www.w3.org/2001/XMLSchema#'           => 'xsd',
		'http://schema.org/'                          => 'schema',
		}->{$url};
	
	return $chosen if length $chosen;

	my @words = map { lc; } ($url =~ m< ((?:$PN_CHARS|\.)+) >xg);
	WORD: while (defined(my $w = pop @words))
	{
		next WORD if (
			   length $w < 1
			or $w =~ $looks_like_version
			or $w =~ $too_generic
			or $w !~ m< ^ $PN_PREFIX $ >x
		);
		
		$chosen = $w;
		last WORD;
	}
	
	$chosen =~ s< [.] (owl|rdf|rdfx|rdfs|nt|ttl|turtle|xml|org|com|net) $ >()x;
	$chosen = 'ex' if $chosen eq 'example';
	return undef unless length $chosen;	
	return lc $chosen;
}

sub _practical_prefix
{
	my ($self, $url) = @_;
	
	my %existing = %{ $self->[IDX_USED] };
	while (my ($existing_prefix, $full) = each %existing)
	{
		return $existing_prefix if $full eq $url;
	}
	
	my $perfect = $self->[IDX_SUGGESTED]{$url}
		// $self->_perfect_prefix($url)
		// 'ns';
	return $perfect unless $self->_already($perfect);
	
	my $i = 2;
	while ($self->_already($perfect.$i))
	{
		$i++;
	}
	return $perfect.$i;
}

sub _already
{
	my ($self, $prefix) = @_;
	return grep { uc $prefix eq uc $_ } keys %$self;
}

1;

__END__

=head1 NAME

RDF::Prefixes - simple way to turn URIs into QNames

=head1 SYNOPSIS

 my $context = RDF::Prefixes->new;
 say $context->qname('http://purl.org/dc/terms/title');  # dc:title
 say $context->qname('http://example.net/rdf/dc#title'); # dc2:title
 say $context->turtle;  # @prefix dc: <http://purl.org/dc/terms/> .
                        # @prefix dc2: <http://example.net/rdf/dc#> .

=head1 DESCRIPTION

This module is not so much for managing namespaces/prefixes in code (see
L<RDF::Trine::NamespaceMap> for that), but as a helper for code that
serialises data using namespaces.

It generates pretty prefixes, reducing "http://purl.org/dc/terms/"
to "dc" rather than something too generic like like "ns01", and provides
a context for keeping track of namespaces already used, so that when
"http://purl.org/dc/elements/1.1/" is encountered, it won't stomp on
the previous definition of "dc".

=head2 Constructor

=over 4

=item C<< new(\%suggestions, \%options) >>

Creates a new RDF prefix context.

Suggestions for prefix mappings may be given, but there's no guarantee
that they'll be used.

The only option right now is 'syntax' that is used by the to_string
method.

Both hashrefs are optional.

=back

=head2 Methods

=over 4

=item C<< get_prefix($uri) >>

Gets the prefix associated with a URI. e.g.
C<< get_prefix('http://purl.org/dc/terms/') >> might return 'dc'.

=item C<< get_qname($uri) >>

Gets a QName for a URI. e.g.
C<< get_qname('http://purl.org/dc/terms/title') >> might return 'dc:title'.

Some URIs cannot be converted to QNames. In these cases, undef is returned.

=item C<< get_curie($uri) >>

As per C<get_qname>, but allows for more relaxed return values, suitable
for RDFa, Turtle or Notation 3, but not RDF/XML. Should never need to
return undef.

=item C<< preview_prefix($uri) >>,
C<< preview_qname($uri) >>,
C<< preview_curie($uri) >>

As per the "get" versions of these methods, but doesn't modify the
context.

=item C<< to_hashref >>

Returns a hashref of prefix mappings used so far. This is not especially
necessary as the object may be treated as a hashref directly:

  foreach my $prefix (keys %$context)
  {
    printf("%s => %s\n", $prefix, $context->{$prefix});
  }

=item C<< TO_JSON >>

A synonym for to_hashref, provided for the benefit of the L<JSON> package.

=item C<< rdfa >>

Return the same data as C<to_hashref>, but as a string suitable for
placing in an RDFa 1.1 prefix attribute.

=item C<< sparql >>

Return the same data as C<to_hashref>, but as a string suitable for
prefixing a SPARQL query.

=item C<< turtle >>

Return the same data as C<to_hashref>, but as a string suitable for
prefixing a Turtle or Notation 3 file.

=item C<< xmlns >>

Return the same data as C<to_hashref>, but as a string of xmlns
attributes, suitable for use with RDF/XML or RDFa.

=item C<< to_string >>

Calls either C<rdfa>, C<sparql>, C<turtle> (the default) or C<xmlns>, based on
the 'syntax' option passed to the constructor. This module overloads
the stringification operator, so explicitly calling to_string is rarely
necessary.

 my $context  = RDF::Prefixes->new({}, {syntax=>'turtle'});
 my $dc_title = 'http://purl.org/dc/terms/title';
 print "# Prefixes\n" . $context;

=back

=head2 Internationalisation

Strings passed to and from this module are expected to be utf8 character
strings, not byte strings. This is not explicitly checked for, but will
be checked in a future version, so be warned!

URIs containing non-Latin characters should "just work".

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2010-2013 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
