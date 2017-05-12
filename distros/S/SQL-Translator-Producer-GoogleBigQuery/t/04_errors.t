use strict;
use Test::More 0.98;

use DBI qw/:sql_types/;
use SQL::Translator;
use SQL::Translator::Producer::GoogleBigQuery;
use File::Spec;

eval { SQL::Translator::Producer::GoogleBigQuery::_type(999999, {}) };
like $@, qr/\A\QUnknown type: (unknown) (sql_data_type: 999999)/, 'unknown type error' or diag $@;

my $t = SQL::Translator->new();
$t->parser('MySQL') or die $t->error;
$t->filename(File::Spec->catfile('t', 'schema', 'mysql.sql'));

$t->producer('GoogleBigQuery', outdir => 't/foo/bar');
$t->translate;
like $t->error, qr!No such directory: t/foo/bar!, 'no such directory' or diag $t->error;

done_testing;
