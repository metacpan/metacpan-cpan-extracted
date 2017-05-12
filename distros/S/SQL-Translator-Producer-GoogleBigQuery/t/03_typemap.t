use strict;
use Test::More 0.98;

use DBI qw/:sql_types/;
use SQL::Translator;
use File::Spec;

my $t = SQL::Translator->new();
$t->parser('MySQL') or die $t->error;
$t->filename(File::Spec->catfile('t', 'schema', 'mysql.sql'));

$t->producer('GoogleBigQuery', typemap => { SQL_INTEGER() => 'string' });
my $result = $t->translate or die $t->error;
is_deeply $result => [
    {
        name   => 'author',
        schema => [
            {
                name => 'id',
                type => 'string',
            },
            {
                name => 'name',
                type => 'string',
            },
        ],
    },
    {
        name   => 'module',
        schema => [
            {
                name => 'id',
                type => 'string',
            },
            {
                name => 'name',
                type => 'string',
            },
            {
                name => 'author_id',
                type => 'string',
            },
        ],
    },
];

done_testing;
