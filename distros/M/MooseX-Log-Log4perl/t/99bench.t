#perl

use strict;
use warnings;

use Benchmark qw(:all :hireswallclock);
use Log::Log4perl;
use vars qw($tmplogfile);

use Test::More;
plan skip_all => 'Author test. Set $ENV{TEST_AUTHOR} to run benchmark tests' unless $ENV{TEST_AUTHOR};
plan tests => 6;

my $benchlimit = 85; # accept 85% performance hit due to method call overhead

BEGIN {	$tmplogfile = 'mxll4p_benchtest.log'; }
END {
	### Remove tmpfile if exists
	unlink($tmplogfile) if (-f $tmplogfile);
}

{
	### Define a custom Log4perl appender that simply does not log anything
	### as we only need to check on call performance not actuall performance
	### of the appender
	package Log::Log4perl::Appender::TestNirvana;
	use base qw( Log::Log4perl::Appender::TestBuffer );
	sub log {}
}

{
	package BenchMooseXLogLog4perl;

	use Moo;
	with 'MooseX::Log::Log4perl';

	sub testlog { shift->log->info("Just a test for logging"); }
	sub testlogger { shift->logger->info("Just a test for logging"); }
	__PACKAGE__->meta->make_immutable;
}

{
	package BenchLogLog4perl;

	use Log::Log4perl;
	use vars qw($log);

	BEGIN { $log = Log::Log4perl->get_logger(__PACKAGE__); }

	sub new { bless({log=>$log},__PACKAGE__); }
	sub log { return shift->{log}; };

	sub testlogmethod { shift->log->info("Just a test for logging"); }
	sub testlogdirect { $log->info("Just a test for logging"); }
}

###
### Tests start here
###
{
	my $cfg = <<__ENDCFG__;
log4perl.rootLogger = INFO, Nirvana
log4perl.appender.Nirvana = Log::Log4perl::Appender::TestNirvana
log4perl.appender.Nirvana.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Nirvana.layout.ConversionPattern = %p [%c] %m%n
__ENDCFG__
	Log::Log4perl->init(\$cfg);

	my $mxl = new BenchMooseXLogLog4perl();
	my $llp = new BenchLogLog4perl();

	isa_ok( $mxl, 'BenchMooseXLogLog4perl', 'Bench instance for MooseX::Log::Log4perl');
	isa_ok( $llp, 'BenchLogLog4perl', 'Bench instance for Log::Log4perl');

	### We expect some basic performance of approx. 95% of Log4perl directly
	diag("Running benchmarks, please wait a minute...");
	my $result = cmpthese(-10, {
		'Log4perl direct' => sub { $llp->testlogdirect() },
		'Log4perl method' => sub { $llp->testlogmethod() },
		'MooseX-L4p logger' => sub { $mxl->testlogger() },
		'MooseX-L4p log' => sub { $mxl->testlog() },
	});
	### Compare the rates now
	my %bench = ();
	foreach (@{$result}) {
		my @row = @{$_};
		my $rate = $row[1]; $rate =~ s?/s$??;
		$bench{$row[0]} = $rate;
		# diag($rate);
	}
	my ($rate_logger, $rate_log);
	$rate_logger = 100 * $bench{'MooseX-L4p logger'} / $bench{'Log4perl direct'};
	ok($rate_logger >= $benchlimit, sprintf("Call rate of ->logger must be above $benchlimit%% " .
		"(%i / %i = %.2f %%) to Log4perl direct", $bench{'MooseX-L4p logger'}, $bench{'Log4perl direct'}, $rate_logger));
	$rate_log = 100 * $bench{'MooseX-L4p log'} / $bench{'Log4perl direct'};
	ok($rate_log >= $benchlimit, sprintf("Call rate of ->log must be above $benchlimit%% " .
		"(%i / %i = %.2f %%) to Log4perl direct", $bench{'MooseX-L4p logger'}, $bench{'Log4perl direct'}, $rate_log));

	$rate_logger = 100 * $bench{'MooseX-L4p logger'} / $bench{'Log4perl method'};
	ok($rate_logger >= $benchlimit, sprintf("Call rate of ->logger must be above $benchlimit%% " .
		"(%i / %i = %.2f %%) to Log4perl via method", $bench{'MooseX-L4p logger'}, $bench{'Log4perl method'}, $rate_logger));
	$rate_log = 100 * $bench{'MooseX-L4p log'} / $bench{'Log4perl method'};
	ok($rate_log >= $benchlimit, sprintf("Call rate of ->log must be above $benchlimit%% " .
		"(%i / %i = %.2f %%) to Log4perl via method", $bench{'MooseX-L4p logger'}, $bench{'Log4perl method'}, $rate_log));

}
