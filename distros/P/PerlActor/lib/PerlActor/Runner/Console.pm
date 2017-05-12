package PerlActor::Runner::Console;
use strict;
use base 'PerlActor::Runner';
use fields qw( run passed failed aborted failedReport abortedReport started ended );

$| = 1;

use Benchmark;

#===============================================================================================
# Public Methods
#===============================================================================================

sub start
{
	my $self = shift;

	$self->_resetCounters();
	$self->_resetReports();
	$self->_printHeader();	
	$self->_startClock();
}

sub end
{
	my $self = shift;

	$self->_stopClock();

	my $runTime = timediff($self->{ended}, $self->{started});
	
	print "\n" . $self->trim(timestr($runTime));
	print "\nRun: $self->{run}, Passed: $self->{passed}, Failed: $self->{failed}, Aborted: $self->{aborted}.\n";
	
	$self->_printReports($self->{failedReport},'FAILED');
	$self->_printReports($self->{abortedReport},'ABORTED');

	unless ($self->{failed} or $self->{aborted})
	{
		print "\nOK ($self->{passed} scripts)";
	}
	print "\n";
}

sub _printReports
{
	my $self = shift;
	my $reports = shift;
	my $label = shift;
	
	if (@{$reports})
	{
		print "\n!!!$label!!!\n";
		my $count = 0;
		map { $count++; print "\n$count) $_\n" } @{$reports};
	}
}

sub scriptStarted
{ 
	my $self = shift;
	$self->{run}++;
}

sub scriptPassed
{ 
	my $self = shift;
	$self->{passed}++;
	print ".";
}

sub scriptAborted
{
	my ($self, $script, $exception) = @_;
	$self->{aborted}++;
	print "E";
	$self->_addReport($script, $exception, 'ABORTED', $self->{abortedReport});
}

sub scriptFailed
{ 
	my ($self, $script, $exception) = @_;
	$self->{failed}++;
	print "F";
	$self->_addReport($script, $exception, 'FAILED', $self->{failedReport});
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

sub _resetCounters
{
	my $self = shift;
	$self->{run}     = 0;
	$self->{passed}  = 0;
	$self->{failed}  = 0;
	$self->{aborted} = 0;
}

sub _resetReports
{
	my $self = shift;
	$self->{failedReport}  = [];
	$self->{abortedReport}  = [];
}

sub _addReport
{
	my ($self, $script, $exception, $label, $reportType) = @_;
	chomp $exception;
	push @{$reportType}, "$label: '$exception' " . $script->getTraceInfo();
}

sub _startClock
{
	my $self = shift;
	$self->{started} = new Benchmark();
}

sub _stopClock
{
	my $self = shift;
	$self->{ended} = new Benchmark();
}

sub _printHeader
{
	print "\nRunning Acceptance Tests\n";
	print "========================\n";
}

# Keep Perl happy.
1;
