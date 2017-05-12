use Test::More tests => 20;

plan skip_all => "MSWin32 not supported" if $^O eq 'MSWin32';

use Nagios::Passive;

eval {
  Nagios::Passive->create(
    checkresults_dir => "/hopefully_not_there",
    check_name => 'x',
    host_name => 'localhost',
  )
}; if($@) {
  ok($@ =~ /is not a directory/, "constructor");
} else {
  fail("constructor");
}

my $nw = Nagios::Passive->create(
   checkresults_dir => '/var/tmp',
   check_name => "TEST01",
   host_name  => "localhost",
   service_description => "test_service",
);

ok(time - $nw->time < 5, "time");
ok(time - $nw->time >= 0, "time");
is($nw->checkresults_dir, "/var/tmp", "checkresults_dir");
is($nw->check_name, "TEST01", "check_name");
is($nw->host_name, "localhost", "hostname");
is($nw->service_description, "test_service", "service_description");
ok(!$nw->has_threshold, "threshold");
eval {
  $nw->set_status(1);
}; if($@) {
  ok($@ =~ /you have to call set_thresholds/, "thresholds");
} else {
  fail("thresholds");
}
$nw->set_thresholds(
  warning => 5,
  critical => 10
);
ok($nw->has_threshold, "threshold");
$nw->set_status(1); is($nw->return_code, 0, "OK");
$nw->set_status(6); is($nw->return_code, 1, "WARNING");
$nw->set_status(11); is($nw->return_code, 2, "CRITICAL");
ok(!$nw->has_performance, "performance");
$nw->add_perf( label => 'x', value => 1 );
$nw->add_perf( label => 'y', value => 5 );
ok($nw->has_performance, "performance");
is(scalar @{ $nw->performance }, 2, "performance");
is($nw->_perf_string, "x=1;; y=5;;", "performance");
is($nw->_quoted_output, ' | x=1;; y=5;;', "output");
$nw->output("abc\n");
$nw->add_output("def");
is($nw->_quoted_output, 'abc\ndef | x=1;; y=5;;', "output");
$nw->time(10);
$nw->start_time(15);
$nw->finish_time(20);
$ENV{TZ} = 'UTC';
SKIP: {
if((scalar localtime(10)) ne 'Thu Jan  1 00:00:10 1970') {
  skip 'localtime does not respect $ENV{TZ}', 1
}
is("$nw", << 'EOT', "string");
### Active Check Result File ###
file_time=10

### Nagios Service Check Result ###
# Time: Thu Jan  1 00:00:10 1970
host_name=localhost
service_description=test_service
check_type=1
check_options=0
scheduled_check=0
latency=0.000000
start_time=15.000000
finish_time=20.000000
early_timeout=0
exited_ok=1
return_code=2
output=TEST01 CRITICAL - abc\ndef | x=1;; y=5;;
EOT
}
