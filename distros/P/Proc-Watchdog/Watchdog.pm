package Proc::Watchdog;

require 5.005_62;
use Carp;
use strict;
use warnings;
use IO::File;
our $VERSION = '1.01';

sub new {
    my $type = shift;
    my $class = ref($type) || $type || "Proc::Watchdog";

    my $flags = shift;

    bless { path => ($flags->{-path} || '/tmp') ,
	    file => undef
	}, $class;
}

sub _unlink_file ($) {
    my $self = shift;

    if ($self->{file}) {
	unlink $self->{file};
	delete $self->{file};
    }
}

sub _create_file ($$) {
    my $self = shift;
    my $time = shift;

    $self->{file} = $self->{path} . '/watchdog.' . $$;
    
    my $fh = new IO::File ">" . $self->{file}
	or croak "Cannot create watchdog file ", $self->{file}, ": $!\n";
    
    $fh->print($time, "\n");
    $fh->close;
}

sub alarm ($$) {
    my $self = shift;
    my $time = shift;

    $self->_unlink_file;

    if ($time < 0) {
	croak "->alarm() must be called with a positive timeout\n";
    }
    elsif ($time == 0) {
	return;
    }
    else {
	$self->_create_file($time);
    }
}

sub reset () {
    my $self = shift;

    $self->_unlink_file;
}

sub DESTROY {
    my $self = shift;
    $self->_unlink_file;
}

1;

__END__

=head1 NAME

Proc::Watchdog - Perl extension to implement (more) reliable watchdog of processes

=head1 SYNOPSIS

  use Proc::Watchdog;

  my $w = new Proc::Watchdog { -path => '/tmp' };

  $w->alarm(30);		# Kill me in 30 secs if I don't reset

  # Your code goes here

  $w->reset;			# Reset the kill-clock

=head1 DESCRIPTION

This code implements a simple but effective mechanism to support
Watchdogs in your code. A watchdog is a timer that fires a determined
action after a timeout period has expired and can be used to recover
hung processes. In our particular scenario, we found a number of
possible failures that would let perl daemons that access database
servers hung forever. alarm() was not an option as the client
libraries supplied by the vendor already used the ALRM signal
internally, so there was no way to quickly recover from these
failures.

It works by creating a file in the path supplied by the `-path'
argument as seen in the synopsis. If the path is not specified, it
will default to '/tmp', which is nice because this dir is usually
cleaned-up as part of the boot process.

The file is created each time the C<-E<gt>alarm($time)> method is invoked,
and the value of C<$time> is stored in it. The call to C<-E<gt>reset>
unlink()s the file.

A separate daemon (watchd) included along with this module, is called
from cron or another similar service to check on the path. It scans
the watchdog files in there looking for files older than the number of
seconds in them. After files matching this criteria are found, thus
hung processes, a SIGTERM followed by a SIGKILL are sent to the pid
and the watchdog file is unlinked. The amount of time between the TERM
and KILL are configurable in the command line.

Please do a

		watchd -h

for more information about its usage.

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 1.00

Original version; created by h2xs 1.20 with options

  -ACOXcfn
	Proc::Watchdog
	-v
	1.00

=item 1.01

Added the C<DESTROY> method. Now, when an object gets out of scope or
is otherwise collected, the file will be automatically C<unlink()>ed
to prevent spurious C<kill()>s.

=back


=head1 AUTHOR

Luis E. Munoz <lem@cantv.net>

=head1 SEE ALSO

perl(1).

=cut
