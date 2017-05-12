#
# This file is part of MooseX-Attribute-Deflator
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::LazyInflator::Role::Class;
{
  $MooseX::Attribute::LazyInflator::Role::Class::VERSION = '2.2.2';
}

# ABSTRACT: Lazy inflate attributes
use Moose::Role;
use strict;
use warnings;

has _inflated_attributes => ( is => 'rw', isa => 'HashRef', lazy => 1, default => sub {{}} );


1;



=pod

=head1 NAME

MooseX::Attribute::LazyInflator::Role::Class - Lazy inflate attributes

=head1 VERSION

version 2.2.2

=head1 ATTRIBUTES

=over 8

=item B<_inflated_attributes>

This attributes keeps a HashRef of inflated attributes.

=back

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

