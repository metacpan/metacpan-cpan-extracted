package Perlanet::DBIx::Class::Types;
# ABSTRACT: All types used by Perlanet::DBIx::Class

use strict;
use warnings;
use base 'MooseX::Types::Combine';
use namespace::autoclean;

__PACKAGE__->provide_types_from(qw(
    MooseX::Types::DBIx::Class
));

1;


__END__
=pod

=head1 NAME

Perlanet::DBIx::Class::Types - All types used by Perlanet::DBIx::Class

=head1 VERSION

version 0.02

=head1 AUTHOR

  Oliver Charles <oliver@ocharles.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Oliver Charles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

