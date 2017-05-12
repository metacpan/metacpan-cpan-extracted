package Solaris::NDDI;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Solaris::NDDI ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
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
	    croak "Your vendor has not defined Solaris::NDDI macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Solaris::NDDI $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Solaris::NDDI - Perl extension for interacting with Solaris Network Device Driver
Interface (NDDI). This module allows for getting and setting tunable parameters
that control network stack drivers, including IP, TCP, UDP, ICMP and ARP drivers.

=head1 SYNOPSIS

  use Solaris::NDDI;

  $ref = new Solaris::NDDI( <pseudo-device> );

  $ref->{<variable-name>} = <value>;
  <variable> = $ref->{<variable-name>};

=head1 DESCRIPTION

The Solaris::NDDI module is a programming interface for viewing and setting the values
of various tunable parameters associated with network drivers. A Solaris::NDDI object can 
be created for a particular pseudo-device, such as /dev/udp, /dev/tcp or /dev/ip, for instance,
this allowing for getting and setting the values of the tunable variables for a corresponding
network driver:
   
   $ref = new Solaris::NDDI('/dev/ip');
   print $ref->{ip_forwarding};     # prints the value of ip_forwarding tunable 
   $ref->{ip_forwarding} = 0;	    # turn off ip forwarding

Once instantiated, a Solaris::NDDI object will return a reference to a tied hash, where
every variable for a given driver will be represented by a hash pair. Thus, the following
code snippet will list all variable names for a particular driver:

   $ref = new Solaris::NDDI('/dev/ip');
   foreach( sort keys %$ref ) {
      print "$_ => $ref->{$_}\n";
   }

Note, appropriate level of permissions is necessary to open a some pseudo-devices (such as /dev/ip)
and to get/set certain variables.

=head2 EXPORT

None by default.


=head1 AUTHOR

Alexander Golomshtok, golomshtok_alexander@jpmorgan.com

=head1 SEE ALSO

L<perl>, L<ndd(1M)>.

=cut
