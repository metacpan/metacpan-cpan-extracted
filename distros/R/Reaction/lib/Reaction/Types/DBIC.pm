package Reaction::Types::DBIC;

use MooseX::Types
    -declare => [qw/ResultSet Row/];

use Moose::Util::TypeConstraints;

use DBIx::Class::ResultSet;

subtype 'DBIx::Class::ResultSet'
  => as 'Object'
  => where { $_->isa('DBIx::Class::ResultSet') };

subtype ResultSet,
  as 'DBIx::Class::ResultSet';

use DBIx::Class::Core;
use DBIx::Class::Row;

subtype 'DBIx::Class::Row'
  => as 'Object'
  => where { $_->isa('DBIx::Class::Row') };

subtype Row,
  as 'DBIx::Class::Row';

1;

=head1 NAME

Reaction::Types::DBIC

=head1 DESCRIPTION

=over

=item * DBIx::Class::ResultSet

=item * DBIx::Class::Row

=back

=head1 SEE ALSO

=over

=item * L<Reaction::Types::Core>

=back

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
