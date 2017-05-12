use 5.10.1;
use strict;
use warnings;

package Types::Stenciller;

our $VERSION = '0.1400'; # VERSION
# ABSTRACT: Types for Stenciller

use Type::Library -base, -declare => qw/Stencil Stenciller/;
use Type::Utils -all;

class_type Stenciller => { class => 'Stenciller' };
class_type Stencil    => { class => 'Stenciller::Stencil' };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::Stenciller - Types for Stenciller

=head1 VERSION

Version 0.1400, released 2016-02-03.



=head1 SYNOPSIS

    use Types::Stenciller -types;

=head1 DESCRIPTION

Defines a couple of types used in the C<Stenciller> namespace.

=head1 TYPES

=over 4

=item *

C<Stenciller> is a L<Stenciller>

=item *

C<Stencil> is a L<Stenciller::Stencil>

=back

It also inherits from L<Types::Standard> and L<Types::Path::Tiny>.

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
