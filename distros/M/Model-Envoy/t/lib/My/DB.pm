package My::DB;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

my $schema;

sub db_connect {
    my( $class ) = @_;

    $schema //= $class->connect( "dbi:SQLite:dbname=",'','');

    return $schema;
}

__PACKAGE__->load_namespaces;

1;
