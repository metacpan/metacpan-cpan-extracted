use Test::TempDir::Tiny qw/tempdir/;
use Test::More;
use Nagios::Passive;
use Nagios::Passive::BulkResult;
use IO::File;
$ENV{TZ} = 'UTC';
use strict;

plan skip_all => "MSWin32 not supported" if $^O eq 'MSWin32';

my $tempdir = tempdir

isnt(eval { Nagios::Passive::BulkResult->new(); 1 }, 1, "should die");
isnt(eval { Nagios::Passive::BulkResult->new(checkresults_dir => undef); 1 }, 1, "should die");

SKIP: {
if((scalar localtime(10)) ne 'Thu Jan  1 00:00:10 1970') {
  skip 'localtime does not respect $ENV{TZ}', 2;
}

my $p1 = Nagios::Passive->create(
  checkresults_dir => undef,
  check_name => 'FOO',
  host_name => 'localhost',
  service_name => 'P1',
  return_code => 0,
  output => "good",
  time => 10,
  start_time => 10,
  end_time => 10,
  finish_time => 10,
);
my $p2 = Nagios::Passive->create(
  checkresults_dir => undef,
  check_name => 'FOO',
  host_name => 'localhost',
  service_name => 'P2',
  return_code => 1,
  output => "good",
  time => 10,
  start_time => 10,
  end_time => 10,
  finish_time => 10,
);

my $expected = do { local $/; <DATA> };
my $bulk = Nagios::Passive::BulkResult->new(checkresults_dir => "$tempdir");
isa_ok($bulk, 'Nagios::Passive::BulkResult');

$bulk->add($p1);
$bulk->add($p2);
$bulk->submit;
undef $bulk; # flush
my $file = (glob("$tempdir/*"))[0];
diag $file;
my $got = do { local $/; my $f = IO::File->new($file, 'r'); <$f> };
$got =~ s/\A.*?\n\n//s;
is($got, $expected, "result ok");
}
done_testing;

__DATA__
### Nagios Service Check Result ###
# Time: Thu Jan  1 00:00:10 1970
host_name=localhost
check_type=1
check_options=0
scheduled_check=0
latency=0.000000
start_time=10.000000
finish_time=10.000000
early_timeout=0
exited_ok=1
return_code=0
output=FOO OK - good

### Nagios Service Check Result ###
# Time: Thu Jan  1 00:00:10 1970
host_name=localhost
check_type=1
check_options=0
scheduled_check=0
latency=0.000000
start_time=10.000000
finish_time=10.000000
early_timeout=0
exited_ok=1
return_code=1
output=FOO WARNING - good

