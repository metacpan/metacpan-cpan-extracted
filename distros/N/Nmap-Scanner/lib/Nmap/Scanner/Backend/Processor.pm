package Nmap::Scanner::Backend::Processor;

=pod

=head1 NAME - Nmap::Scanner::Processor

This is the base class for output processors for Nmap::Scanner.  

=cut

use strict;
use IPC::Open3;
use FileHandle;

sub new {
    my $class = shift;
    my $you = {};
    return bless $you, $class;
}

=pod

=head1 register_scan_complete_event()

Use this to tell the backend processor you want
to be notified when the scan of a HOST is 
complete.  

Pass in a reference to a function that will
receive two arguments when called:  A reference
to the calling object and a reference to an
Nmap::Scanner::Host instance.

=cut

sub register_scan_complete_event {
    $_[0]->{'SCAN_COMPLETE_EVENT'} = $_[1];
}

=pod

=head1 register_scan_started_event()

Use this to tell the backend processor you want
to be notified when the scan of a HOST has
started.  

Pass in a reference to a function that will
receive two arguments when called:  A reference
to the calling object and a reference to an
Nmap::Scanner::Host instance.

=cut

sub register_scan_started_event {
    $_[0]->{'SCAN_STARTED_EVENT'} = $_[1];
}

=pod

=head1 register_host_closed_event()

Use this to tell the backend processor you want
to be notified when nmap has determined that the
current host is not available (up).

Pass in a reference to a function that will
receive two arguments when called:  A reference
to the calling object and a reference to an
Nmap::Scanner::Host instance.

=cut

sub register_host_closed_event {
    $_[0]->{'HOST_CLOSED_EVENT'} = $_[1];
}

=pod

=head1 register_port_found_event()

Use this to tell the backend processor you want
to be notified when an open port has been found
on the current host being scanned.

Pass in a reference to a function that will
receive three arguments when called:  A reference
to the calling object, a reference to an
Nmap::Scanner::Host instance, and a reference to
an Nmap::Scanner::Port containing information on
the port.

=cut

sub register_port_found_event {
    $_[0]->{'PORT_FOUND_EVENT'} = $_[1];
}

=pod

=head1 register_no_ports_open_event()

Use this to tell the backend processor you want
to be notified when the scan of a HOST has
yielded NO open ports.  

Pass in a reference to a function that will
receive three arguments when called:  A reference
to the calling object, a reference to an
Nmap::Scanner::Host instance, and a reference to
an Nmap::Scanner::ExtraPorts instance with some
information on the states of the non-open ports.

=cut

sub register_no_ports_open_event {
    $_[0]->{'NO_PORTS_OPEN_EVENT'} = $_[1];
}

=head1 register_task_started_event()

Use this to tell the backend processor you want
to be notified when an nmap task has started.

Pass in a reference to a function that will
receive two arguments when called:  A reference
to the calling object and a reference to an
Nmap::Scanner::Task instance.  Note that since
this is the begin part of a task end_time() will
be undefined.

=cut

sub register_task_started_event {
    $_[0]->{'TASK_STARTED_EVENT'} = $_[1];
}

=head1 register_task_ended_event()

Use this to tell the backend processor you want
to be notified when an nmap task has ended.

Pass in a reference to a function that will
receive two arguments when called:  A reference
to the calling object and a reference to an
Nmap::Scanner::Task instance. 

=cut

sub register_task_ended_event {
    $_[0]->{'TASK_ENDED_EVENT'} = $_[1];
}

=head1 register_task_progress_event()

Use this to tell the backend processor you want
to be notified when an nmap task progress event occurs.

Pass in a reference to a function that will
receive two arguments when called:  A reference
to the calling object and a reference to an
Nmap::Scanner::TaskProgress instance. 

=cut

sub register_task_progress_event {
    $_[0]->{'TASK_PROGRESS_EVENT'} = $_[1];
}


=pod

=head1 results()

Return the Nmap::Scanner::Results instance
created by the scan.

=cut

sub results {
    (defined $_[1]) ? ($_[0]->{RESULTS} = $_[1]) : return $_[0]->{RESULTS};
}

sub debug {
    (defined $_[1]) ? ($_[0]->{DEBUG} = $_[1]) : return $_[0]->{DEBUG};
}

=pod

=head1 start_nmap()

This method may be called by the user.  It starts the nmap process using 
the options set by the user via the scan() method or setters of 
Nmap::Scanner::Scanner.  The method returns the PID of the child 
nmap process, a reader handle to read from the nmap process, 
a write handle to write to nmap, and an error handle which will 
contain data if nmap throws an error.

Example code:

sub process {

    my $self = shift;
    my $cmdline = shift;

    my ($pid, $in, $out, $err) = $self->SUPER::start_nmap($cmdline);

    #  Process filehandles

}

=cut

sub start_nmap {

    my $self = shift;
    my $cmdline = shift;

    my ($readfh, $writefh, $errorfh) = 
        (FileHandle->new(), FileHandle->new(), FileHandle->new());

    my $pid = 0;

    if (-f $cmdline) {
        open($readfh, "+< $cmdline") ||
            die "Can't read from input file $cmdline: $!\n";
        $writefh = $readfh;
        my $error = "";
        open($errorfh, '<', \$error);
    } else {
        $pid = open3($writefh, $readfh, $errorfh, $cmdline) ||
                     die "Can't open pipe to $cmdline: $!\n";
        $readfh->flush();
        $errorfh->flush();
    }

    return ($pid, $readfh, $writefh, $errorfh);
    
}

=head1 start_nmap2()

This method is called by the sub-classed processor to start the nmap 
process using options set by the user via the scan() method or 
setters of Nmap::Scanner::Scanner.  The sub-classed processor is 
returned the PID of the child nmap process and a reader handle to read
from the nmap process.

Example code:

sub process {

    my $self = shift;
    my $cmdline = shift;

    my ($pid, $in) = $self->SUPER::start_nmap2($cmdline);

    #  Process filehandles

}

=cut
sub start_nmap2{

    my $self = shift;
    my $cmdline = shift;

    local(*READ);

    my $pid = open(\*READ, "-|", "$cmdline 2>&1");
    unless (defined $pid) {
                  die "Can't open pipe to nmap: $!\n";
          }

    my $read = *READ;
    $read->flush();

    
    return ($pid, $read);
    
}

=pod

=head1 notify_scan_started()

Notify the listener that a scan started
event has occurred.  Caller is passed a
reference to the callers self reference
(object instance) and an Nmap::Scanner::Host
instance.

=cut

sub notify_scan_started {

    &{$_[0]->{'SCAN_STARTED_EVENT'}->[1]}(
        $_[0]->{'SCAN_STARTED_EVENT'}->[0], $_[1]
    ) if defined $_[0]->{'SCAN_STARTED_EVENT'}->[1];

}

=pod

=head1 notify_scan_complete()

Notify the listener that a scan complete
event has occurred.  Caller is passed a
reference to the callers self reference
(object instance) and an Nmap::Scanner::Host
instance.

=cut

sub notify_scan_complete {
    &{$_[0]->{'SCAN_COMPLETE_EVENT'}->[1]}(
        $_[0]->{'SCAN_COMPLETE_EVENT'}->[0], $_[1]
    ) if (defined $_[0]->{'SCAN_COMPLETE_EVENT'}->[1]);
}

=pod

=head1 notify_scan_started()

Notify the listener that a port found
event has occurred.  Caller is passed a
reference to the callers self reference
(object instance), an Nmap::Scanner::Host
instance, and an Nmap::Scanner::Port
instance.

=cut

sub notify_port_found {
    &{$_[0]->{'PORT_FOUND_EVENT'}->[1]}(
        $_[0]->{'PORT_FOUND_EVENT'}->[0], $_[1], $_[2]
    ) if (defined $_[0]->{'PORT_FOUND_EVENT'}->[1]);
}

=pod

=head1 notify_no_ports_open()

Notify the listener that a scan started
event has occurred.  Caller is passed a
reference to the callers self reference
(object instance), an Nmap::Scanner::Host
instance, and an Nmap::Scanner::ExtraPorts
instance.

=cut

sub notify_no_ports_open {
    &{$_[0]->{'NO_PORTS_OPEN_EVENT'}->[1]}(
        $_[0]->{'NO_PORTS_OPEN_EVENT'}->[0], $_[1], $_[2]
    ) if (defined $_[0]->{'NO_PORTS_OPEN_EVENT'}->[0]);
}

=head1 notify_task_started()

Notify the listener that an nmap task begin (taskbegin)
event has occurred.  Caller is passed a
reference to the callers self reference
(object instance) and an Nmap::Scanner::Task
instance.

=cut

sub notify_task_started {

    &{$_[0]->{'TASK_STARTED_EVENT'}->[1]}(
        $_[0]->{'TASK_STARTED_EVENT'}->[0], $_[1]
    ) if defined $_[0]->{'TASK_STARTED_EVENT'}->[1];

}

=head1 notify_task_ended()

Notify the listener that an nmap task end (taskend)
event has occurred.  Caller is passed a
reference to the callers self reference
(object instance) and an Nmap::Scanner::Task
instance.

=cut

sub notify_task_ended {

    &{$_[0]->{'TASK_ENDED_EVENT'}->[1]}(
        $_[0]->{'TASK_ENDED_EVENT'}->[0], $_[1]
    ) if defined $_[0]->{'TASK_ENDED_EVENT'}->[1];

}

=head1 notify_task_progress()

Notify the listener that an nmap task end (taskend)
event has occurred.  Caller is passed a
reference to the callers self reference
(object instance) and an Nmap::Scanner::TaskProgress
instance.

=cut

sub notify_task_progress {

    &{$_[0]->{'TASK_PROGRESS_EVENT'}->[1]}(
        $_[0]->{'TASK_PROGRESS_EVENT'}->[0], $_[1]
    ) if defined $_[0]->{'TASK_PROGRESS_EVENT'}->[1];

}
1;
