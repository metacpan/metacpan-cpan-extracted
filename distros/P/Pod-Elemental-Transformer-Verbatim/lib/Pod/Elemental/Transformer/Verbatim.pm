use strict;
use warnings;
package Pod::Elemental::Transformer::Verbatim; # git description: 8baf5a3
# ABSTRACT: Transform :verbatim regions into verbatim paragraphs
# KEYWORDS: pod transformer verbatim literal indent code text
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.001';

use Moose;
with 'Pod::Elemental::Transformer' => { -version => '0.101620' };

use Pod::Elemental::Types 'FormatName';
use Pod::Elemental::Element::Pod5::Verbatim;
use namespace::autoclean;

has format_name => (
    is  => 'ro',
    isa => FormatName,
    default => 'verbatim',
);

## TODO? customize the number of columns used for indenting
sub indent_level { 4 }

sub transform_node
{
    my ($self, $node) = @_;

    # why do we process in reverse? it should make no difference
    for my $i (reverse(0 .. $#{ $node->children })) {
        my $para = $node->children->[ $i ];
        next unless $self->__is_xformable($para);
        my @replacements = $self->_make_verbatim( $para );
        splice @{ $node->children }, $i, 1, @replacements;
    }

    return $node;
}

sub _make_verbatim
{
    my ($self, $parent) = @_;

    return map {
        my $para = $_;
        !$para->isa('Pod::Elemental::Element::Pod5::Ordinary')
            ? ($self->__is_xformable($para) ? $self->_make_verbatim($para) : $para)
            : length $para->content
            ? Pod::Elemental::Element::Pod5::Verbatim->new({
                content => join("\n", map { ' ' x $self->indent_level . $_ } split(/\n/, $para->content)),
              })
            : ();
    } @{ $parent->children };
}

# from ::List
sub __is_xformable
{
    my ($self, $para) = @_;

    return unless $para->isa('Pod::Elemental::Element::Pod5::Region')
        and $para->format_name eq $self->format_name;

    confess('verbatim regions must be pod (=begin :' . $self->format_name . ')')
        unless $para->is_pod;

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Transformer::Verbatim - Transform :verbatim regions into verbatim paragraphs

=head1 VERSION

version 0.001

=head1 SYNOPSIS

In your F<weaver.ini>:

     [-Transformer / Verbatim]
     transformer = Verbatim

Or in a plugin bundle:

    sub mvp_bundle_config {
        return (
            ...
            [ '@Author::YOU/Verbatim', _exp('-Transformer'), { 'transformer' => 'Verbatim' } ],
        );
    }

=head1 DESCRIPTION

This module acts as a L<pod transformer|Pod::Elemental::Transformer>, using
C<:verbatim> regions to mark sections of text for treatment as if they were
verbatim paragraphs. The transformer indents the contained text by four
columns, allowing the pod parser to treat them properly; see
L<perlpod/"Verbatim Paragraph">.

That is, this pod:

    =begin :verbatim

    Here is some text.

    =end :verbatim

Is transformed to:

        Here is some text

Note that a single paragraph can be simply noted with C<=for :verbatim> rather
than using C<=begin :verbatim> and C<=end :verbatim> lines.

=head1 ATTRIBUTES

=head2 format_name

This attribute (defaulting to C<verbatim>) is the region format that will be
processed by this transformer.

=head1 METHODS

=head2 transform_node

Given a pod document object, returns the object with all its children with
C<:verbatim> directives removed and appropriate content replaced with
L<Pod::Elemental::Element::Pod5::Verbatim> objects.

=for Pod::Coverage indent_level

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Elemental-Transformer-Verbatim>
(or L<bug-Pod-Elemental-Transformer-Verbatim@rt.cpan.org|mailto:bug-Pod-Elemental-Transformer-Verbatim@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver>

=back

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
