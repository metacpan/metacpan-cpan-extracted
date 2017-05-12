package Nmap::Scanner::Scanner;

use File::Spec;
use Nmap::Scanner::Backend::XML;
use LWP::UserAgent;
use File::Temp;
use strict;

=pod

=head1 DESCRIPTION

This is the primary class of this module; it is the driver for
the Nmap::Scanner hierarchy.  To use it, create an instance of
Nmap::Scanner, possibly set the path to Nmap with nmap_location()
(the default behaviour of this class is to search for nmap in
the PATH variable.

my $nmap = new Nmap::Scanner();
$nmap->nmap_location('/usr/local/bin/nmap');

Set any options you wish to use in order to run the scan in either
batch or event mode, and then call scan() to start scanning.  The
results are return in an Nmap::Scanner::Backend::Results object.

my $results = $nmap->scan();

For information on the options presented below, see the man page for
nmap or go to http://www.insecure.org/nmap/.

=head2 NOTE

Some descriptions of methods here are taken directly from the nmap
man page.

=head2 EXAMPLE 

See examples/ directory in the distribution for many more)

  use Nmap::Scanner;
  my $scan = Nmap::Scanner->new();
  
  $scan->add_target('localhost');
  $scan->add_target('host.i.administer');
  $scan->add_scan_port('1-1024');
  $scan->add_scan_port('31337');
  $scan->tcp_syn_scan();
  $scan->noping();
  
  my $results = $scan->scan();
  
  my $hosts = $results->gethostlist();
  
  while (my $host = $hosts->get_next()) {
  
      print "On " . $host->hostname() . ": \n";
  
      my $ports = $host->get_port_list();
  
      while (my $port = $ports->get_next()) {
          print join(' ',
              'Port',
              $port->service() . '/' . $port->portid(),
              'is in state',
              $port->state(),
              "\n"
          );
      }
  
  }

=cut

sub new {
    my $class = shift;
    my $you = { OPTS => {'-oX' => '-'}, DEBUG => 0};
    return bless $you, $class;
}

=pod

=head2 SCAN EVENTS

Register for any of the below events if you wish to use Nmap::Scanner
in event-driven mode.

=head2 register_scan_complete_event(\&host_done)

Register for this event to be notified when a scan of a 
host is complete.  Pass in a function reference that can
accept a $self object reference and a reference to an
Nmap::Scanner::Host object.

host_done($self, $host);


=cut

sub register_scan_complete_event {
    $_[0]->{'SCAN_COMPLETE_EVENT'} = [$_[0], $_[1]];
    return $_[0];
}

=pod

=head2 register_scan_started_event(\&scan_started);

Register for this event to be notified when nmap has started to
scan one of the targets specified in add_target.  Pass in a 
function reference that can accept a $self object reference,
and a reference to an Nmap::Scanner::Host object.

scan_started($self, $host);

=cut

sub register_scan_started_event {
    $_[0]->{'SCAN_STARTED_EVENT'} = [$_[0], $_[1]];
    return $_[0];
}

=pod

=head2 register_host_closed_event(\&host_closed);

Register to be notified if a scanned host is found to
be closed (no open ports).  Pass in a function reference
that can take an $self object reference and a reference to
a Host object.

XXX --- TBD (not implemented yet).

host_closed($self, $host);

=cut

sub register_host_closed_event {
    $_[0]->{'HOST_CLOSED_EVENT'} = [$_[0], $_[1]];
    return $_[0];
}

=pod

=head2 register_port_found_event(\&port_found);

Register to be notified when a port is scanned on a host.  The
port may be in any state ... closed, open, filtered.  Pass a
reference to a function that takes a $self object reference,
a Host reference, and a Port reference.

port_found($self, $host, $port);

=cut

sub register_port_found_event {
    $_[0]->{'PORT_FOUND_EVENT'} = [$_[0], $_[1]];
    return $_[0];
}

=pod

=head2 register_no_ports_open_event(\&port_found);

Register to be notified in the event that no ports are found
to be open on a host.  Pass in a reference to a function that
takes a $self object reference, a Host reference, and a reference
to an ExtraPorts object.  The ExtraPorts object describes ports
that are in a state other than open (e.g. flitered, closed).

port_found($self, $host, $extra_ports);

=cut

#  Function pointer that receives host name, IP, and status of all ports
sub register_no_ports_open_event {
    $_[0]->{'NO_PORTS_OPEN_EVENT'} = [$_[0], $_[1]];
    return $_[0];
}

=head2 register_task_started_event(\&task_begin);

Register to be notified when an internal nmap task starts.
Pass in a reference to a function that takes a $self object 
reference and an Nmap::Scanner::Task reference.  Note that
end_time() will be undefined in the Task instance as this is
a begin event.

task_begin($self, $task);

=cut

#  Function pointer that receives Nmap::Scanner::Task instance
sub register_task_started_event {
    $_[0]->{'TASK_STARTED_EVENT'} = [$_[0], $_[1]];
    return $_[0];
}

=head2 register_task_ended_event(\&task_end);

Register to be notified when an internal nmap task ends.
Pass in a reference to a function that takes a $self object 
reference and an Nmap::Scanner::Task reference.  

task_end($self, $task);

=cut

#  Function pointer that receives Nmap::Scanner::Task instance
sub register_task_ended_event {
    $_[0]->{'TASK_ENDED_EVENT'} = [$_[0], $_[1]];
    return $_[0];
}

=head2 register_task_progress_event(\&task_progress);

Register to be notified when an internal nmap task progress
event is fired; this happens when a task takes more than a
few seconds to complete (good for GUIs).

Pass in a reference to a function that takes a $self object 
reference and an Nmap::Scanner::TaskProgress reference.  

task_progress($self, $task_progress);

=cut

#  Function pointer that receives Nmap::Scanner::Task instance
sub register_task_progress_event {
    $_[0]->{'TASK_PROGRESS_EVENT'} = [$_[0], $_[1]];
    return $_[0];
}

=pod

=head2 debug()

Set this to a non-zero value to see debugging output.

=cut

sub debug {
    (defined $_[1]) ? ($_[0]->{DEBUG} = $_[1]) : return $_[0]->{DEBUG};
}

=pod

=head2 norun()

Set this to non-zero to have Nmap::Scanner::Scanner print the
nmap command line and exit when scan() is called.

=cut

sub norun {
    $_[0]->{'NORUN'} = $_[1];
    return $_[0];
}

=pod

=head2 use_interface()

specify the network interface that nmap should use for scanning

=cut

sub use_interface {
    $_[0]->{OPTS}->{'-e'} = $_[1];
    return $_[0];
}

=pod

=head2 SCAN TYPES

See the nmap man page for descriptions of all these.

=head2 tcp_connect_scan()

=head2 tcp_syn_scan()

=head2 fin_scan()

=head2 xmas_scan()

=head2 null_scan()

=head2 ping_scan()

=head2 udp_scan()

=head2 protocol_scan()

If this scan is used, the protocols can be retrieved from
the Nmap::Scanner::Host objects using the method
get_protocol_list(); this method returns a list of
Nmap::Scanner::Port object references of type 'ip.'

=head2 idle_scan($zombie_host, $probe_port)

=head2 ack_scan()

=head2 window_scan()

=head2 version_scan($intestity)

=head2 rpc_scan()

=cut

sub tcp_connect_scan {
    $_[0]->{TYPE} = 'T';
    return $_[0];
}

sub tcp_syn_scan {
    $_[0]->{TYPE} = 'S';
    return $_[0];
}

sub fin_scan {
    $_[0]->{TYPE} = 'F';
    return $_[0];
}

sub xmas_scan {
    $_[0]->{TYPE} = 'X';
    return $_[0];
}

sub null_scan {
    $_[0]->{TYPE} = 'N';
    return $_[0];
}

sub ping_scan {
    $_[0]->{TYPE} = 'P';
}

sub udp_scan {
    $_[0]->{UDPSCAN} = 'U';
    return $_[0];
}

sub protocol_scan {
    $_[0]->{TYPE} = 'O';
    return $_[0];
}

sub idle_scan {
    $_[0]->{TYPE} = "I $_[1]";
    $_[0]->{TYPE} .= ":$_[2]" if $_[2];
    return $_[0];
}

sub ack_scan {
    $_[0]->{TYPE} = 'A';
    return $_[0];
}

sub window_scan {
    $_[0]->{TYPE} = 'W';
    return $_[0];
}

sub rpc_scan {
    $_[0]->{'OPTS'}->{'-sR'} = '';
    return $_[0];
}

sub version_scan {
    my $intensity = $_[1] || '5';
    $_[0]->{'OPTS'}->{'-sV'} = "--version-intensity $intensity";
    return $_[0];
}

=pod

=head2 SPECIFYING PORTS TO SCAN

Use add_scan_port($port_spec) to add one or more ports
to scan.  $port_spec can be a single port or a range:  
$n->add_scan_port(80) or $n->add_scan_port('80-1023');

Use delete_scan_port($portspec) to delete a port or range
of ports.

Use reset_scan_ports() to cancel any adds done with add_scan_port().

Use getports to get a hash reference in which the keys are the
ports you specified with add_scan_port().

=cut

sub add_scan_port {

    my $self = shift;

    for my $port_spec (@_) {
        $self->{PORTS}->{$port_spec} = 1;
    }

    return $self;
}

sub delete_scan_port {

    my $self = shift;

    for my $port_spec (@_) {
        delete $self->{'PORTS'}->{$port_spec} if 
            exists $self->{'PORTS'}->{$port_spec};
    }

    return $self;
}

sub reset_scan_ports {

    $_[0]->{PORTS} = undef;

    return $_[0];
}

sub getports {

    return $_[0]->{PORTS};
}

=pod

=head2 SPECIFYING TARGETS TO SCAN

See the nmap documentation for the full syntax nmap supports
for specifying hosts / subnets / networks to scan.  

Use add_target($hostspec) to add a target to scan.

Use delete_target($hostspec) to delete a target from the
list of hosts/networks to scan (must match text used in
add_target($hostspec)).

Use reset_targets() to cancel any targets you specified
with add_target().

=cut

sub add_target {

    my $self = shift;

    for my $host_spec (@_) {
        $self->{'TARGETS'}->{$host_spec} = 1;
    }

    return $self;
}

sub delete_target {

    my $self = shift;

    for my $host_spec (@_) {

        $self->{'TARGETS'}->{$host_spec} = 1;

        delete $self->{'TARGETS'}->{$host_spec} if 
            exists $self->{'TARGETS'}->{$host_spec};

    }

    return $self;
}

sub reset_targets {

    $_[0]->{'TARGETS'} = undef;

    return $_[0];
}

=pod

=head2 PING OPTIONS

nmap has a very flexible mechanism for setting how a ping
is interpreted for hosts during a scan.  See the nmap
documentation for more details.

Use no_ping() to not ping hosts before scanning them.

Use ack_ping($port) to use a TCP ACK packet as a ping to
the port specified on each host to be scanned.

Use syn_ping($port) to use a TCP SYN packet as a ping
to the port specified on each host to be scanned.

Use icmp_ping() to use a true ICMP ping for each host 
to be scanned.

Use ack_icmp_ping($port) to use an ICMP ping, then a TCP ACK packet 
as a ping (if the ICMP ping fails) to the port specified on each host 
to be scanned.  This is the default behaviour if no ping options are
specified.

=cut

sub no_ping {

    $_[0]->{'OPTS'}->{'-P'} = "0";

    return $_[0];
}

sub ack_ping {

    $_[0]->{'OPTS'}->{'-P'} = "T$_[1]";

    return $_[0];
}

sub syn_ping {

    $_[0]->{'OPTS'}->{'-P'} = "S$_[1]";

    return $_[0];
}

sub icmp_ping {

    $_[0]->{'OPTS'}->{'-P'} = "I";

    return $_[0];
}

sub ack_icmp_ping {

    $_[0]->{'OPTS'}->{'-P'} = "B$_[1]";

    return $_[0];
}

=pod

=head2 TIMING OPTIONS

Use these methods to set how quickly or slowly nmap scans
a host.  For more detail on these methods, see the nmap
documentation.

From slowest to fastest:

=item * paranoid_timing()

=item * sneaky_timing()

=item * polite_timing()

=item * normal_timing()

=item * aggressive_timing()

=item * insane_timing()

=cut

sub paranoid_timing {

    $_[0]->{'OPTS'}->{'-T'} = 'Paranoid';

    return $_[0];
}

sub sneaky_timing {

    $_[0]->{'OPTS'}->{'-T'} = 'Sneaky';

    return $_[0];
}

sub polite_timing {

    $_[0]->{'OPTS'}->{'-T'} = 'Polite';

    return $_[0];
}

sub normal_timing {

    $_[0]->{'OPTS'}->{'-T'} = 'Normal';

    return $_[0];
}

sub aggressive_timing {

    $_[0]->{'OPTS'}->{'-T'} = 'Aggressive';

    return $_[0];
}

sub insane_timing {

    $_[0]->{'OPTS'}->{'-T'} = 'Insane';

    return $_[0];
}

=pod

=head2 OTHER OPTIONS

There are many other nmap options.  I have done my best
to to represent them all.  I welcome patches from 
users for any that I have missed.

For details on any of these methods see the nmap 
documentation.

=cut

=pod

=head2 guess_os()

Try and guess the operating system of each target host
using TCP fingerprinting.

=cut

sub guess_os {

    $_[0]->{'OPTS'}->{'-O'} = "";

    return $_[0];
}

=pod

=head2 fast_scan()

Only scan for services listed in nmap's services file.

=cut

sub fast_scan {

    $_[0]->{'OPTS'}->{'-F'} = "";

    return $_[0];
}

=pod

=head2 ident_check() [DEPRECATED]

Attempts to find the user that owns each open port by
querying the ident damon of the remote host.  See the
nmap man page for more details.  Support for ident 
checking is being removed from nmap as so few hosts 
allow or utilize IDENT anymore.

=cut

sub ident_check {

    $_[0]->{'OPTS'}->{'-I'} = "";

    return $_[0];
}

=pod

=head2 host_timeout($milliseconds)

Specifies how much time nmap spends on scanning each 
host before giving up.  Not set by default.

=cut

sub host_timeout {

    $_[0]->{'OPTS'}->{'--host-timeout'} = $_[1];

    return $_[0];
}

=pod

=head2 max_rtt_timeout($milliseconds)

Specifies the maximum time nmap should
wait for a response to a probe of a port.

=cut

sub max_rtt_timeout {

    $_[0]->{'OPTS'}->{'--max_rtt_timeout'} = $_[1];

    return $_[0];
}

=head2 max_rtt_timeout($milliseconds)

Specifies the minimum time nmap should
wait for a response to a probe of a port.  Nmap
reduces the amoutn of time per response if the
scanned machines respond quickly; it will not
go below this threshold.

=cut

sub min_rtt_timeout {

    $_[0]->{'OPTS'}->{'--min_rtt_timeout'} = $_[1];

    return $_[0];
}

=head2 initial_rtt_timeout($milliseconds)

Specifies the initial probe timeout.  See the
nmap man page for more detail.

=cut

sub initial_rtt_timeout {

    $_[0]->{'OPTS'}->{'--initial_rtt_timeout'} = $_[1];

    return $_[0];
}

=pod

=head2 max_parallelism($number)

Specifies  the  maximum  number of scans Nmap is allowed to
perform in parallel.

=cut

sub max_parallelism {

    $_[0]->{'OPTS'}->{'--max_parallelism'} = $_[1];

    return $_[0];
}

=pod

=head2 scan_delay($milliseconds)

Specifies the minimum amount of time Nmap must wait between
probes.

=cut

sub scan_delay {

    $_[0]->{'OPTS'}->{'--scan_delay'} = $_[1];

    return $_[0];
}

=pod

=head2 open_nmap() 

This method sets up a scan, but instead of actually performing
the scan, it returns the PID, read filehandle, write file
handle, and error file handle of the opened nmap process.  Use
this if you wish to just use Nmap::Scanner::Scanner as your 
front end to set up a scan but you wish to process it in some
way not supported by Nmap::Scanner.

Example:

my $scan = Nmap::Scanner->new();

my $opts = '-sS -P0 -p 1-1024 192.168.32.1-255'; 

my ($pid, $in, $out, $err) = $scan->open_nmap($opts);

=cut

sub open_nmap {
    
    my $this = shift;

    my $fast_options = shift || "";

    my $cmd = $this->_setup_cmdline($fast_options);

    die "$cmd\n" if $this->{'NORUN'};

    my $processor = $this->_setup_processor();

    my ($pid, $read, $write, $error)= $processor->start_nmap($cmd);
    return ($pid, $read, $write, $error);

}

=pod

=head2 scan()

Perform the scan.  Returns a populated instance of 
Nmap::Scanner::Backend::Results when scanning in
batch mode (as opposed to event-driven mode).

=cut

sub scan {
    
    my $this = shift;

    my $fast_options = shift || "";

    #  If we have a file, add "< "

    my $cmd = "";

    $cmd = $this->_setup_cmdline($fast_options);

    die "$cmd\n" if $this->{'NORUN'};

    Nmap::Scanner::debug("command line: $cmd");

    my $processor = $this->_setup_processor();

    my ($pid, $read, $write, $error) = $processor->start_nmap($cmd);
    close($write);

    $this->{'RESULTS'} = $processor->process($pid, $read, $cmd, $error);

    return $this->{'RESULTS'};

}

=pod

=head2 scan_from_file()

Recreate a scan from an existing nmap XML-formatted
output file.  Pass this method in the name of an
XML file created by a previously performed nmap
scan done in XML output mode and the file will be
processed in the same manner as a live scan would
be processed. If the passed in file looks like a 
URI, the module will attempt to retrieve the file 
using an HTTP GET simple (LWP::UserAgent).

Examples:

 my $scanner = Nmap::Scanner->new();
 my $results = $scanner->scan_from_file('/path/to/scan_output.xml');
 my $results = $scanner->scan_from_file('http://example.com/results.xml');

=cut

sub scan_from_file {
    
    my $this = shift;

    my $filename = shift || 
        die "scan_from_file: missing filename to read from!";

    my $handle;

    if ($filename =~ m#://#) {

        my $agent = LWP::UserAgent->new(
                        'agent' => "Nmap::Scanner/$Nmap::Scanner::VERSION");
        my $response = $agent->get($filename);

        if (! $response->is_success()) {
            die "scan_from_file: unable to retrieve $filename: " .
                $response->status_line();
        }

        my $dir = File::Temp::tempdir( CLEANUP => 1 );
        ($handle, $filename) = File::Temp::tempfile( DIR => $dir );

        print $handle $response->content();

        seek($handle, 0, 0);

    } else {

        local (*READ);

        open (READ, "< $filename") ||
            die "scan_from_file: Can't read from $filename: $!";

        $handle = *READ;

    }

    my $processor = $this->_setup_processor();

    $this->{'RESULTS'} = $processor->process($$, $handle, $filename);

    return $this->{'RESULTS'};

}

sub _setup_cmdline {

    my $this = shift;
    my $fast_options = shift || "";

    my $nmap = $this->{'NMAP'} || _find_nmap();

    die "Can't find nmap!\n" unless $nmap;

    unless (-f $nmap && -x _) {
        die "Can't execute specified nmap: $this->{NMAP}\n";
    }

    local($_);

    #  Single quotes around command to handle spaces in full path
    #  ... for Windows/Cygwin users.  Fix by Jon Amundsen.

    my $cmd = "'$nmap' -v -v -v";

    if (! $fast_options) {

        $cmd .= " -s$this->{'TYPE'}" if defined $this->{'TYPE'};

        $cmd .= " -s$this->{'UDPSCAN'}" if $this->{'UDPSCAN'};

        if ($this->{PORTS}) {
            $cmd .= " -p " . join(',', keys %{$this->{PORTS}});
        }

        #  Gather other options
        if ($this->{'OPTS'}) {
            for my $opt (keys %{$this->{OPTS}}) {
                $cmd .= " " . $opt . " " . $this->{'OPTS'}->{$opt};
            }
        }

        $cmd .= " " . join(' ', keys %{$this->{'TARGETS'}});

    } else {
        $cmd .= " $fast_options -oX -";
    }

    return $cmd;

}

sub _setup_processor {

    my $this = shift;

    my $processor = Nmap::Scanner::Backend::XML->new();

    #  All backend processors support these.
    $processor->debug($this->{'DEBUG'});
    $processor->register_scan_complete_event($this->{'SCAN_COMPLETE_EVENT'});
    $processor->register_scan_started_event($this->{'SCAN_STARTED_EVENT'});
    $processor->register_host_closed_event($this->{'HOST_CLOSED_EVENT'});
    $processor->register_port_found_event($this->{'PORT_FOUND_EVENT'});
    $processor->register_no_ports_open_event($this->{'NO_PORTS_OPEN_EVENT'});
    $processor->register_task_started_event($this->{'TASK_STARTED_EVENT'});
    $processor->register_task_ended_event($this->{'TASK_ENDED_EVENT'});
    $processor->register_task_progress_event($this->{'TASK_PROGRESS_EVENT'});

    return $processor;

}

sub results {
    (defined $_[1]) ? ($_[0]->{RESULTS} = $_[1]) : return $_[0]->{RESULTS};
}

=pod

=head2 nmap_location($path)

If nmap is not in your PATH, you can specify where it
is using this method.

=cut

sub nmap_location {
    (defined $_[1]) ? ($_[0]->{NMAP} = $_[1]) : return $_[0]->{NMAP};
}

sub _find_nmap {

    local($_);
    local(*DIR);

    my $sep = ($^O =~ /Win32/) ? ';' : ':';

    for my $dir (split($sep, $ENV{'PATH'})) {
        opendir(DIR,$dir) || next;
        my @files = (readdir(DIR));
        closedir(DIR);
        my $path;
        for my $file (@files) {
            next unless $file =~ /^nmap(?:.exe)?$/;
            $path = File::Spec->catfile($dir, $file);
            #  Should symbolic link be considered?  Helps me on cygwin but ...
            next unless -r "$path" && (-x _ || -l _);
            return $path;
            last DIR;
        }
    }

}

1;
