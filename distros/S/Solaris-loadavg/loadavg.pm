package Solaris::loadavg;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Solaris::loadavg ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
   loadavg	
   LOADAVG_1MIN
   LOADAVG_5MIN
   LOADAVG_15MIN
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
   loadavg	
   LOADAVG_1MIN
   LOADAVG_5MIN
   LOADAVG_15MIN
);
our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Solaris::loadavg macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Solaris::loadavg $VERSION;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Solaris::loadavg - get system load averages

=head1 SYNOPSIS

  use Solaris::loadavg;

  @avgs = loadavg();
  printf "load average: %f %f %f\n", @avgs;
  
=head1 DESCRIPTION
  The Solaris::loadavg module provides simple interface to Solaris getloadavg(3C) library
  function, which returns the number of processes in the  system run queue averaged over 
  various periods of time. Up to 3 (LOADAVG_NSTATS) samples are retrieved and returned 
  to successive elements of the output array. The  system imposes a maximum of 3
  samples, representing averages over the last 1,  5,  and  15 minutes, respectively.
  The LOADAVG_1MIN, LOADAVG_5MIN, and LOADAVG_15MIN  indices, defined  in <sys/loadavg.h>, 
  can be used to extract the data from the appropriate element of the output array:

  # get the first two load averages

  @avgs = loadavg(2);
  printf "first load avg (1min): %f\n", @avgs[LOADAVG_1MIN];
  printf "second load avg (5min): %f\n", @avgs[LOADAVG_5MIN];

  When called without an argument, the loadavg() function returns all three 
  load averages.

=head2 EXPORT
   loadavg	
   LOADAVG_1MIN
   LOADAVG_5MIN
   LOADAVG_15MIN

=head1 AUTHOR

Alexander Golomshtok, E<lt>golomshtok_alexander@jpmorgan.comE<gt>

=head1 SEE ALSO

L<perl>,L<getloadavg(3C)>

=cut
