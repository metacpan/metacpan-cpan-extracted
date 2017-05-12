package SVG::Rasterize::TextNode;
use strict;
use warnings;

use Params::Validate qw(:types validate_with);

# $Id: TextNode.pm 5971 2010-06-06 09:34:40Z mullet $

=head1 NAME

C<SVG::Rasterize::TextNode> - workaround to represent a text node

=head1 VERSION

Version 0.003002

=cut

our $VERSION = '0.003002';

sub new {
    my ($class, @args) = @_;

    my $self = bless {}, $class;
    return $self->init(@args);
}

sub init {
    my ($self, @args) = @_;
    my %args          = validate_with
	(params  => \@args,
	 spec    => {data => {type => SCALAR}},
	 on_fail => sub { SVG::Rasterize->ex_pv($_[0]) });

    $self->{data} = $args{data};

    return $self;
}

sub getNodeName   { return '#text' }
sub getAttributes { return undef }
sub getChildNodes { return undef }

sub getData { return $_[0]->{data} }

1;


__END__

=pod

=head1 DESCRIPTION

=head2 The Problem

According to the C<DOM> specification which
L<SVG::Rasterize|SVG::Rasterize> uses to traverse C<SVG> document
trees, basically everything is a node including simple text. This
means that if an C<SVG> element contains text (e.g. a C<text> or
C<tspan> element), the C<getChildNodes> method is supposed to return
not only the child elements, but also the character data (i.e. text)
sections in this list of nodes. However, the C<getChildNodes> method
of the L<SVG::Element|SVG::Element> class in the L<SVG|SVG>
distribution only returns the child elements, no character data
section.

L<SVG::Rasterize|SVG::Rasterize> tries to support not only
L<SVG|SVG> object trees, but also C<DOM> trees created by a generic
C<XML> parser. Due to the behaviour described above, these two
scenarios have to be treated differently.

=head2 The Solution (or Workaround)

This class acts as a drop-in for a C<SVG> node class representing a
character data node. When parsing a L<SVG|SVG> object tree,
character data of the relevant elements are stored in such an object
and pushed to the list of child nodes. Afterwards, the object tree
can be accessed uniformly.

This process does not get around the problem that in an
L<SVG::Element|SVG::Element> object cannot hold multiple character
data sections and that it cannot store the order of such sections
and child elements. However, this problem can only be solved within
the L<SVG|SVG> distribution (see
L<RT#58153|https://rt.cpan.org/Public/Bug/Display.html?id=58153>).

=head1 INTERFACE

The interface only implements (apart from the constructor) the
minimal requirements of L<SVG::Rasterize|SVG::Rasterize/SVG Input>,
e.g. the following methods:

=head3 new

  $node = SVG::Rasterize::TextNode->new(%args)

Creates a new C<SVG::Rasterize::TextNode> object and calls
C<init(%args)>. If you subclass C<SVG::Rasterize::TextNode> overload
L<init|/init>, not C<new>.

Supported arguments:

=over 4

=item * data (mandatory): a SCALAR as defined by
L<Params::Validate|Params::Validate>, containing the text data.

=back

=head3 init

See new for a description of the interface. If you overload C<init>,
your method should also call this one.

=head3 getNodeName

Returns C<#text>.

=head3 getAttributes

Returns C<undef>.

=head3 getChildNodes

Returns C<undef>.

=head3 getData

Returns the text.

=head1 SEE ALSO

=over 4

=item * L<SVG::Rasterize|SVG::Rasterize>

=item * L<SVG|SVG>

=item * L<http://www.w3.org/TR/1998/REC-DOM-Level-1-19981001/level-one-core.html#ID-1590626202>

=back


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
