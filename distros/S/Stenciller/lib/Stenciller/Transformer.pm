use 5.10.1;
use strict;
use warnings;

package Stenciller::Transformer;

our $VERSION = '0.1400'; # VERSION:
# ABSTRACT: A role for transformer plugins to consume

use Moose::Role;
use Types::Standard qw/HashRef/;
use Types::Stenciller qw/Stenciller/;
use List::MoreUtils qw/first_index/;

requires 'transform';

has stenciller => (
    is => 'ro',
    isa => Stenciller,
    required => 1,
);

sub init_out {
    my $self = shift;
    my $stenciller = shift;
    my $transform_args = shift || {};

    my @out = ('');
    push (@out => $stenciller->all_header_lines, '') if !$transform_args->{'skip_header_lines'};
    return @out;
}

sub should_skip_stencil_by_index {
    my $self = shift;
    my $index = shift;
    my $transform_args = shift || {};
    return 1 if exists $transform_args->{'stencils'} && -1 == first_index { $_ == $index } @{ $transform_args->{'stencils'} };
    return 0;
}

sub should_skip_stencil {
    my $self = shift;
    my $stencil = shift;
    my $transform_args = shift || {};

    return 0 if !exists $transform_args->{'require_in_extra'};
    my $wanted_key = $transform_args->{'require_in_extra'}{'key'};
    my $required_value = $transform_args->{'require_in_extra'}{'value'};
    my $default_value = $transform_args->{'require_in_extra'}{'default'};

    return !$default_value if !defined $stencil->get_extra_setting($wanted_key);
    return !$stencil->get_extra_setting($wanted_key);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stenciller::Transformer - A role for transformer plugins to consume

=head1 VERSION

Version 0.1400, released 2016-02-03.



=head1 SYNOPSIS

    package Stenciller::Plugin::MyNewRenderer;

    use Moose;
    with 'Stenciller::Transformer';

    sub transformer {
        ...
    }

=head1 DESCRIPTION

This is the role that all L<Stenciller> plugins must consume. It requires a C<transformer> method to be implemented.

=head1 METHODS

=head2 transform

This method must be implemented by classes consuming this role.

It takes one attribute:

B<C<$transform_args>>

C<$transform_args> is a hash reference with the following structure:

    $transform_args => {
        skip_header_lines => 0|1,
        stencils => [...],
        require_in_extra => {
            key => '...',
            value => '...',
            default => '...',
        },
    }

B<C<skip_header_lines =E<gt> 1>>

C<skip_header_lines> takes a boolean indicating if the L<Stenciller's|Stenciller> header_lines should be skipped. Default is C<0>.

B<C<stencils =E<gt> [ ]>>

C<stencils> takes an array reference of which stencils in the currently parsed file that should be included in the output. The index is zero based. If C<stencils> is not given, all stencils are parsed.

B<C<require_in_extra =E<gt> { }>>

C<require_in_extra> allows finer filtering than C<stencils>. Usually, the point to using Stenciller, and
related modules, is to use the same content more than once (eg. include it in pod, create html files with
examples, and create tests). It is not always necessary to include every stencil in every end product.

If C<require_in_extra> is given, it looks in the options hash for every stencil for the C<key> key.

=over 4

=item *

If C<key> exists in the stencil's hash, and it has the C<value> value, then the stencil is parsed.

=item *

If C<key> exists in the stencil's hash, and it doesn't have the C<value> value, then the stencil is not parsed.

=item *

If C<key> doesn't exist in the stencil's hash, then the two first rules are applied as if the stencil had the C<default> value.

=back

=head1 ATTRIBUTES

=head2 stenciller

The L<Stenciller> object is passed automatically to plugins.

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
