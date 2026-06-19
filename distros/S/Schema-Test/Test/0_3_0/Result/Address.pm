package Schema::Test::0_3_0::Result::Address;

use base qw(DBIx::Class::Core);
use strict;
use warnings;

our $VERSION = 0.02;

__PACKAGE__->table('address');
__PACKAGE__->add_columns(
	'address_id' => {
		'data_type' => 'integer',
		'is_auto_increment' => 1,
	},
	'person_id' => {
		'data_type' => 'integer',
	},
);
__PACKAGE__->set_primary_key('address_id');
__PACKAGE__->belongs_to(
	'person',
	'Schema::Test::0_3_0::Result::Person',
	'person_id',
);

1;

__END__

=pod

=encoding utf8

=head1 NAME

Schema::Test::0_3_0::Result::Address - DBIx::Class result class for the address table in schema version 0.3.0.

=head1 SYNOPSIS

 use Schema::Test::0_3_0::Result::Address;

 my $obj = Schema::Test::0_3_0::Result::Address->new(%params);
 my $table = $obj->table;
 my $table = Schema::Test::0_3_0::Result::Address->table;

=head1 DESCRIPTION

DBIx::Class result class for the C<address> table in the C<0.3.0> schema
version. The class inherits row behavior from L<DBIx::Class::Row> and source
behavior from L<DBIx::Class::ResultSourceProxy::Table>. The table links to
C<person> through C<person_id>.

=head1 METHODS

=head2 C<new>

 my $obj = Schema::Test::0_3_0::Result::Address->new(%params);

Returns instance of object.

=head2 C<table>

 my $table = $obj->table;
 my $table = Schema::Test::0_3_0::Result::Address->table;

Get address table name.

Returns string.

=head2 C<belongs_to>

 Schema::Test::0_3_0::Result::Address->belongs_to(...);

Returns 1.

=head1 SEE ALSO

=over

=item L<DBIx::Class::Row>

Base class for row instances returned by C<new>.

=item L<DBIx::Class::ResultSourceProxy::Table>

Provides the C<table> class method.

=item L<Schema::Test::0_3_0::Result::Person>

Related result source for the referenced C<person> table.

=back

=head1 DEPENDENCIES

L<DBIx::Class::Core>,
L<Schema::Test::0_3_0::Result::Person>

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Schema-Test>

=head1 AUTHOR

Michal Josef Špaček E<lt>skim@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2022-2026 Michal Josef Špaček.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 VERSION

0.02

=cut
