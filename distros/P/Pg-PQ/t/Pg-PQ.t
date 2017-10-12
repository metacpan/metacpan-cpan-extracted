#!/usr/bin/perl

use 5.010;

use strict;
use warnings;

use Test::More;
use Pg::PQ qw(:all);

sub conn_ok {
    my $conn = shift;
    goto &pass if $conn->status == CONNECTION_OK;
    diag sprintf "connection status: %s (%s)", $conn->status, $conn->errorMessage;
    goto &fail;
}

sub _test_result {
    my $res = shift;
    my $status = shift;
    my $rows = shift;
    goto &pass if ($status == $res->status and
                   ( not defined $rows or
                     $rows == ($status == PGRES_TUPLES_OK ? $res->rows : $res->cmdRows // 0)));
    diag sprintf("result status: %s, rows: %s, cmdRows: %s, expected: %s",
                 $res->status,
                 scalar($res->rows)//'<undef>',
                 $res->cmdRows//'<undef>',
                 $rows // '<undef>');
    goto &fail;
}

sub command_ok {
    my $res = shift;
    my $n = ((defined $_[0] and $_[0] =~ /^\d+$/) ? shift : undef);
    unshift @_, $res, PGRES_COMMAND_OK, $n;
    goto &_test_result
}

sub tuples_ok {
    my $res = shift;
    my $n = ((defined $_[0] and $_[0] =~ /^\d+$/) ? shift : 1);
    unshift @_, $res, PGRES_TUPLES_OK, $n;
    goto &_test_result;
}

unless (eval { require Test::PostgreSQL; 1 }) {
    plan skip_all => "Unable to load Test::PostgreSQL: $@";
}

my $tpg = Test::PostgreSQL->new;
unless ($tpg) {
    no warnings;
    plan skip_all => $Test::PostgreSQL::errstr;
}

plan tests => 22;

my %ci = (dbname => 'test',
          host   => '127.0.0.1',
          port   => $tpg->port,
          user   => 'postgres');

diag "conninfo: " . Pg::PQ::Conn::_make_conninfo(%ci);

my $conn = Pg::PQ::Conn->new(%ci);
conn_ok($conn, "connection");

my $res = $conn->exec("create table foo (id int)");
command_ok($res, "create table foo");

$res = $conn->exec('insert into foo (id) values ($1)', 8378);
command_ok($res, 1, "insert into foo");

$res = $conn->prepare(sth1 => 'insert into foo (id) values ($1)');
command_ok($res, "prepare insert into foo");

$res = $conn->execPrepared(sth1 => 11);
command_ok($res, "insert into foo prepared 11");

$res = $conn->execPrepared(sth1 => 12);
command_ok($res, "insert into foo prepared 12");

$res = $conn->execPrepared(sth1 => 13);
command_ok($res, "insert into foo prepared 13");

$res = $conn->execPrepared(sth1 => 14);
command_ok($res, "insert into foo prepared 14");

$res = $conn->prepare(sth2 => 'select id, id * id from foo where id > $1 order by id');
command_ok($res, "prepare select");

$res = $conn->execPrepared(sth2 => 12);
tuples_ok($res, 3, "select prepared");

is_deeply([$res->rows], [[13, 169], [14, 196], [8378, 70190884]], "rows");
is_deeply([$res->columns], [[13, 14, 8378], [169, 196, 70190884]], "columns");

ok($conn->sendQueryPrepared(sth2 => 12));
while (1) {
    $conn->consumeInput;
    last unless $conn->busy;
    sleep 1;
}

$res = $conn->result;
tuples_ok($res, 3, "select send prepared");

is_deeply([$res->rows], [[13, 169], [14, 196], [8378, 70190884]], "send rows");
is_deeply([$res->columns], [[13, 14, 8378], [169, 196, 70190884]], "send columns");


$res = $conn->exec("listen bar");
command_ok($res, "listen bar");

my $conn2 = Pg::PQ::Conn->new(%ci);
conn_ok($conn2, "conn2 connected");

$res = $conn2->exec("notify bar");

my ($name, $pid);
for (1..10) {
    $conn->consumeInput or last;
    if (($name, $pid) = $conn->notifies) {
        diag "notification received on iteration $_";
        last;
    }
    select undef, undef, undef, 0.25;
}

conn_ok($conn, "conn ok");
conn_ok($conn2, "conn2 ok");
is ($name, 'bar', "notification name");
is ($pid, $conn2->backendPID, "notification PID");

$conn2->finish;
$conn->finish;

