package Schema::Test::0_3_0::Result::Person;

use base qw(DBIx::Class::Core);
use strict;
use warnings;

our $VERSION = 0.02;

__PACKAGE__->load_components('InflateColumn::DateTime');
__PACKAGE__->table('person');
__PACKAGE__->add_columns(
	'person_id' => {
		'data_type' => 'integer',
		'is_auto_increment' => 1,
	},
	'email' => {
		'data_type' => 'text',
		'size' => 255,
		'is_nullable' => 1,
	},
	'name' => {
		'data_type' => 'text',
		'size' => 255,
		'is_nullable' => 1,
	},
	'created_at' => {
		'data_type' => 'datetime',
		'default_value' => 'CURRENT_TIMESTAMP',
	},
);
__PACKAGE__->set_primary_key('person_id');

1;

__END__

=pod

=encoding utf8

=head1 NAME

Schema::Test::0_3_0::Result::Person - DBIx::Class result class for the person table in schema version 0.3.0.

=head1 SYNOPSIS

 use Schema::Test::0_3_0::Result::Person;

 my $obj = Schema::Test::0_3_0::Result::Person->new(%params);
 my $table = $obj->table;
 my $table = Schema::Test::0_3_0::Result::Person->table;

=head1 DESCRIPTION

DBIx::Class result class for the C<person> table in the C<0.3.0> schema
version. The class inherits row behavior from L<DBIx::Class::Row> and source
behavior from L<DBIx::Class::ResultSourceProxy::Table>. It loads
L<DBIx::Class::InflateColumn::DateTime> for the C<created_at> column.

=head1 METHODS

=head2 C<new>

 my $obj = Schema::Test::0_3_0::Result::Person->new(%params);

Returns instance of object.

=head2 C<table>

 my $table = $obj->table;
 my $table = Schema::Test::0_3_0::Result::Person->table;

Get person table name.

Returns string.

=head1 SEE ALSO

=over

=item L<DBIx::Class::Row>

Base class for row instances returned by C<new>.

=item L<DBIx::Class::InflateColumn::DateTime>

Adds date and time column inflation for C<created_at>.

=item L<DBIx::Class::ResultSourceProxy::Table>

Provides the C<table> class method.

=back

=head1 DEPENDENCIES

L<DBIx::Class::Core>,
L<DBIx::Class::InflateColumn::DateTime>,
L<Schema::Test::0_3_0>

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
