#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use TestTmp;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::base;

my $dir  = TestTmp::dir();
my $data = $FindBin::Bin . '/data';
local $Monitoring::Sneck::Checks::base::OS   = 'linux';
local $Monitoring::Sneck::Checks::base::PROC = $data . '/uptime/proc';
my $run = sub {
	my ( $check, @args ) = @_;
	return Monitoring::Sneck::Checks->run( check => $check, args => \@args );
};
my %sysctl;
{
	no warnings 'once';
	$INC{'BSD/Sysctl.pm'} = __FILE__;
	*BSD::Sysctl::sysctl = sub { return $sysctl{ $_[0] } };
}

# pid_file, with this test as the process
require Proc::ProcessTable;
my ($self_process) = grep { $_->pid == $$ } @{ Proc::ProcessTable->new->table };
my $name           = $self_process->fname;
my $pid_file       = $dir . '/test.pid';
open( my $fh, '>', $pid_file ) or die($!);
print $fh $$ . "\n";
close($fh);
is( $run->( 'pid_file', '-f', $pid_file )->{stdout}, "PID_FILE OK - $$ from $pid_file is running\n", 'running' );
is(
	$run->( 'pid_file', '-f', $pid_file, '-n', $name )->{stdout},
	"PID_FILE OK - $$ $name from $pid_file is running\n",
	'with its name'
);
is(
	$run->( 'pid_file', '-f', $pid_file, '-n', 'not-this' )->{stdout},
	"PID_FILE CRITICAL - $$ from $pid_file is $name, not not-this\n",
	'a other name'
);
my $dead = fork();
exit(0) if !$dead;
waitpid( $dead, 0 );
open( $fh, '>', $dir . '/dead.pid' ) or die($!);
print $fh $dead;
close($fh);
is(
	$run->( 'pid_file', '-f', $dir . '/dead.pid' )->{stdout},
	"PID_FILE CRITICAL - $dead from $dir/dead.pid is not running\n",
	'not running'
);
is(
	$run->( 'pid_file', '-f', $data . '/pid_file/junk.pid' )->{stdout},
	"PID_FILE CRITICAL - $data/pid_file/junk.pid does not have a PID\n",
	'not a PID'
);
like( $run->( 'pid_file', '-f', $data . '/pid_file/nope.pid' )->{stdout},
	qr/\APID_FILE CRITICAL - can not read \S+nope.pid/, 'missing' );

# uptime
is( $run->('uptime')->{stdout}, "UPTIME OK - up 12 days, 3:24 | uptime=1049040s;900:;;0\n", 'uptime' );
is( $run->( 'uptime', '-w', '900:864000' )->{code}, 1,                                      'up too long' );
$Monitoring::Sneck::Checks::base::PROC = $data . '/uptime/proc_rebooted';
is( $run->('uptime')->{stdout}, "UPTIME WARNING - up 0:05 | uptime=300s;900:;;0\n", 'just rebooted' );
{
	local $Monitoring::Sneck::Checks::base::OS = 'freebsd';
	foreach my $boot (
		{ sec => time - 90060, usec => 0 },
		[ time - 90060, 0 ],
		'{ sec = ' . ( time - 90060 ) . ', usec = 0 } Sat Oct  1 00:00:00 2026',
		time - 90060
		)
	{
		$sysctl{'kern.boottime'} = $boot;
		like(
			$run->('uptime')->{stdout},
			qr/\AUPTIME OK - up 1 day, 1:01 \|/,
			'FreeBSD kern.boottime as ' . ( ref($boot) || 'text' )
		);
	} ## end foreach my $boot ( { sec => time - 90060, usec ...})
}

# file_handles
$Monitoring::Sneck::Checks::base::PROC = $data . '/file_handles/proc';
is( $run->('file_handles')->{stdout},
	"FILE_HANDLES WARNING - 85.0% used, 8500 of 10000 open | used=85.0%;80;90;0;100 open=8500;;;0;10000\n",
	'Linux' );
{
	local $Monitoring::Sneck::Checks::base::OS = 'freebsd';
	%sysctl = ( 'kern.openfiles' => 950, 'kern.maxfiles' => 1000 );
	is( $run->('file_handles')->{code}, 2, 'FreeBSD' );
}
{
	local $Monitoring::Sneck::Checks::base::OS = 'solaris';
	like( $run->('file_handles')->{stderr}, qr/not supported on solaris/, 'other OSes' );
}

done_testing();
