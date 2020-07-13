use strict;
use warnings;

use Test::More;
use Test::Deep;

use DBI;
use DBD::SQLite;

use Log::Any::Adapter qw(TAP);

use OpenTracing::Any qw($tracer);
use OpenTracing::Integration qw(DBI);

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', 'example_user');
$dbh->do(q{create temporary table example (id integer primary key autoincrement, data text)});
$dbh->do(q{insert into example (data) values ('example data here')});
$dbh->selectall_arrayref(q{select * from example});

my @spans = $tracer->span_list;
is(@spans, 4, 'have expected span count');
{
    my $span = shift @spans;
    is($span->operation_name, 'sql do: create temporary', 'have correct operation');
}
{
    my $span = shift @spans;
    is($span->operation_name, 'sql do: insert', 'have correct operation');
}
{
    my $span = shift @spans;
    is($span->operation_name, 'sql selectall: select', 'have correct operation');
    my %tags = $span->tags->%*;
    cmp_deeply(\%tags, superhashof({
        'component'       => 'DBI',
        'span.kind'       => 'client',
    }), 'have expected tags');

}
{
    my $span = shift @spans;
    is($span->operation_name, 'sql prepare: select', 'have correct operation');
    my %tags = $span->tags->%*;
    cmp_deeply(\%tags, superhashof({
        'component'       => 'DBI',
        'span.kind'       => 'client',
    }), 'have expected tags');

}
done_testing;


