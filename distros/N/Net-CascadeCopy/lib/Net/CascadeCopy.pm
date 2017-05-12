package Net::CascadeCopy;
use strict;
use warnings;

our $VERSION = '0.2.6'; # VERSION

use Mouse;

use Benchmark;
use Log::Log4perl qw(:easy);
use POSIX ":sys_wait_h"; # imports WNOHANG
use Proc::Queue size => 32, debug => 0, trace => 0, delay => 1;

my $logger = get_logger( 'default' );

has data         => ( is => 'ro', isa => 'HashRef', default => sub { return {} } );

has total_time   => ( is => 'rw', isa => 'Num', default => 0 );

has ssh          => ( is => 'ro', isa => 'Str', default => "ssh"   );
has ssh_args     => ( is => 'ro', isa => 'Str', default => "-x -A" );

has command      => ( is => 'ro', isa => 'Str', required => 1  );
has command_args => ( is => 'ro', isa => 'Str', default  => "" );

has source_path  => ( is => 'ro', isa => 'Str', required => 1 );
has target_path  => ( is => 'ro', isa => 'Str', required => 1 );

has output       => ( is => 'ro', isa => 'Str', default => "" );

# maximum number of failures per server
has max_failures => ( is => 'ro', isa => 'Num', default => 3 );

# maximum processes per remote server
has max_forks    => ( is => 'ro', isa => 'Num', default => 2 );

# keep track of child processes
has children     => ( is => 'ro', isa => 'HashRef', default => sub { return {} } );

# for testing purposes
has transfer_map => ( is => 'ro', isa => 'HashRef', default => sub { return {} } );

# sort order
has sort_order   => ( is => 'ro', isa => 'HashRef', default => sub { return {} } );

sub add_group {
    my ( $self, $group, $servers_a ) = @_;

    $logger->info( "Adding group: $group: ",
                   join( ", ", @$servers_a ),
               );

    # initialize data structures
    for my $server ( @{ $servers_a } ) {
        $self->data->{remaining}->{ $group }->{$server} = 1;

        unless ( defined $self->sort_order->{ $group }->{ $server } ) {
            $self->sort_order->{ $group }->{ $server } = scalar keys %{ $self->sort_order->{ $group } };
        }
    }

    # first server to transfer from is the current server
    $self->data->{available}->{ $group }->{localhost} = 1;

    # initialize data structures
    $self->data->{completed}->{ $group } = [];

}

sub get_groups {
    my ( $self ) = @_;

    my @groups;

    for my $group ( keys %{ $self->sort_order } ) {
        push @groups, $group;
    }

    return @groups;
}

sub transfer {
    my ( $self ) = @_;

    my $transfer_start = new Benchmark;

  LOOP:
    while ( 1 ) {
        last LOOP unless $self->_transfer_loop( $transfer_start );
        sleep 1;
    }
}

sub _transfer_loop {
    my ( $self, $transfer_start ) = @_;

    $self->_check_for_completed_processes();

    # keep track if there are any remaining servers in any groups
    my ( $remaining_flag, $available_flag );

    # handle completed processes
    if ( ! scalar keys %{ $self->data->{remaining} } && ! $self->data->{running} ) {
        my $transfer_end = new Benchmark;
        my $transfer_diff = timediff( $transfer_end, $transfer_start );
        my $transfer_time = $self->_human_friendly_time( $transfer_diff->[0] );
        $logger->warn( "Job completed in $transfer_time" );

        my $total_time = $self->_human_friendly_time( $self->total_time );
        $logger->info ( "Cumulative tansfer time of all jobs: $total_time" );

        my $savings = $self->total_time - $transfer_diff->[0];
        if ( $savings ) {
            $savings = $self->_human_friendly_time( $savings );
            $logger->info( "Approximate Time Saved: $savings" );
        }

        my $failure_count;
        for my $group ( $self->get_groups() ) {
            my ( $errors, $failures ) = $self->_get_failed_count( $group );
            $failure_count += $failures;
        }

        if ( $failure_count ) {
            $logger->fatal( "$failure_count Fatal Errors" );
        }
        else {
            $logger->warn( "Completed successfully" );
        }
        return;
    }

    # start new transfers to remaining servers
    for ( 0, 1 ) {
        # code_smell: start 2 transfers each round to keep the
        # test cases from breaking.  need to refactor test cases!
        for my $group ( $self->_get_remaining_groups() ) {
            # group contains servers that still need to be tranferred

            if ( $self->_get_available_servers( $group )  ) {
                # reserve a server to start a new transfer from
                my $source = $self->_reserve_available_server( $group );
                my $target = $self->_reserve_remaining_server( $group );
                $self->_start_process( $group, $source, $target );
            }
        }
    }

    return 1;
}

sub _human_friendly_time {
    my ( $self, $seconds ) = @_;

    return "0 secs" unless $seconds;

    my @time_string;

    if ( $seconds > 3600 ) {
        my $hours = int( $seconds / 3600 );
        $seconds = $seconds % 3600;
        push @time_string, "$hours hrs";
    }
    if ( $seconds > 60 ) {
        my $minutes = int( $seconds / 60 );
        $seconds = $seconds % 60;
        push @time_string, "$minutes mins";
    }
    if ( $seconds ) {
        push @time_string, "$seconds secs";
    }

    return join " ", @time_string;
}

sub _print_status {
    my ( $self, $group ) = @_;

    # completed procs
    my $completed = 0;
    if ( $self->data->{completed}->{ $group } ) {
        $completed = scalar @{ $self->data->{completed}->{ $group } };
    }

    # running procs
    my $running = 0;
    if ( $self->data->{running} ) {
        for my $pid ( keys %{ $self->data->{running} } ) {
            if ( $self->data->{running}->{ $pid }->{group} eq $group ) {
                $running++;
            }
        }
    }

    # unstarted
    my $unstarted = 0;
    if ( $self->data->{remaining}->{ $group } ) {
        $unstarted = scalar keys %{ $self->data->{remaining}->{ $group } };
    }

    # failed
    my ( $errors, $failures ) = $self->_get_failed_count( $group );

    $logger->info( "\U$group: ",
                   "completed:$completed ",
                   "running:$running ",
                   "left:$unstarted ",
                   "errors:$errors ",
                   "failures:$failures ",
               );
}

sub _start_process {
    my ( $self, $group, $source, $target ) = @_;

    $self->transfer_map->{$source}->{$target} += 1;

    my $f=fork;
    if (defined ($f) and $f==0) {

        my $target_path = $self->target_path;

        my $command;
        if ( $source eq "localhost" ) {
            $command = join( " ",
                             $self->command,
                             $self->command_args,
                             $self->source_path,
                             "$target:$target_path"
                         );
        } else {
            $command = join( " ",
                             $self->ssh,
                             $self->ssh_args,
                             $source,
                             $self->command,
                             $self->command_args,
                             $self->target_path,
                             "$target:$target_path"
                         );
        }

        print "COMMAND: $command\n";

        my $output = $self->output || "";
        if ( $output eq "stdout" ) {
            # don't modify command
        } elsif ( $output eq "log" ) {
            # redirect all child output to log
            $command = "$command >> ccp.$source.$target.log 2>&1"
        } else {
            # default is to redirectout stdout to /dev/null
            $command = "$command >/dev/null"
        }

        $logger->info( "Starting: ($group) $source => $target" );
        $logger->debug( "Starting new child: $command" );

        system( $command );

        if ($? == -1) {
            $logger->logconfess( "failed to execute: $!" );
        } elsif ($? & 127) {
            $logger->logconfess( sprintf "child died with signal %d, %s coredump",
                                 ($? & 127),  ($? & 128) ? 'with' : 'without'
                             );
        } else {
            my $exit_status = $? >> 8;
            if ( $exit_status ) {
                $logger->error( "child exit status: $exit_status" );
            }
            exit $exit_status;
        }
    } else {
        my $start = new Benchmark;
        $self->data->{running}->{ $f } = { group  => $group,
                                           source => $source,
                                           target => $target,
                                           start  => $start,
                                       };
    }
}

sub _check_for_completed_processes {
    my ( $self ) = @_;

    return unless $self->data->{running};

    # find any processes that ended and reschedule the source and
    # target servers in the available pool
    for my $pid ( keys %{ $self->data->{running} } ) {
        if ( waitpid( $pid, WNOHANG) ) {

            # check the exit status of the command.
            if ( $? ) {
                $self->_failed_process( $pid );
            } else {
                $self->_succeeded_process( $pid );
            }
        }
    }

    unless ( keys %{ $self->data->{running} } ) {
        delete $self->data->{running};
    }
}

sub _succeeded_process {
    my ( $self, $pid ) = @_;

    my $group  = $self->data->{running}->{ $pid }->{group};
    my $source = $self->data->{running}->{ $pid }->{source};
    my $target = $self->data->{running}->{ $pid }->{target};
    my $start  = $self->data->{running}->{ $pid }->{start};

    # calculate time for this transfer
    my $end = new Benchmark;
    my $diff = timediff( $end, $start );

    # keep track of transfer time totals
    $self->total_time( $self->total_time + $diff->[0] );

    my $time = $self->_human_friendly_time( $diff->[0] );
    $logger->warn( "Succeeded: ($group) $source => $target ($time)" );

    $self->_mark_available( $group, $source );
    $self->_mark_completed( $group, $target );
    $self->_mark_available( $group, $target );

    delete $self->data->{running}->{ $pid };

    $self->_print_status( $group );
}

sub _failed_process {
    my ( $self, $pid ) = @_;

    my $group  = $self->data->{running}->{ $pid }->{group};
    my $source = $self->data->{running}->{ $pid }->{source};
    my $target = $self->data->{running}->{ $pid }->{target};
    my $start  = $self->data->{running}->{ $pid }->{start};

    # calculate time for this transfer
    my $end = new Benchmark;
    my $diff = timediff( $end, $start );
    # keep track of transfer time totals
    $self->total_time( $self->total_time + $diff->[0] );

    $logger->warn( "Failed: ($group) $source => $target ($diff->[0] seconds)" );

    # there was an error during the transfer, reschedule
    # it at the end of the list
    $self->_mark_available( $group, $source );
    my $fail_count = $self->_mark_failed( $group, $target );
    if (  ! $self->_get_available_servers( $group ) ) {
        $logger->fatal( "Error: no available servers in '$group' to handle $target" );
        $self->_mark_failed( $group, $target, 1 );
    }
    elsif ( $fail_count >= $self->max_failures ) {
        $logger->fatal( "Error: giving up on ($group) $target" );
    } else {
        $self->_mark_remaining( $group, $target );
    }

    delete $self->data->{running}->{ $pid };

    $self->_print_status( $group );
}

sub _get_available_servers {
    my ( $self, $group ) = @_;
    return unless $self->data->{available};
    return unless $self->data->{available}->{ $group };

    my @available;
    for my $host ( $self->_sort_servers( $group, keys %{ $self->data->{available}->{ $group } } ) ) {
        if ( $self->children->{$host} ) {
            next if $self->children->{$host} >= $self->max_forks;
        }
        push @available, $host;
    }

    return @available;
}

sub _reserve_available_server {
    my ( $self, $group ) = @_;

    my ( $server ) = $self->_get_available_servers( $group );
    $logger->debug( "Reserving ($group) $server" );

    # only one transfer from localhost to each dc
    if ( $server eq "localhost" ) {
        delete $self->data->{available}->{$group}->{localhost};
    }

    $self->children->{ $server }++;
    return $server;
}

sub _get_remaining_servers {
    my ( $self, $group ) = @_;

    return unless $self->data->{remaining};

    return unless $self->data->{remaining}->{ $group };

    my @hosts = $self->_sort_servers( $group, keys %{ $self->data->{remaining}->{ $group } } );
    return @hosts;
}

sub _sort_servers {
    my ( $self, $group, @servers ) = @_;

    # sort servers based on original insertion order
    @servers = sort { $self->sort_order->{$group}->{$a} <=> $self->sort_order->{$group}->{$b} } @servers;

    return @servers;
}

sub _reserve_remaining_server {
    my ( $self, $group ) = @_;

    if ( $self->_get_remaining_servers( $group ) ) {
        my $server = ( $self->_sort_servers( $group, keys %{ $self->data->{remaining}->{ $group } } ) )[0];
        delete $self->data->{remaining}->{ $group }->{$server};
        $logger->debug( "Reserving ($group) $server" );

        # delete remaining data structure as groups are completed
        unless ( scalar keys %{ $self->data->{remaining}->{ $group } } ) {
            $logger->debug( "Group empty: $group" );
            delete $self->data->{remaining}->{ $group };
            unless ( scalar ( keys %{ $self->data->{remaining} } ) ) {
                $logger->debug( "No servers remaining" );
                delete $self->data->{remaining};
            }
        }
        return $server;
    }
}

sub _get_remaining_groups {
    my ( $self ) = @_;
    return unless $self->data->{remaining};
    my @keys = sort keys %{ $self->data->{remaining} };
    return unless scalar @keys;
    return @keys;
}

sub _mark_available {
    my ( $self, $group, $server ) = @_;

    # only the initial transfer to each dc comes from localhost.  iff
    # first transfer (from localhost) succeeded, then don't reschedule
    # for future syncs
    if ( $server eq "localhost" ) {

        if ( $self->data->{completed}->{ $group } ) {

            delete $self->data->{available}->{ $group }->{$server};
            return;
        }
    }

    $logger->debug( "Server available: ($group) $server" );
    $self->data->{available}->{ $group }->{$server} = 1;

    # reduce count of number of active processes on this server
    if ( $self->children->{$server} ) {
        $self->children->{$server}--;
    }
}

sub _mark_remaining {
    my ( $self, $group, $server ) = @_;

    $logger->debug( "Server remaining: ($group) $server" );
    $self->data->{remaining}->{ $group }->{$server} = 1;
}

sub _mark_completed {
    my ( $self, $group, $server ) = @_;

    $logger->debug( "Server completed: ($group) $server" );
    push @{ $self->data->{completed}->{ $group } }, $server;
}

sub _mark_failed {
    my ( $self, $group, $server, $fatal ) = @_;

    $logger->debug( "Server failed: ($group) $server" );

    if ( $fatal ) {
        $self->data->{failed}->{ $group }->{ $server } = $self->max_failures;
    }
    else {
        $self->data->{failed}->{ $group }->{ $server }++;
    }

    my $failures = $self->data->{failed}->{ $group }->{ $server };
    $logger->debug( "$failures failures for ($group) $server" );
    return $failures;
}

sub _get_failed_count {
    my ( $self, $group ) = @_;

    my $errors = 0;
    my $failures = 0;

    if ( $self->data->{failed} && $self->data->{failed}->{ $group } ) {
        for my $server ( keys %{ $self->data->{failed}->{ $group }} ) {
            $errors += $self->data->{failed}->{ $group }->{ $server };
            if ( $self->data->{failed}->{ $group }->{ $server } >= $self->max_failures ) {
                $failures++;
            }
        }
    }

    return ( $errors, $failures );
}

# tracing all the attempted transfers
sub get_transfer_map {
    my ( $self ) = @_;

    return $self->transfer_map;
}


1;

__END__

=head1 NAME

Net::CascadeCopy - Rapidly propagate (rsync/scp/...) files to many servers in multiple locations.


=head1 VERSION

version 0.2.6

=head1 SYNOPSIS

    use Net::CascadeCopy;

    # create a new CascadeCopy object
    my $ccp = Net::CascadeCopy->new( { ssh          => "/path/to/ssh",
                                       ssh_flags    => "-x -A",
                                       max_failures => 3,
                                       max_forks    => 2,
                                       output       => "log",
                                   } );

    # set the command and arguments to use to transfer file(s)
    $ccp->set_command( "rsync", "-rav --checksum --delete -e ssh" );

    # another example with scp instead
    $ccp->set_command( "/path/to/scp", "-p" );


    # set path on the local server
    $ccp->set_source_path( "/path/on/local/server" );
    # set path on all remote servers
    $ccp->set_target_path( "/path/on/remote/servers" );

    # add lists of servers in multiple datacenters
    $ccp->add_group( "datacenter1", \@dc1_servers );
    $ccp->add_group( "datacenter2", \@dc2_servers );

    # transfer all files
    $ccp->transfer();


=head1 DESCRIPTION

This module implements a scalable method of quickly propagating files
to a large number of servers in one or more locations via rsync or
scp.

A frequent solution to distributing a file or directory to a large
number of servers is to copy it from a central file server to all
other servers.  To speed this up, multiple file servers may be used,
or files may be copied in parallel until the inevitable bottleneck in
network/disk/cpu is reached.  These approaches run in O(n) time.

This module and the included script, ccp, take a much more efficient
approach that is O(log n).  Once the file(s) are been copied to a
remote server, that server will be promoted to be used as source
server for copying to remaining servers.  Thus, the rate of transfer
increases exponentially rather than linearly.

Servers can be specified in groups (e.g. datacenter) to prevent
copying across groups.  This maximizes the number of transfers done
over a local high-speed connection (LAN) while minimizing the number
of transfers over the WAN.

The number of multiple simultaneous transfers per source point is
configurable.  The total number of simultaneously forked processes is
limited via Proc::Queue, and is currently hard coded to 32.



=head1 CONSTRUCTOR

=over 8

=item new( { option => value } )

Returns a reference to a new use Net::CascadeCopy object.

Supported options:

=over 4

=item ssh => "/path/to/ssh"

Name or path of ssh script ot use to log in to each remote server to
begin a transfer to another remote server.  Default is simply "ssh" to
be invoked from $PATH.

=item ssh_flags => "-x -A"

Command line options to be passed to ssh script.  Default is to
disable X11 and enable agent forwarding.

=item max_failures => 3

The Maximum number of transfer failures to allow before giving up on a
target host.  Default is 3.

=item max_forks => 2

The maximum number of simultaneous transfers that should be running
per source server.  Default is 2.

=item output => undef

Specify options for child process output.  The default is to discard
stdout and display stderr.  "log" can be specified to redirect stdout
and stderr of each transfer to to ccp.sourcehost.targethost.log.
"stdout" option also exists which will not supress stdout, but this
option is only intended for debugging.

=back

=back

=head1 INTERFACE


=over 8

=item $self->add_group( $groupname, \@servers )

Add a group of servers.  Ideally all servers will be located in the
same datacenter.  This may be called multiple times with different
group names to create multiple groups.

=item $self->get_groups()

Get list of groups.  List is sorted by the order in which the groups
were added.

=item $self->set_command( $command, $args )

Set the command and arguments that will be used to transfer files.
For example, "rsync" and "-ravuz" could be used for rsync, or "scp"
and "-p" could be used for scp.

=item $self->set_source_path( $path )

Specify the path on the local server where the source files reside.

=item $self->set_target_path( $path )

Specify the target path on the remote servers where the files should
be copied.

=item $self->transfer( )

Transfer all files.  Will not return until all files are transferred.

=item $self->get_transfer_map( )

Returns a data structure describing the transfers that were peformed,
i.e. which hosts were used as the sources for which other hosts.

=back


=head1 BUGS AND LIMITATIONS

Note that this is still a beta release.

There is one known bug.  If an initial copy from the localhost to the
first server in one of the groups fails, it will not be retried.  the
real solution to this bug is to refactor the logic for the inital copy
from localhost.  The current logic is a hack.  Max forks should be
configured for localhost transfers, and localhost could be listed in a
group to allow it to be re-used by that group once all the intial
transfers to the first server in each group were completed.

If using rsync for the copy mechanism, it is recommended that you use
the "--delete" and "--checksum" options.  Otherwise, if the content of
the directory structure varies slightly from system to system, then
you may potentially sync different files from some servers than from
others.

Since the copies will be performed between machines, you must be able
to log into each source server to each target server (in the same
group).  Since empty passwords on ssh keys are insecure, the default
ssh arguments enable the ssh agent for authentication (the -A option).
Note that each server will need an entry in .ssh/known_hosts for each
other server.

Multiple syncs will be initialized within a few seconds on remote
hosts.  Ideally this could be configurable to wait a certain amount of
time before starting additional syncs.  This would give rsync some
time to finish computing checksums, a potential disk/cpu bottleneck,
and move into the network bottleneck phase before starting the next
transfer.

There is no timeout enforced in CascadeCopy yet.  A copy command that
hangs forever will prevent CascadeCopy from ever completing.

Please report problems to VVu@geekfarm.org.  Patches are welcome.


=head1 SUPPORT AND DOCUMENTATION

    RT, CPAN's request tracker
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-CascadeCopy

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Net-CascadeCopy

    Search CPAN
        http://search.cpan.org/dist/Net-CascadeCopy


=head1 SEE ALSO

ccp - command line script distributed with this module

http://www.geekfarm.org/wu/muse/CascadeCopy.html

=head1 CONTRIBUTORS

0.2.3 incorporates a fix from twelch for an endless loop that occurred
      when the initial transfer failed.


=head1 AUTHOR

Alex White  C<< <vvu@geekfarm.org> >>




=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Alex White C<< <vvu@geekfarm.org> >>. All rights reserved.

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

- Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

- Neither the name of the geekfarm.org nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.