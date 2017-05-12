use 5.006;    # our, pragmas
use strict;
use warnings;

package Moose::Meta::Attribute::Custom::Trait::Indexed;

our $VERSION = '2.000001';

# ABSTRACT: Registration Node for the Indexed Trait.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

sub register_implementation {
  return 'MooseX::AttributeIndexes::Meta::Attribute::Trait::Indexed';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Meta::Attribute::Custom::Trait::Indexed - Registration Node for the Indexed Trait.

=head1 VERSION

version 2.000001

=head1 METHODS

=head2 C<register_implementation>

Associates the Indexed trait with MX::AI

=head1 AUTHORS

=over 4

=item *

Kent Fredric <kentnl@cpan.org>

=item *

Jesse Luehrs <doy@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
