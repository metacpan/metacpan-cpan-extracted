#!perl
use Test::More tests => 3;
use Test::Exception;

use Pg::Explain;

throws_ok
    { my $explain = Pg::Explain->new( ) }
    qr/One of \(source, source_file\) parameters has to be provided/,
    'No arguments - caught ok.';

throws_ok
    { my $explain = Pg::Explain->new( 'source_file' => 't/non-existant-file' ) }
    qr{Can't open 't/non-existant-file'},
    'Bad filename - caught ok.';

throws_ok
    { my $explain = Pg::Explain->new( 'source_file' => 't/explain-file-simple.output', 'source' => 'Seq Scan on tenk1  (cost=0.00..333.00 rows=10000 width=148)' ) }
    qr{Only one of \(source, source_file\) parameters has to be provided},
    'Both source arguments - caught ok.';

