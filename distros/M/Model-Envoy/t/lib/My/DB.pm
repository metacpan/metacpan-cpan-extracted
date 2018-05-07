package My::DB;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

sub db_connect {
    my( $schema, $filename ) = @_;

    $filename ||= '/tmp/testdata';

    return $schema->connect( "dbi:SQLite:dbname=$filename",'','');
}

__PACKAGE__->load_namespaces;

1;
