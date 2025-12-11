use v5.12;
use warnings;
use Test::More;
use Test::Exception;
use Try::Tiny;
use URI::bolt;
use Cwd qw/getcwd/;
use Neo4j::Bolt;
use File::Spec;

my $neo_info;
my $nif = File::Spec->catfile('t','neo_info');
if (-e $nif ) {
    local $/;
    open my $fh, "<", $nif or die $!;
    my $val = <$fh>;
    $val =~ s/^.*?(=.*)$/\$neo_info $1/s;
    eval $val;
}

unless (defined $neo_info && $neo_info->{tests}) {
  plan skip_all => "DB tests not requested";
}

my $url = URI::bolt->new("bolt://".$neo_info->{host});

if ($neo_info->{user}) {
  $url->userinfo($neo_info->{user}.':'.$neo_info->{pass});
}
diag $url->as_string if $ENV{AUTHOR_TESTING};

# ok(Neo4j::Bolt->set_log_level("TRACE"), "log level TRACE");
ok my $cxn = Neo4j::Bolt->connect($url->as_string);
unless ($cxn->connected) {
  diag "hey ->".$cxn->errmsg;
}

SKIP: {
  skip "Couldn't connect to server", 1 unless $cxn->connected;
  my ($Mv,$mv) = $cxn->protocol_version =~ /^([0-9]+)\.([0-9]*)$/;
  diag $cxn->protocol_version;
  skip "Bolt version 3+ required", 1 unless $Mv >= 3;
  ok my $txn = Neo4j::Bolt::Txn->new($cxn), "create a new transaction on the connection";
  isa_ok($txn, 'Neo4j::Bolt::Txn');
  ok $txn->commit, "commit succeeds";
  ok !$txn->commit, "recommit fails";
  ok $txn = Neo4j::Bolt::Txn->new($cxn);
  ok $txn->rollback, "rollback succeeds (new txn)";
  ok !$txn->rollback, "you only live once";
  ok $txn = Neo4j::Bolt::Txn->new($cxn, { tx_timeout => 10000, dbname => "neo4j" });
  $txn->run_query("create (a:zzyyxx123)");
  # if you do $cxn->run_query ---- the commit/rollback segfaults......
  my $rs = $cxn->run_query("match (a:zzyyxx123) return count(a)");
  is (($rs->fetch_next)[0], 1, "now you see it");
  ok $txn->rollback, "rollback";
  #ok $txn->commit, "commit";
  ok $rs = $cxn->run_query("match (a:zzyyxx123) return count(a)");
  ok !$rs->fetch_next, "now you dont";
  my $badrs = $txn->run_query("match (a) return count(a)");
  ok !$badrs->success, "run query doesn't work on closed txn";
  
}

done_testing;
