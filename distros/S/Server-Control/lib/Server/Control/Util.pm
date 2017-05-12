package Server::Control::Util;
use IO::Socket;
use Proc::Killfam;
use Proc::ProcessTable;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(
  trim
  is_port_active
  process_listening_to_port
  something_is_listening_msg
  kill_my_children
  kill_children
  get_child_pids
  process_table
);

eval { require Unix::Lsof };
my $have_lsof = $Unix::Lsof::VERSION;

sub trim {
    my ($str) = @_;

    for ($str) { s/^\s+//; s/\s+$// }
    return $str;
}

# Return boolean indicating whether $port:$bind_addr is active
#
sub is_port_active {
    my ( $port, $bind_addr ) = @_;

    return IO::Socket::INET->new(
        PeerAddr => $bind_addr,
        PeerPort => $port
    ) ? 1 : 0;
}

# Return the Proc::ProcessTable::Process that is listening to $port and
# $bind_addr. Return undef if no process is listening or we cannot determine
# the process
#
sub process_listening_to_port {
    my ( $port, $bind_addr ) = @_;

    return undef unless $have_lsof;
    $bind_addr = defined($bind_addr) ? "(?:$bind_addr|\\*)" : '.*';
    if ( my $lr = eval { Unix::Lsof::lsof( "-P", "-i", "TCP" ) } ) {
        if (
            my ($row) =
            grep { $_->[1] =~ /^$bind_addr:$port$/ && $_->[2] =~ /^IP/ }
            $lr->get_arrayof_rows( "process id", "file name", "file type" )
          )
        {
            my $pid    = $row->[0];
            my $ptable = process_table();
            if ( my ($proc) = grep { $_->pid == $pid } @{ $ptable->table } ) {
                return $proc;
            }
        }
    }
    return undef;
}

# Return a message like "something is listening to foo:1234", with a
# qualifier about which process is listening if we can determine that
#
sub something_is_listening_msg {
    my ( $port, $bind_addr ) = @_;

    my $proc = process_listening_to_port( $port, $bind_addr );
    my $qualifier =
      $proc
      ? sprintf( ' (possibly pid %d - "%s")', $proc->pid, $proc->cmndline )
      : "";
    sprintf( "something%s is listening to %s:%d",
        $qualifier, $bind_addr, $port );
}

# Kill all children of this process with TERM - specifically for testing purposes.
#
sub kill_my_children {
    my @child_pids = kill_children($$);
    if ( $ENV{TEST_VERBOSE} ) {
        printf STDERR "sending TERM to %s\n", join( ", ", @child_pids )
          if @child_pids;
    }
}

# Kill all children of process $pid with TERM. Return pids killed.
#
sub kill_children {
    my ($pid) = @_;

    my @child_pids = get_child_pids($pid);
    if (@child_pids) {
        Proc::Killfam::killfam( 15, @child_pids );
    }
    return @child_pids;
}

# Return the child pids of process $pid.
#
sub get_child_pids {
    my ($pid) = @_;

    my $pt = process_table();
    return Proc::Killfam::get_pids( $pt->table, $pid );
}

sub process_table {
    return new Proc::ProcessTable( cache_ttys => 1 );
}

1;
