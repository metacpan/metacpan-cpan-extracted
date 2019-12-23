use v5.10;
use Test::More;
use Test::Exception;
use File::Spec;
use Mock::Quick;
use lib qw{t ../lib};
use Data::Dumper;
use REST::Neo4p;
use ErrJ;
use JSON;
use strict;
use warnings;
no warnings qw/once/;

#$SIG{__DIE__} = sub { print $_[0] };
$REST::Neo4p::Query::BUFSIZE = 1000;

my $TESTDIR = (-d 't' ? 't' : '.');

open my $qfh,"<", \$ErrJ::resp or die $!;
diag 'query endpoint';
my $endpt = REST::Neo4p->q_endpoint;
my $mock_agt = qobj(
  batch_mode => 0,
  post_cypher => 1,
  post_transaction => qmeth { {commit => "http://localhost:7474/db/data/transaction/24/commit", errors => []} }
);
my $iofile_control = qtakeover 'IO::File';
$iofile_control->override(
  filename => 'mockfile'
);
my $iohandle_control = qtakeover 'IO::Handle';
$iohandle_control->override(
  filename => 'mockfile'
);
my $neo4p_control = qtakeover 'REST::Neo4p';
$neo4p_control->override(
  connected => 1,
  agent => sub { $mock_agt },
  neo4j_version => '203'
);
my $query_control = qtakeover 'REST::Neo4p::Query';
$query_control->override(
    tmpf => sub { $qfh }
)
;
my $q = REST::Neo4p::Query->new('fake query');
$q->{RaiseError} = 1;

ok $q->execute;
is_deeply $q->{NAME}, [qw/a r b/];
my $row = $q->fetch;
 isa_ok $row->[0],'REST::Neo4p::Node';
 isa_ok $row->[1],'REST::Neo4p::Relationship';
 isa_ok $row->[2],'REST::Neo4p::Node';


# now, break a Neo4j json stream in a number of ways
open $qfh,"<", \$ErrJ::badcol_resp;
throws_ok {$q->execute } qr/j_parse:.*not a query/i, 'not a query response';
isa_ok($@, 'REST::Neo4p::StreamException');
open $qfh,"<",\$ErrJ::baddata_resp;
throws_ok {$q->execute } qr/j_parse:.*Unexpected key 'baddata'/i, 'no data key';
isa_ok($@, 'REST::Neo4p::StreamException');
open $qfh,"<",\$ErrJ::badjson_resp;
ok $q->execute, 'execute';
throws_ok {$q->fetch} qr/j_parse:.*expected, at character/, 'bad json syntax';
isa_ok($@, 'REST::Neo4p::StreamException');
open $qfh,"<",\$ErrJ::baddataval_resp;
throws_ok {$q->execute} qr/j_parse: expecting an array value/, 'bad data value';
isa_ok($@, 'REST::Neo4p::StreamException');

1;
diag 'txn endpoint';
# txn
$DB::single=1;
REST::Neo4p->begin_work;
is (REST::Neo4p->_transaction, 24, 'mock txn');
open $qfh,"<",\$ErrJ::txn_resp;
ok $q->execute;
undef $q->{RaiseError};

while (my $row = $q->fetch) {
  is(ref,'HASH') foreach @$row;
  say encode_json($_) foreach @$row;
  $DB::single=1 if $row->[-1]{short_name} eq "Mojo::Server::PSGI::_IO";
}
diag $q->errobj->message;
isa_ok $q->errobj, 'REST::Neo4p::TxQueryException';
open $qfh,"<",\$ErrJ::txn_long_err_resp;
ok $q->execute;
while (my $row = $q->fetch) {
  is(ref,'HASH') foreach @$row;
}
diag $q->errobj->message;
isa_ok $q->errobj, 'REST::Neo4p::TxQueryException';

open $qfh,"<",\$ErrJ::txn_no_err_resp;

ok $q->execute;
while (my $row = $q->fetch) {
  is(ref,'HASH') foreach @$row;
  $DB::single=1 if $q->err;
}
diag $q->errobj->message if ($q->err);
ok !$q->err, 'no txn error';

open $qfh,"<",\$ErrJ::txn_baddata_resp;
$q->{RaiseError} =1 ;
throws_ok { $q->execute } qr/j_parse: expecting an array/, "data key points to object not array";
open $qfh,"<",\$ErrJ::txn_baddata2_resp;
throws_ok {$q->execute } qr/j_parse:.*Unexpected key 'baddata'/i, 'no data key';done_testing;
