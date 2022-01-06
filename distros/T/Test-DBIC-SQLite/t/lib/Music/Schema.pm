use utf8;
package Music::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-14 01:57:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uoRonhRcnWwbKvlHK0BdYw

our $DB_VERSION = 1;

=head2 connection

Override the standard C<connection()> method to include the DB/SW-version check.

We pass the 4th argument to the version-check, this is the options-hash passed
to the C<connect()> method of the L<DBIx::Class::Schema> subclass.

=cut

sub connection {
    my $self = shift;
    $self->next::method(@_);
    $self->_on_connect($_[3]);
    return $self;
}

=head2 _on_connect();

This (private) method, checks if we can connect to the database by checking that
the (schema) version stored in the database is the same as this software is.

The version-check is skipped if the `ignore_version` attribute is true.

It is an implementation detail/choice how and where to store the (schema) version of
the database and that of the software (the L<DBIx::Class> generated ORM).

This example uses the I<Config> table with a single value stored in
I<db_version>. This version is also set whenever the C<deploy()> method on the
Schema is called.

=cut

sub _on_connect {
    my $self = shift;
    my $args = shift || {};

    return if $args->{ignore_version};

    my $db_version = $self->resultset('Config')->find({name => 'db_version'})->value;

    if ($db_version != $DB_VERSION) {
        die(
            sprintf("Database version has %d, expected value = %d", $db_version, $DB_VERSION)
        );
    }
}

sub deploy {
    my $self = shift;
    $self->next::method(@_);

    $self->resultset('Config')->populate(
        [
            {
                name  => 'db_version',
                value => $DB_VERSION
            }
        ]
    );
}
1;
