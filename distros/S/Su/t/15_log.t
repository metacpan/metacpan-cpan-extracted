use lib qw(t/test15 test15 lib ../lib);
use Su::Log;
use Test::More tests => 19;
use ForTest;

Su::Log->on('ForTest');
my $obj = ForTest->new;
my $ret = $obj->info_test();

like( $ret, qr/\[INFO\]info message\.\n/ );

$ret = $obj->trace_test();
ok( !$ret );

# Su::Log->set_level("trace");
Su::Log->set_global_log_level("trace");
$ret = $obj->trace_test();
like( $ret, qr/\[TRACE\]trace message\.\n/ );
Su::Log->set_global_log_level(undef);

package Test15_Foo;
use Test::More;

sub new {
  my $self = shift;
  return bless {}, $self;
}

sub fn01 {
  my $log = Su::Log->new(shift);
  my $arg = shift;

  # if ($arg) {
  #   diag( "on?:" . $log->{on} );
  # }
  $log->info("info from Test15_Foo::fn01()");
} ## end sub fn01

sub fn01_off {
  my $self = shift;
  my $log  = Su::Log->new($self);
  $log->off;
  $log->info("info from Test15_Foo::fn01_off()");
} ## end sub fn01_off

sub fn02 {
  my $log = Su::Log->new(shift);
  $log->log_handler( \&hndl );
  return $log->info("info from Test15_Foo::fn02()");
}

sub hndl {
  shift;    # Remove the caller parameter.
  $log_msg = join '', 'custom log handler:', @_;

  #  diag($log_msg);
  like( $log_msg,
    qr/custom log handler:\[INFO\]info from Test15_Foo::fn02\(\)/ );
  return $log_msg;
} ## end sub hndl

package main;

$obj = Test15_Foo->new;

$ret = undef;
$ret = $obj->fn01('arg');

#diag( "ret is:" . $ret );
#diag(@Su::Log::target_class);
like( $ret, qr/\[INFO\]info from Test15_Foo::fn01\(\)\n/ );

$ret = undef;
$ret = $obj->fn01_off;

# diag($ret);
ok( !$ret, "Nothing logged because module is not registered." );

# Set the whole class as log target.
Su::Log->enable;
$ret = $obj->fn01;

like(
  $ret,
  qr/\[INFO\]info from Test15_Foo::fn01\(\)\n/,
  "Logging is on, because all flag is set."
);

# test object specific log handler.

$ret = $obj->fn02;
like( $ret, qr/custom log handler:\[INFO\]info from Test15_Foo::fn02\(\)/ );

# test for functional usage.

# Omit constructor parmeter test.
Su::Log->clear_all_flags;
$Su::Log::all_off = 1;
$log              = new Su::Log->new;

ok( !$log->info("info message"), "Test of the all_off flag." );
Su::Log->clear_all_flags;

# Register main package.
Su::Log->on(__PACKAGE__);

like( $log->info("info message"), qr/\[INFO\]info message\n/ );

# Unregister main package.
Su::Log->off(__PACKAGE__);

ok( !$log->info("info message") );
ok( !$log->warn("info message") );
ok( !$log->crit("info message") );

Su::Log->on(__PACKAGE__);

my $log = Su::Log->new;
ok( $log->info("info message") );

# Su::Log->on(__PACKAGE__);
like( $log->info("info message2"), qr/\[INFO\]info message2\n/ );

# Test to use the class specified off flag.
Su::Log->clear_all_flags;
Su::Log->clear;
$obj = Test15_Foo->new;

$ret = undef;
$ret = $obj->fn01;
ok($ret);

Su::Log->off('Test15_Foo');
$ret = $obj->fn01;
ok( !$ret );

Su::Log->on('Test15_Foo');
$ret = $obj->fn01;
ok($ret);

# Test to force enable logging from outer against inner using of off method.

$ret = $obj->fn01_off;
ok( $ret, "Force output test." );

