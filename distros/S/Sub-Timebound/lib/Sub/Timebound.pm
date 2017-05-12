package Sub::Timebound;

use 5.008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Sub::Timebound ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(timeboundretry);

our $VERSION = '1.01';

# Preloaded methods go here.

sub timeboundretry 
{ 
	# Allocated Time, Attempts, Wait Time between attempts, Coderef to execute, Params
	my $allocated = int(shift);
	my $attempts = int(shift);
	my $wait = int(shift);
	my $coderef = shift;
	my @params = @_;

	my $ret = {
		value => undef,
		status => 1, ### Assume Success
	};

	my $count = 1;

	my $ref_string = "Did not complete in allocated $allocated Seconds\n";

	AGAIN: {

	eval {
		local $SIG{'ALRM'} = sub { die $ref_string };
		alarm($allocated);
		$ret->{value} = $coderef->(@params);
		$ret->{status} = 1;	### We execute this means all is well
		alarm(0);		### Reset alarm signal upon success
	};

	alarm(0);	### Reset alarm signal

	if ($@) {
		$ret->{status} = 0; ### Inform the caller that function call did not succeed
		### Now all we know is that eval block failed.
		### We still should determine if it died due to timeout or the called function misbehaved
		print "ERROR $@\n";

		if ("$@" eq $ref_string) {
			print "... Error happened due to timeout\n";
		} else {
			print "... Error happened due to function misbehavior\n";
		}

		$count++;
		if ($count > $attempts) { 
			print "Exceeded count limit ($attempts)....exiting\n"; 
			return $ret;
		} else { 
			print "Retry after $wait seconds...\n"; 
			sleep $wait; 
			goto AGAIN; 
		}
	}

	}
	return $ret;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Sub::Timebound - Perl extension for timebound computations

=head1 SYNOPSIS

	     use Sub::Timebound;

	     sub fun 
	     {
	     	my $i = shift;
		if ($i =~ /7$/) {
			die "Simulated internal error\n";
		}
		while ($i) {
			$i--;
		}
		return "All is well";
	     }

	     my	$x = timeboundretry(10, 3, 5, \&fun, 10);
	     ### Returns { value => '...', status => 0(FAILURE)/1(SUCCESS) }
	     ### 'value' is the return value of fun()

	     if	($x->{status}) {
		     # SUCCESS
		     $x->{value}
	     } else {
		      #	FAILURE
	     }

=head1 DESCRIPTION

	Module exports "timeboundretry" - this is a wrapper that watches a function call.

	my $x = timeboundretry([TimeAllocated], [NumberOfAttempts], 
			[PauseBetweenAttempts],[CodeRef],[Param1], [Param2], ...);


	[TimeAllocated]		- Seconds allocated to [CodeRef] to complete
	[NumberOfAttempts]	- Number of attempts made to [CodeRef]
	[PauseBetweenAttempts]	- Seconds to wait before making subsequent attempts
	[CodeRef]		- Reference to subroutine
	[Param1]...		- Parameters to subroutine

=head2 EXPORT

	timeboundretry()

=head1 SEE ALSO

	Proc::Reliable is a similar module that addresses external processes

=head1 AUTHOR

	Ramana Mokkapati, E<lt>mvr@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

	Copyright (C) 2005 by Ramana Mokkapati <mvr@cpan.org>

	This library is free software; you can redistribute it and/or modify
	it under the same terms as Perl itself, either Perl version 5.8.0 or,
	at your option, any later version of Perl 5 you may have available.

=cut
