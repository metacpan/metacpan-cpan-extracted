#perl

use strict;
use warnings;

use IO::Scalar;
use Log::Log4perl;

use Test::More tests => 14;

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
	package BasicLogTest;

	use Moo;
	with 'MooseX::Log::Log4perl';

	sub test_log {
		my ($self) = @_;
		$self->log->trace('hey');
		$self->log->debug('foo');
		$self->log("SPECIAL")->info('BAZ');
		$self->log(".SPECIAL")->info('BAZ');
		$self->log("::SPECIAL")->info('BAZ');
		$self->log->warn('no nooo NOOOO');
		$self->log->error('bar');
		$self->log->fatal('titanic is sinking');
	}
}

{
	package BasicLogTest;

	use Moo;
	with 'MooseX::Log::Log4perl';

	has 'foo' => ( is => 'rw' );
}

{
	my $obj = new BasicLogTest;

	isa_ok( $obj, 'BasicLogTest' );
	ok( $obj->can('log'),    "Role method log exists" );
	ok( $obj->can('logger'), "Role method logger exists" );
	foreach my $lvl (qw(fatal error warn info debug trace)) {
		ok( !$obj->can("log_$lvl"), "Instance namespace must not be poluted with easy method log_$lvl" );
	}
	ok( !$obj->can('debug'), "Interface not poluted with direct debug method" );

	my $logger = $obj->logger;
	isa_ok( $obj->logger, 'Log::Log4perl::Logger' );
	is( $obj->can('debug'), undef, "Object not poluted" );
	is( $obj->can('error'), undef, "Object not poluted" );

	tie *STDERR, 'IO::Scalar', \my $err;
	local $SIG{__DIE__} = sub { untie *STDERR; die @_ };

	$obj->test_log;
	untie *STDERR;

	# Cleanup log output line-endings
	$err =~ s/\r\n/\n/gm;

	my $expect = <<__ENDLOG__;
TRACE [BasicLogTest] [BasicLogTest::test_log] hey
DEBUG [BasicLogTest] [BasicLogTest::test_log] foo
INFO [SPECIAL] [BasicLogTest::test_log] BAZ
INFO [BasicLogTest.SPECIAL] [BasicLogTest::test_log] BAZ
INFO [BasicLogTest.SPECIAL] [BasicLogTest::test_log] BAZ
WARN [BasicLogTest] [BasicLogTest::test_log] no nooo NOOOO
ERROR [BasicLogTest] [BasicLogTest::test_log] bar
FATAL [BasicLogTest] [BasicLogTest::test_log] titanic is sinking
__ENDLOG__

	is( $err, $expect, "Log messages are formated as expected to stderr" );

}
