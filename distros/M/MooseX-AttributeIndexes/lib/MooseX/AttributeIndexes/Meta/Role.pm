use 5.006;    # our, pragmas
use strict;
use warnings;

package MooseX::AttributeIndexes::Meta::Role;

our $VERSION = '2.000001';

# ABSTRACT: MetaRole for AttributeIndexes.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose::Role;

sub composition_class_roles {
  return 'MooseX::AttributeIndexes::Meta::Role::Composite';
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeIndexes::Meta::Role - MetaRole for AttributeIndexes.

=head1 VERSION

version 2.000001

=head1 METHODS

=head2 C<composition_class_roles>

returns C<MooseX::AttributeIndexes::Meta::Role::Composite>

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
