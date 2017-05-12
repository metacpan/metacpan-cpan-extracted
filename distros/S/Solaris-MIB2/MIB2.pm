package Solaris::MIB2;

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

# This allows declaration	use Solaris::MIB2 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
   ACE_F_PERMANENT 
   ACE_F_PUBLISH   
   ACE_F_DYING     
   ACE_F_RESOLVED  
   ACE_F_MAPPING   
   RTF_UP          
   RTF_GATEWAY     
   RTF_HOST        
   RTF_REJECT      
   RTF_DYNAMIC     
   RTF_MODIFIED    
   RTF_DONE        
   RTF_MASK        
   RTF_CLONING     
   RTF_XRESOLVE    
   RTF_LLINFO      
   RTF_STATIC      
   RTF_BLACKHOLE   
   RTF_PRIVATE     
   RTF_PROTO2      
   RTF_PROTO1      
   IRE_BROADCAST           
   IRE_DEFAULT             
   IRE_LOCAL               
   IRE_LOOPBACK            
   IRE_PREFIX              
   IRE_CACHE               
   IRE_IF_NORESOLVER       
   IRE_IF_RESOLVER         
   IRE_HOST                
   IRE_HOST_REDIRECT       
   MIB2_TCP_closed	  
   MIB2_TCP_listen	  
   MIB2_TCP_synSent	  
   MIB2_TCP_synReceived 
   MIB2_TCP_established 
   MIB2_TCP_finWait1	  
   MIB2_TCP_finWait2	  
   MIB2_TCP_closeWait	  
   MIB2_TCP_lastAck	  
   MIB2_TCP_closing	  
   MIB2_TCP_timeWait	  
   MIB2_TCP_deleteTCB	  
   MIB2_UDP_unbound   
   MIB2_UDP_idle      
   MIB2_UDP_connected 
   MIB2_UDP_unknown   
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.02';

# ARP constants for ntm_flags (inet/arp.h)
use constant ACE_F_PERMANENT => 0x1;
use constant ACE_F_PUBLISH   => 0x2;
use constant ACE_F_DYING     => 0x4;
use constant ACE_F_RESOLVED  => 0x8;
use constant ACE_F_MAPPING   => 0x10;

# routing flags constants for re_flags (net/route.h)
use constant RTF_UP          => 0x1;
use constant RTF_GATEWAY     => 0x2;
use constant RTF_HOST        => 0x4;
use constant RTF_REJECT      => 0x8;
use constant RTF_DYNAMIC     => 0x10;
use constant RTF_MODIFIED    => 0x20;
use constant RTF_DONE        => 0x40;
use constant RTF_MASK        => 0x80;
use constant RTF_CLONING     => 0x100;
use constant RTF_XRESOLVE    => 0x200;
use constant RTF_LLINFO      => 0x400;
use constant RTF_STATIC      => 0x800;
use constant RTF_BLACKHOLE   => 0x1000;
use constant RTF_PRIVATE     => 0x2000;
use constant RTF_PROTO2      => 0x4000;
use constant RTF_PROTO1      => 0x8000;

# ire routing type constants for re_ire_type (inet/ip.h)
use constant IRE_BROADCAST           => 0x0001;
use constant IRE_DEFAULT             => 0x0002;
use constant IRE_LOCAL               => 0x0004;
use constant IRE_LOOPBACK            => 0x0008;
use constant IRE_PREFIX              => 0x0010;
use constant IRE_CACHE               => 0x0020;
use constant IRE_IF_NORESOLVER       => 0x0040;
use constant IRE_IF_RESOLVER         => 0x0080;
use constant IRE_HOST                => 0x0100;
use constant IRE_HOST_REDIRECT       => 0x0200;

# tcp connection state constants for tcpConnState (inet/mib2.h)
use constant MIB2_TCP_closed	  => 1;
use constant MIB2_TCP_listen	  => 2;
use constant MIB2_TCP_synSent	  => 3;
use constant MIB2_TCP_synReceived => 4;
use constant MIB2_TCP_established => 5;
use constant MIB2_TCP_finWait1	  => 6;
use constant MIB2_TCP_finWait2	  => 7;
use constant MIB2_TCP_closeWait	  => 8;
use constant MIB2_TCP_lastAck	  => 9;
use constant MIB2_TCP_closing	  => 10;
use constant MIB2_TCP_timeWait	  => 11;
use constant MIB2_TCP_deleteTCB	  => 12;

# udp entry state constants for ue_state (inet/mib2.h)
use constant MIB2_UDP_unbound   => 1;
use constant MIB2_UDP_idle      => 2;
use constant MIB2_UDP_connected => 3;
use constant MIB2_UDP_unknown   => 4;

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
	    croak "Your vendor has not defined Solaris::MIB2 macro $constname";
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

bootstrap Solaris::MIB2 $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Solaris::MIB2 - Perl extension for reading network device status
and throughput information.

=head1 SYNOPSIS

  use Solaris::MIB2 ':all';

  $mib = new Solaris::MIB2;
  foreach my $entry ( @{$mib->{ipNetToMediaEntry}} ) {
     print "Device: $entry->{ipNetToMediaIfIndex}\n";
     print "IP Address: $entry->{ipNetToMediaNetAddress}\n";
     print "Phys Address: $entry->{ipNetToMediaPhysAddress}\n";
     ...
  }

=head1 DESCRIPTION

MIB or Management Information Base is a collection of data describing the operations of
a particular device on a network. Normally, MIB data is delivered through SNMP (Simple
Network Management Protocol). The detailed description of information elements, maintained
within a MIB database could be found in RFC 1213.
Reading MIB data through SNMP is fairly involved and requires availability of a heavy duty
SNMP infrastructure - SNMP agents, management stations, etc. Solaris::MIB2 allows for a
simplified retrieval of the MIB data via a hierarchical hash interface. In order to read 
tcp statistics, for instance, one would just have to create an instance of Solaris::MIB2 and
read the values, using the hash reference, returned from the 'new' function:

   use Solaris::MIB2;

   $mib = new Solaris::MIB2;
   print $mib->{tcpInSegs}, $mib->{tcpOutSegs}, "\n";
   ...

Solaris::MIB2 utilizes the fact that Solaris stream modules maintain extensive statistical
data pertinent to the operations and throughput of a particular network device. In addition
to normal data, which can be written out to the network through the streams mechanism, 
control messages can also be sent downstream. One of the control messages is the option
management request, which instructs the stream modules to return all available statistical 
information. Unfortunately, retrieving MIB data is 'all-or-none' proposition - i.e. once
a control message is sent downstream, all stream modules will send their information back so
that it is impossible to just retrieve the data, pertinent to, say, UDP. Hence, Solaris::MIB2
extension is NOT a tied-hash - i.e. reading a particular value from the MIB handle doesn't 
trigger a control message to be sent downstream. Instead, when the instance of Solaris::MIB2
is first constructed, the message is sent and all information, returned by the stream modules,
is saved into the hierarchial hash structure. In order to refresh the values, 'update' function
shall be used as follows:
   
   use Solaris::MIB2;

   $mib = new Solaris::MIB2;
   print $mib->{tcpInSegs}, "\n";
   ...
   $mib->update();
   print $mib->{tcpInSegs}, "\n";
   ...

Internally, Solaris::MIB2 constructs a stack of streams modules for the sole purpose of
retrieving the MIB data. By default (i.e. if no parameter is passed to the 'new' function)
it will attempt to open '/dev/arp' as it doesn't require any special privileges. The
'/dev/arp' streams stack seems to contain all the necessary stream modules, therefore, all 
statistics should be accurate. 
To make sure that the stack is constructed exactly to your specification, you may want to 
create an instance of Solaris::MIB2 over the '/dev/ip' as follows:

   use Solaris::MIB2;

   $mib = new Solaris::MIB2 '/dev/ip';

On Solaris, however, '/dev/ip' is only accesible by root and members of sys group, therefore the
script should be run with sufficient level of privileges. One approach is to make every
Solaris::MIB2 script setgroupid 'sys', which is fairly secure as starting from Solaris 2.6 OS
supports secure setuid/setgroupid scripts. In fact, this is exactly how netstat command is setup
under Solaris - it is setgroupid sys. 


=head2 EXPORT

None by default.


=head1 AUTHOR

Alexander Golomshtok, golomshtok_alexander@jpmorgan.com

=head1 SEE ALSO

L<perl>.

=cut
