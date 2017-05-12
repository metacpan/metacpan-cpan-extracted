use 5.10.1;
use strict;
use warnings;

package Stenciller::Plugin::ToUnparsedText;

our $VERSION = '0.1400'; # VERSION:
# ABSTRACT: A plugin that doesn't transform the text

use Moose;
with 'Stenciller::Transformer';
use namespace::autoclean;

use List::MoreUtils qw/first_index/;
use Types::Standard qw/Bool/;

has text_as_html_pod => (
    is => 'ro',
    isa => Bool,
    default => 0,
);

sub transform {
    my $self = shift;
    my $transform_args = shift;

    my @out = $self->init_out($self->stenciller, $transform_args);

    STENCIL:
    for my $i (0 .. $self->stenciller->max_stencil_index) {
        next STENCIL if $self->should_skip_stencil_by_index($i, $transform_args);

        my $stencil = $self->stenciller->get_stencil($i);
        next STENCIL if $self->should_skip_stencil($stencil, $transform_args);

        push @out => '',
                     $self->maybe_as_html_pod($stencil->all_before_input), '',
                     $stencil->all_input, '',
                     $self->maybe_as_html_pod($stencil->all_between), '',
                     $stencil->all_output, '',
                     $self->maybe_as_html_pod($stencil->all_after_output), '';
    }
    my $content = join "\n" => '', @out, '';
    $content =~ s{\v{2,}}{\n\n}g;
    return $content;
}

sub maybe_as_html_pod {
    my $self = shift;
    my @text = @_;

    return @text if !$self->text_as_html_pod;
    return @text if !scalar @text;

    unshift @text => '', '=begin html', '';
    push @text => '', '=end html', '';
    return @text;

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stenciller::Plugin::ToUnparsedText - A plugin that doesn't transform the text

=head1 VERSION

Version 0.1400, released 2016-02-03.



=head1 SYNOPSIS

    use Stenciller;
    my $stenciller = Stenciller->new(filepath => 't/corpus/test-1.stencil');
    my $content = $stenciller->transform('ToUnparsedText');

=head1 DESCRIPTION

This plugin to L<Stenciller> basically returns all text content of the stencils.

If this plugin is used via L<Pod::Elemental::Transformer::Stenciller> it could be used like this in pod:

    =pod

    # includes header_lines and all stencils
    :stenciller ToUnparsedText atestfile-1.stencil

    # includes header_lines and all stencils
    :stenciller ToUnparsedText atestfile-1.stencil { }

    # includes only the first stencil in the file
    :stenciller ToUnparsedText atestfile-1.stencil { stencils => [0], skip_header_lines => 1 }

    # includes only the header_lines
    :stenciller ToUnparsedText atestfile-1.stencil { stencils => [] }

=head1 ATTRIBUTES

=head2 text_as_html_pod

Default: 0

If set to a true value, the parts that are neither C<input> or C<output> will be rendered between C<=begin html> and C<=end html>. This is useful
when rendering the same stencils to html examples files as well as including in pod.

=head1 METHODS

=head2 transform

See L<transform|Stenciller::Transformer/"transform"> in L<Stenciller::Transformer>.

=head1 SOURCE

L<https://github.com/Csson/p5-Stenciller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Stenciller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
