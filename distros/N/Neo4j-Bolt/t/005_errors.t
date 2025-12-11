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

unless (defined $neo_info) {
  plan skip_all => "DB tests not requested";
}

my $url = URI->new("bolt://".$neo_info->{host});

if ($neo_info->{user}) {
  $url->userinfo($neo_info->{user}.':'.$neo_info->{pass});
}

ok my $badcxn = Neo4j::Bolt->connect("bolt://localhost:16444");
ok !$badcxn->connected;
like $badcxn->errmsg, qr/Connection refused/, "client error msg correct";
is $badcxn->protocol_version,"", "protocol version empty";
throws_ok { $badcxn->run_query("match (a) return count(a)") } qr/No connection/, "query attempt throws";


ok my $cxn = Neo4j::Bolt->connect($url->as_string);
unless ($cxn->connected) {
  diag $cxn->errmsg;
}

SKIP: {
  skip "Couldn't connect to server", 6+2 unless $cxn->connected;
  ok my $stream = $cxn->run_query(
    "MATCH (a) RETRUN labels a",
   ), 'label count query';
  ok !$stream->success, "Not Succeeded";
  ok $stream->failure, "Failure";

  my $fd = $stream->get_failure_details();
  like $stream->server_errcode, qr/SyntaxError/, "got syntax error code";

  $cxn = Neo4j::Bolt->connect('snarf://localhost:7687');
  like $cxn->errmsg, qr/scheme/, "got errmsg";
  is $cxn->errnum, -12, "got error";
  
  $url->userinfo($neo_info->{user}.':blarf');
  SKIP: {
    skip "no neo_info pass", 2 unless $neo_info->{pass};
    $cxn = Neo4j::Bolt->connect($url->as_string);
    ok (!$cxn->connected, "bad pass, not connected");
    like $cxn->errmsg, qr/password is invalid/, "got unauthorized";
  }
  
}

done_testing;

