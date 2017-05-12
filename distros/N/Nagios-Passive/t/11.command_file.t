use Test::More;
plan skip_all => "MSWin32 not supported" if $^O eq 'MSWin32';

use Nagios::Passive;
use POSIX qw/mkfifo/;

my $fifo = "/var/tmp/test.fifo.$$";
END {
  unlink $fifo;
};

unless (mkfifo $fifo, 0777) {
  plan skip_all => "mkfifo failed";
}

plan tests => 21;

eval {
  Nagios::Passive->create(
    command_file => '.',
    check_name => 'x',
    host_name => 'localhost',
  )
}; if($@) {
  ok($@ =~ /is not a named pipe/, "constructor");
} else {
  fail("constructor");
}

my $nw = Nagios::Passive->create(
   command_file => $fifo,
   check_name => "TEST01",
   host_name  => "localhost",
   service_description => "test_service",
);

ok(time - $nw->time < 5, "time");
ok(time - $nw->time >= 0, "time");
is($nw->command_file, $fifo, "command_file");
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
$ENV{TZ} = 'UTC';
is("$nw", << 'EOT', "string service check");
[10] PROCESS_SERVICE_CHECK_RESULT;localhost;test_service;2;TEST01 CRITICAL - abc\ndef | x=1;; y=5;;
EOT

$nw = Nagios::Passive->create(
  command_file => $fifo,
  host_name => 'localhost',
  check_name => 'TEST01',
  time => 10,
);
is("$nw", << 'EOT', "string host check");
[10] PROCESS_HOST_CHECK_RESULT;localhost;0;TEST01 OK - 
EOT
