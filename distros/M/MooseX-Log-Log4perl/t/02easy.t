#perl

use strict;
use warnings;

use IO::Scalar;
use Log::Log4perl;

use Test::More tests => 11;

BEGIN {
	my $cfg = <<__ENDCFG__;
log4perl.rootLogger = TRACE, Console

log4perl.appender.Console        = Log::Log4perl::Appender::Screen
log4perl.appender.Console.stderr = 1
log4perl.appender.Console.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Console.layout.ConversionPattern = %p [%c] [%M] %m%n
__ENDCFG__
	Log::Log4perl->init(\$cfg);
}

{
	package EasyLogTest;

	use Moo;
	with 'MooseX::Log::Log4perl::Easy';

	sub test_easy {
		my ($self) = @_;
		$self->log_trace('hey');
		$self->log_debug('guess');
		$self->log_info('we all');
		$self->log_warn('have');
		$self->log_error('big');
		$self->log_fatal('brains');
	}

	sub test_log {
		my ($self) = @_;
		$self->log("SPECIAL")->info('BAZ');
		$self->log->debug('foo');
		$self->log->error('bar');

	}
}

{
	my $obj = new EasyLogTest;

	isa_ok( $obj, 'EasyLogTest' );

	### Test the interface
	ok( $obj->can("logger"),    "Role method logger exists" );
	ok( $obj->can("log"),    "Role method log exists" );
	foreach my $lvl (qw(fatal error warn info debug trace)) {
		ok( $obj->can("log_$lvl"),    "Role method log_$lvl exists" );
	}

	my $expect_easy = <<__ENDLOG__;
TRACE [EasyLogTest] [EasyLogTest::test_easy] hey
DEBUG [EasyLogTest] [EasyLogTest::test_easy] guess
INFO [EasyLogTest] [EasyLogTest::test_easy] we all
WARN [EasyLogTest] [EasyLogTest::test_easy] have
ERROR [EasyLogTest] [EasyLogTest::test_easy] big
FATAL [EasyLogTest] [EasyLogTest::test_easy] brains
__ENDLOG__

	my $expect_log = <<__ENDLOG__;
INFO [SPECIAL] [EasyLogTest::test_log] BAZ
DEBUG [EasyLogTest] [EasyLogTest::test_log] foo
ERROR [EasyLogTest] [EasyLogTest::test_log] bar
__ENDLOG__

	tie *STDERR, 'IO::Scalar', \my $err;
	local $SIG{__DIE__} = sub { untie *STDERR; die @_ };

	### Call some object routine to test the easy logging
	$obj->test_easy();

	# Cleanup log output line-endings
	$err =~ s/\r\n/\n/gm;
	is( $err, $expect_easy, "Log messages for easy logging are formated as expected to stderr" );
	$err = '';

	### Call some the standard log4perl log routing
	$obj->test_log();

	# Cleanup log output line-endings
	$err =~ s/\r\n/\n/gm;
	is( $err, $expect_log, "Log messages using standard logging are formated as expected to stderr" );
	$err = '';

	untie *STDERR;
}
