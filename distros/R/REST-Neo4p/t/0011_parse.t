use 5.10.1;
use Test::More;
use File::Spec;
#use Devel::Leak;
use lib '../lib';
use REST::Neo4p::ParseStream;
use JSON::XS;
use HOP::Stream qw/head tail drop/;
use experimental;
use strict;
use warnings;
#$SIG{__DIE__} = sub { print $_[0] };

my $TESTDIR = (-d 't' ? 't' : '.');
my $CHUNK = 10000;
my $j = JSON::XS->new;

open my $f, File::Spec->catfile($TESTDIR,'samples','qry-response.txt') or die $!;
open my $g, File::Spec->catfile($TESTDIR, 'samples', 'batch-response.txt') or die $!;
open my $k, File::Spec->catfile($TESTDIR,'samples','txn-response.txt') or die $!;

my $buf;
my $i=0;
my @objs;
my ($res,$str);
my ($r_obj,$ar);
my ($obj,@rows);

my $handle;

read $g,$buf,$CHUNK or die $!;
$j->incr_parse($buf);
ok $res = j_parse($j), "parsing batch response";
is $res->[0], 'BATCH', "is batch response";

$str = $res->[1]->();
isa_ok($str, 'HOP::Stream');

my ($ct,$newct);

while (my $obj = drop($str)) {
  use experimental 'smartmatch';
  is $obj->[0],'ARELT', "is array elt";
  given ($obj->[1]) {
    when(ref eq 'HASH'){
      push @objs, $obj->[1];
      pass "value is hashref";
    }
    when('PENDING') {
      read $g, $buf,$CHUNK;
      $j->incr_parse($buf);
    }
    default {
      fail "shouldn't be here";
    }
  }
  1;
}

is @objs, 31, "Got all batch responses (31)";
is $j->incr_text,'', "All text consumed";
 undef @objs;
 undef $j;
 undef $res;
 undef $str;

$j = JSON::XS->new();
read ($f, $buf,$CHUNK) or die $!;
$j->incr_parse($buf);
ok $res = j_parse($j), "parsing qry response";
is $res->[0],'QUERY', "is query response";


$str = $res->[1]->();
isa_ok($str, 'HOP::Stream');
ok $obj = drop($str);
is $obj->[0],'columns', 'got columns key';
is_deeply $obj->[1], [qw/a r b/], 'got column name array';
ok $obj = drop($str);
is $obj->[0],'data', 'got data key';
ok $ar = $obj->[1]->(), 'got array stream';
isa_ok($ar,'HOP::Stream');
ok $obj = drop($str), 'get paused stream entry';
is_deeply $obj, [qw/data DATA_STREAM/], 'paused for data stream';
while (my $obj = drop($ar)) {
  use experimental 'smartmatch';
  is $obj->[0],'ARELT', "is array elt";
  given ($obj->[1]) {
    when(ref eq 'ARRAY'){
      push @rows, $obj->[1];
      pass "value is arrayref";
    }
    when('PENDING') {
      read $f, $buf,$CHUNK;
      $j->incr_parse($buf);
    }
    default {
      fail "shouldn't be here";
    }
  }
}
is @rows, 131, 'got all rows';
ok !drop($ar), 'array stream done';

drop($str);
ok !drop($str), 'object stream done';
is $j->incr_text,'', 'all text consumed';



$j = JSON::XS->new();
read($k, $buf,$CHUNK) or die $!;
$j->incr_parse($buf);
ok $res = j_parse($j), "parsing txn response";
is $res->[0],'TXN', "is txn response";
$str = $res->[1]->();
isa_ok($str, 'HOP::Stream');
ok $obj = drop($str);
is $obj->[0],'commit', "got commit key";
like $obj->[1], qr/http:\/\//, "got commit url value";

$obj = drop($str);
is $obj->[0], 'results', "got results key";
my $r_str = $obj->[1]->();
isa_ok($r_str, 'HOP::Stream');
@rows = undef;

while ($r_obj = drop($r_str)) {
  last if $r_obj->[0] eq 'transaction';
  is $r_obj->[0],'columns', "got columns key";
  is ref $r_obj->[1], 'ARRAY', "got column name array";
  ok $r_obj = drop($r_str);
  is $r_obj->[0],'data', "got data key";
  my $ar = $r_obj->[1]->();
  isa_ok($ar,'HOP::Stream');
  while (my $row = drop($ar)) {
    use experimental 'smartmatch';
    is $row->[0],'ARELT', "is array elt";
    given ($row->[1]) {
      when(ref eq 'HASH'){
	push @rows, $r_obj->[1];
	pass "value is hashref";
      }
      when('PENDING') {
	read $k, $buf,$CHUNK;
	$j->incr_parse($buf);
      }
      default {
	fail "shouldn't be here";
      }
    }
  }
  drop($r_str) if (head($r_str)->[1] eq 'DATA_STREAM');
  if (head($r_str)) {
    $r_str = head($r_str)->[1]->() if head($r_str)->[0] eq 'results';
  }
}

is $r_obj->[0], 'transaction', 'got transaction key';
ok $r_obj->[1]->{expires}, 'has expires key and value';
ok $r_obj = drop($r_str);
is $r_obj->[0],'errors', 'got errors key';

$ar = $r_obj->[1]->();
isa_ok($ar,'HOP::Stream');
while (my $item = drop($ar)) {
  is $item->[0],'ARELT',"is array elt";
  1;
}

open $k, File::Spec->catfile($TESTDIR, 'samples','null-txn-response.txt');
$j = JSON::XS->new();
read($k, $buf,$CHUNK) or die $!;
$j->incr_parse($buf);
ok $res = j_parse($j), "parsing null txn response";
is $res->[0],'TXN', "is txn response";
$str = $res->[1]->();
isa_ok($str, 'HOP::Stream');
ok $obj = drop($str);
is $obj->[0],'commit', "got commit key";
like $obj->[1], qr/http:\/\//, "got commit url value";

$obj = drop($str);
is $obj->[0], 'results', "got results key";
$r_str = $obj->[1]->();
isa_ok($r_str, 'HOP::Stream');
@rows = undef;
while ($r_obj = drop($r_str)) {
  last if $r_obj->[0] eq 'transaction';
  is $r_obj->[0],'columns', "got columns key";
  is ref $r_obj->[1], 'ARRAY', "got column name array";
  ok $r_obj = drop($r_str);
  is $r_obj->[0],'data', "got data key";
  my $ar = $r_obj->[1]->();
  isa_ok($ar,'HOP::Stream');
  ok !drop($ar), 'empty results';
  drop($r_str) if (head($r_str)->[1] eq 'DATA_STREAM');
  if (head($r_str)) {
    $r_str = head($r_str)->[1]->() if head($r_str)->[0] eq 'results';
  }
}
$obj = drop($str);
$obj = drop($str) if $obj && $obj->[1] =~ /STREAM/;
is $obj->[0], 'transaction', 'got transaction key';
ok $obj->[1]->{expires}, 'has expires key and value';
ok $obj = drop($str);
is $obj->[0],'errors', 'got errors key';
$ar = $obj->[1]->();
isa_ok($ar,'HOP::Stream');
ok !drop($ar), 'no errors';

1;
 done_testing;
1;
