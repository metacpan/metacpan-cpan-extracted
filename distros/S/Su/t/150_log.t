use lib qw(lib ../lib t/test15 test15);

use Su::Log;
use Test::More tests => 38;
use Procs::ForLogTest;
use Procs::ForLogTest2;

my $obj = Procs::ForLogTest->new;

my $ret = $obj->log_test;

# Simply output test.

like( $ret, qr/\[.+?\]\[INFO\]info test\.\n/ );

# Log disable test.

my $log = Su::Log->new;
$log->disable;

$ret = undef;
$ret = $obj->log_test;

ok( !$ret );

$ret = undef;
$ret = $log->info("main test.");
ok( !$ret );

# Instantiate object under the state of log disable.
$obj = Procs::ForLogTest->new;

$ret = undef;
$ret = $obj->log_test;

ok( !$ret );

# Log enable test.

$log->enable;

$ret = undef;
$ret = $obj->log_test;

like( $ret, qr/\[INFO\]info test\.\n/ );

# Clear all flag and normally logging test.

$log->clear_all_flags;

$ret = undef;
$ret = $obj->log_test;

like( $ret, qr/\[INFO\]info test\.\n/ );

# Log disable test by off method.

$log->off('Procs::ForLogTest');

$ret = undef;
$ret = $obj->log_test;

ok( !$ret );

# Whether anoter package can logging.

$ret = undef;
$ret = $log->info("main test.");

like( $ret, qr/\[INFO\]main test\.\n/ );

# Log enable test by on method.

$log->on('Procs::ForLogTest');

$ret = undef;
$ret = $obj->log_test;

like( $ret, qr/\[INFO\]info test\.\n/ );

# Whether anoter package can logging.

$ret = undef;
$ret = $log->info("main test.");

like( $ret, qr/\[INFO\]main test\.\n/ );

## Tests for log level.

# Trace leve can not output by default.
ok( !$log->trace('trace message') );

# Make trace level output the log.
$log->set_level('trace');
$ret = $log->trace('trace message');
like( $ret, qr/\[TRACE\]trace message\n/ );

# Reset the log level, then trace level can not output.
$log->set_level('info');
ok( !$log->trace('trace message') );
ok( !$log->debug('debug message') );
ok( $log->info('info message') );
ok( $log->error('info message') );
ok( $log->crit('info message') );

# Global level(trace) overwhelm instance level(info).

$log->set_global_log_level('trace');

$ret = $log->trace('trace message');
like( $ret, qr/\[TRACE\]trace message\n/ );

# Global level(error) overwhelm instance level(info).

$log->set_global_log_level('error');

ok( !$log->info('info message') );

## Test for class specified log level.
$log->set_global_log_level(undef);
$ret = $obj->many_level_log;

like(
  $ret, qr/\[.+?\]\[INFO\]info test\.
\[.+?\]\[WARN\]warn test\.
\[.+?\]\[ERROR\]error test\.
\[.+?\]\[CRIT\]crit test\.
/
);

$log->on( 'Procs::ForLogTest', 'error' );

$ret = $obj->many_level_log;

like(
  $ret, qr/\[.+?\]\[ERROR\]error test\.
\[.+?\]\[CRIT\]crit test\.
/
);

$ret = $log->error("error");
ok($ret);

$ret = $log->info("warn");
like( $ret, qr/warn/ );

$ret = $log->info("info");
like( $ret, qr/info/ );

$ret = $log->debug("debug");
ok( !$ret, "should be null" );

$ret = $log->trace("trace");
ok( !$ret, "should be null" );

$log->clear();

$ret = $obj->log_test;
ok($ret);

$ret = $obj->log_off_test;
ok( !$ret, "should be null" );

$log->on( "Procs::ForLogTest", "info" );
$ret = $obj->log_off_test;
ok($ret);

my $obj2 = Procs::ForLogTest2->new;
$ret = $obj2->log_off_test;
ok( !$ret, "should be null" );

$log->on( "Procs::ForLogTest2", "info" );
$ret = $obj2->log_off_test;
ok($ret);

$log->clear("Procs::ForLogTest2");
$ret = $obj2->log_off_test;
ok( !$ret );

## Use regexp to specify the tareget classes.

$log->clear;
$log->on( qr/Procs::ForLogTest.*/, "info" );

use Data::Dumper;

# diag( "here:" . Dumper(@Su::Log::target_class) );
$ret = $obj2->log_off_test;
ok($ret);

$log->clear(qr/Procs::ForLogTest.*/);

# diag( "tgt:" . Dumper(@Su::Log::target_class) );
$ret = $obj2->log_off_test;
ok( !$ret );

$ret = undef;
$ret = $log->info("main test.");
ok($ret);

## Logging off via regexp.

$log->clear;
$log->off(qr/Procs::ForLogTest.*/);

$ret = $obj2->log_test;
ok( !$ret );

$ret = undef;
$ret = $log->info("main test.");
ok($ret);

# Clear off flag.

$log->clear(qr/Procs::ForLogTest.*/);
$ret = $obj2->log_test;
ok($ret);
