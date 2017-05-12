package # hide from PAUSE
    UnexpectedTest;
use strict;
use warnings;

use parent 'DBHelper';
use UnexpectedTest::Schema;

# lifted from DBIx::Class' DBICTest.pm
sub init_schema {
    my $self = shift;
    my %args = @_;

    return $self->_init_schema(
        %args,
        namespace           => __PACKAGE__,
        schema_class        => 'UnexpectedTest::Schema',
        db_file             => 't/var/unexpected.db',
        sql_file            => 't/lib/unexpected.sqlite.sql',
    );
}

sub populate_schema {
    # no populating required
}

1;
# vim: ts=8 sts=4 et sw=4 sr sta
