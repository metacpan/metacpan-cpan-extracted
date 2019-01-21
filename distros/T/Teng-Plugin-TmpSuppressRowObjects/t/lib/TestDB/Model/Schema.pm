package TestDB::Model::Schema;
use strict;
use warnings;
use utf8;

use Teng::Schema::Declare;

table {
    name 'test_table';
    pk 'id';
    columns qw(
        id
        name
    );
};

1;
