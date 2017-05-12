package Nmap::Scanner;

use vars qw($VERSION @ISA);

$VERSION = '1.0';

#  Set this to 1 and debugging is on for all modules
$Nmap::Scanner::DEBUG = 0;

use Nmap::Scanner::Scanner;
use Nmap::Scanner::Port;
use Nmap::Scanner::Host;
use Nmap::Scanner::OS;
use Nmap::Scanner::PortList;
use Nmap::Scanner::HostList;
use Nmap::Scanner::Util;

@ISA = qw(Nmap::Scanner::Scanner);

#
#  Convenience method for getting to Nmap::Scanner::Scanner.
#

sub new {

    my $class = shift;
    my $self = $class->SUPER::new();
    return bless $self, $class;    

}

sub debug {
    return 0 unless $Nmap::Scanner::DEBUG == 1;
    my $msg = shift;
    print __PACKAGE__ . ": $msg\n";
    return 1;
}

1;

__END__

=head1 NAME

Nmap::Scanner - Perform and manipulate nmap scans using perl

=head1 SYNOPSIS

  Perl extension for performing nmap (www.insecure.org/nmap) scans.

  use Nmap::Scanner;

  #  Batch scan method

  my $scanner = new Nmap::Scanner;
  $scanner->tcp_syn_scan();
  $scanner->add_scan_port('1-1024');
  $scanner->add_scan_port(8080);
  $scanner->guess_os();
  $scanner->max_rtt_timeout(200);
  $scanner->add_target('some.host.out.there.com.org');

  #   $results is an instance of Nmap::Scanner::Backend::Results
  my $results = $scanner->scan();

  #  Print the results out as an well-formatted XML document
  print $results->as_xml();

  #  Event scan method using *new* easier way to set scan options.

  my $scanner = new Nmap::Scanner;
  $scanner->register_scan_started_event(\&scan_started);
  $scanner->register_port_found_event(\&port_found);
  $scanner->scan('-sS -p 1-1024 -O --max-rtt-timeout 200 somehost.org.net.it');

  sub scan_started {
      my $self     = shift;
      my $host     = shift;
  
      my $hostname = $host->hostname();
      my $addresses = join(',', map {$_->addr()} $host->addresses());
      my $status = $host->status();
  
      print "$hostname ($addresses) is $status\n";
  }
  
  sub port_found {
      my $self     = shift;
      my $host     = shift;
      my $port     = shift;
  
      my $name = $host->hostname();
      my $addresses = join(',', map {$_->addr()} $host->addresses());
  
      print "On host $name ($addresses), found ",
            $port->state()," port ",
            join('/',$port->protocol(),$port->portid()),"\n";
  
  }

=head1 DESCRIPTION

This set of modules provides perl class wrappers for the network mapper
(nmap) scanning tool (see http://www.insecure.org/nmap/).  Using these modules,
a developer, network administrator, or other techie can create perl routines
or classes which can be used to automate and integrate nmap scans elegantly 
into new and existing perl scripts.

If you don't have nmap installed, you will need to download it BEFORE you
can use these modules.  Get it from http://www.insecure.org/nmap/.  You will
need nmap 3.10+ installed to use all the features of this module.

=head1 USAGE

The module set consists of a Scanner class and many classes that support
the scanner and encapsulate the data output by nmap as it scans.  The
class that you will likely use most often is Nmap::Scanner.  This class
encapsulates the nmap scanner options and `drives' the scan process.  It
provides a convenience constructor to let you create a scanner
instance (Nmap::Scanner::Scanner instance).

Scans can be done in two modes using this module set: batch mode and
event mode.  

=head2 Batch mode scanning

In batch mode the scan is set up and executed and the results are returned in 
an Nmap::Scanner::Backend::Results object.  This object contains information 
about the scan and a list of the found host objects 
(instances of Nmap::Scanner::Host).  Each host contains a list of found ports 
on that host (instances of Nmap::Scanner::Port).  No information is returned
to the user until the entire scan is complete.

=head2 Event mode scanning

In event mode the user registers interest in one or more scan events by
passing a reference to a callback function to one or more event registration 
functions.  The scanner then calls the callback function during a specifc 
phase of the scan.  It passes the function arguments describing what has 
happened and the data found.

Each function is also passed a reference to the current object
instance of Nmap::Scanner::Scanner (or a subclass of Nmap::Scanner::Scanner)
as the FIRST argument so that subclasses with instance-specific data can 
be easily created (see the Nmap::Scanner::Util package and examples included
with this module for examples).

There are five events that a user can register for: scan started event,
host closed event, no ports open event, port found event, and scan
complete event.   The scan started event occurs at the beginning of
the scan process for EACH host specified with add_target().  The
host closed event is called if a specified host is found to be unavailable
via whatever type of ping has been specified.  The no ports open event
is triggered if no ports are found to be open on a scanned host.  The
port found event is called when nmap identifies a port as open on a host
(if the port is not explicitly passed to -P) or when the state of a port
passed to -P is determined, whether the port is open or not.  The scan 
complete event is called as soon as the scan of a host specified as a
target with add_target() is complete.

=head1 NOTES

Please keep in mind that this is not a complete implementation of nmap in perl; this module is most likely best suited for larger OO projects implemented in
perl, although it certainly can be used for relatively quick and dirty scripts
as well.

=head1 THANKS

Special thanks to Fyodor (fyodor@insecure.org) for creating such a useful
tool and to all the developers and contributors who constantly work to 
improve and fine-tune nmap!

Thanks also to those of you have provided feedback, bug fixes, and enhancement
code, it is very much appreciated!

=head1 NEXT RELEASE

More examples.

More complete documentation.

=head1 AUTHOR

Max Schubert, <maxschube@cpan.org>

=head1 LICENSE

This software is released under the same license and terms as perl itself.

=head1 SEE ALSO

http://www.insecure.org/nmap/

http://nmap-scanner.sf.net/

Nmap::Scanner::Scanner

=cut
