# ===========================================================================
# POE::Component::Gearman::Client
# 
# POE-based client for Gearman servers
# 
# Author: Alessandro Ranellucci <aar@cpan.org>
# 
# See below for documentation.
# 

package POE::Component::Gearman::Client;

use strict;
use vars qw($VERSION);

use Carp qw(croak);
use fields (
            'job_servers',   # arrayref of POE::Component::Gearman::Client::Connection objects
            't_no_random',   # don't randomize job server to use:  use first alive one.
            't_offline_host', # hashref: hostname -> $bool, if host should act as offline, for testing
            );
use Gearman::Objects;
use Gearman::Task;
use Gearman::JobStatus;
use List::Util qw(first);
use POE::Component::Gearman::Client::Connection;
use POE;

$VERSION = '0.03';

sub DEBUGGING () { 0 }

sub spawn {
    my ($class, %opts) = @_;
    my $self = $class;
    $self = fields::new($class) unless ref $self;
    
    $self->{job_servers}    = [];
    $self->{t_offline_host} = {};

    my $js = delete $opts{job_servers};
    my $alias = delete $opts{alias};
    croak "Unknown parameters: " . join(", ", keys %opts) if %opts;
    
    # register session with POE
	POE::Session->create(
	    inline_states => {
	        _start => sub {
            	$_[KERNEL]->alias_set( $alias || 'Gearman' );
            	
            	# call instead of yield so that the job_servers method is 
            	# instantly available
            	$_[KERNEL]->call($_[SESSION], 'set_job_servers', $js) if $js;
			},
	    },
		object_states => [
			$self => [qw(t_set_disable_random t_set_offline_host
				        set_job_servers add_task disconnect_all)]
		]
	);
	
	return $self;
}

# for testing.
sub t_set_disable_random {
    my $self = $_[OBJECT];
    $self->{t_no_random} = shift;
}

sub t_set_offline_host {
    my ($self, $host, $val) = @_[OBJECT, ARG0, ARG1];
    $val = 1 unless defined $val;
    $self->{t_offline_host}{$host} = $val;

    my $conn = first { $_->hostspec eq $host } @{ $self->{job_servers} }
        or die "No host found with that spec to mark offline";

    $conn->t_set_offline($val);
}

# set job servers, without shutting down dups, and shutting down old ones gracefully
sub set_job_servers {
    my ($self, $js) = @_[OBJECT, ARG0];

    my %being_set; # hostspec -> 1
    %being_set = map { $_, 1 } @$js;

    my %exist;   # hostspec -> existing conn
    foreach my $econn (@{ $self->{job_servers} }) {
        my $spec = $econn->hostspec;
        if ($being_set{$spec}) {
            $exist{$spec} = $econn;
        } else {
            $econn->close_when_finished;
        }
    }

    my @newlist;
    foreach (@$js) {
        push @newlist, $exist{$_} || POE::Component::Gearman::Client::Connection->new( hostspec => $_ );
    }
    $self->{job_servers} = \@newlist;
}

# getter
sub job_servers {
    my $self = shift;
    croak "Not a setter" if @_;
    my @list = map { $_->hostspec } @{ $self->{job_servers} };
    return wantarray ? @list : \@list;
}

sub add_task {
    my $self = $_[OBJECT];
    my Gearman::Task $task = $_[ARG0] or return;

    my $try_again;
    $try_again = sub {

        my @job_servers = grep { $_->alive } @{$self->{job_servers}};
        warn "Alive servers: " . @job_servers . " out of " . @{$self->{job_servers}} . "\n" if DEBUGGING;
        unless (@job_servers) {
            $task->final_fail;
            $try_again = undef;
            return;
        }

        my $js;
        if (defined( my $hash = $task->hash )) {
            # Task is hashed, use key to fetch job server
            $js = @job_servers[$hash % @job_servers];
        }
        else {
            # Task is not hashed, random job server
            $js = @job_servers[$self->{t_no_random} ? 0 :
                               int( rand( @job_servers ))];
        }

        # TODO Fix this violation of object privacy.
        $task->{taskset} = $self;

        $js->get_in_ready_state(
                                # on_ready:
                                sub {
                                    my $timer;
                                    if (my $timeout = $task->{timeout}) {
                                        # TODO: setup timer
                                        #$timer = Danga::Socket->AddTimer($timeout, sub {
                                        #    $task->final_fail('timeout');
                                        #});
                                    }
                                    $task->set_on_post_hooks(sub {
                                        $timer->cancel if $timer;

                                        # ALSO clean up our $js (connection's) waiting stuff:
                                        $js->give_up_on($task);
                                    });
                                    $js->add_task( $task );
                                    $try_again = undef;
                                },
                                # on_error:
                                $try_again,
                                );
    };
    $try_again->();
}

sub disconnect_all {
    my $self = $_[OBJECT];
    warn "Disconnecting all server sockets\n" if DEBUGGING;
    my @job_servers = grep { $_->alive } @{$self->{job_servers}};
    warn "Alive servers: " . @job_servers . " out of " . @{$self->{job_servers}} . "\n" if DEBUGGING;
    
    # TODO: we should better use close_when_finished
    $_->close for @job_servers;
}

# POE::Component::Gearman::Client sometimes fakes itself duck-typing style as a
# Gearman::Taskset, since a task"set" makes no sense in an async
# world, where there's no need to wait on a set of things... since
# everything happens at its own pace.  so for duck-typing reasons (or,
# er, "implementing an interface", say), we need to implement a the
# "taskset client method" but in our case, that's just us.
sub client { $_[0] }

# as a Gearman::Client-like thing, we'll be asked for our prefix, which this module
# currently doesn't support, but the base Gearman libraries expect.
sub prefix { "" }


1;
__END__

=head1 NAME

POE::Component::Gearman::Client - Asynchronous client module for Gearman for POE applications

=head1 SYNOPSIS

    use POE qw(Component::Gearman::Client);

    # Instantiate a new client session.
    POE::Component::Gearman::Client->spawn(
        alias => 'my_gearman_client',
        job_servers => [ '127.0.0.1', '192.168.0.1:123' ],
    );

    # Overwrite job server list with a new one.
    POE::Kernel->post('my_gearman_client' => 'set_job_servers', ['10.0.0.1']);

    # Start a task
    $task = Gearman::Task->new(...); # with callbacks, etc
    POE::Kernel->post('my_gearman_client' => 'add_task', $task);

    # if you keep a reference to the client object you can also 
    # get a list of job servers during runtime:
    my $client = POE::Component::Gearman::Client->spawn(...);
    $arrayref = $client->job_servers;
    @array = $client->job_servers;

=head1 ABSTRACT

This module lets provides an asynchronous interface to submit jobs to Gearman
servers in a POE application.

=head1 PUBLIC METHODS

=over 4

=item C<spawn>

A program must spawn at least one POE::Component::Gearman::Client instance before 
it can submit jobs to Gearman servers. A reference to the object is returned if you
need to call methods such as C<job_servers>, otherwise you won't need to store it.

The following parameters can be passed to the C<spawn> constructor.

=over 8

=item alias

(Optional) This parameter will be used to set POE's internal session alias. This is 
useful to post events and is also very important if you instantiate multiple clients.
If left empty, the alias will be set to "Gearman".

=item job_servers

(Optional) This parameter can contain an arrayref of IP:port host specifications.

=back

=item C<job_servers>

This method returns an ARRAY or ARRAYREF (depending on the calling context) 
containing IP:port specification of the configured job servers.

=back

=head1 POE EVENTS

=over 4

=item C<set_job_servers>

Posting this event to your POE::Component::Gearman::Client client lets you set 
the current job server list (by overriding the existing one if any).

	$kernel->post('Gearman', 'set_job_servers', ['10.0.0.1']);

C<Gearman> is the alias name (see above about C<alias> parameter), and the passed
argument is an ARRAYREF containing the server definitions in IP:port syntax.

=item C<add_task>

Posting this event to your POE::Component::Gearman::Client client lets you submit a
task.

	$kernel->post('Gearman', 'add_task', $task);

C<Gearman> is the alias name (see above about C<alias> parameter), and C<$task> is a 
L<Gearman::Task> object.

B<Warning:> you can't call POE::Kernel's methods like C<yield()>, C<delay()> etc.
from within a task callback, because callbacks will be executed within 
POE::Component::Gearman::Client's session instead of yours. Thus, the only methods
you can call are C<post()> and C<call()> because they let
you specify the destination session. See example:

    # WRONG
    sub submit_task {
        my $kernel = $_[KERNEL];
        my $cb = sub {
            $kernel->delay('submit_task', 60);  # this won't be called within your session!
        };
        my $task = Gearman::Task->new('do_task', \'', { on_complete => $cb });
        POE::Kernel->post('Gearman' => 'add_task', $task);
    }
    
    # CORRECT
    sub submit_task {
        my ($kernel, $session) = @_[KERNEL, SESSION];
        my $cb = sub {
            $kernel->post($session => 'task_done');
        };
        my $task = Gearman::Task->new('do_task', \'', { on_complete => $cb });
        POE::Kernel->post('Gearman' => 'add_task', $task);
    }
    sub task_done {
        $_[KERNEL]->delay('submit_task', 60);
    }

=item C<disconnect_all>

Posting this event to your POE::Component::Gearman::Client client will disconnect
the client from all job servers, allowing your POE application to shutdown if you
want so.

	$kernel->post('Gearman', 'disconnect_all');

C<Gearman> is the alias name (see above about C<alias> parameter).

=back

=head1 SEE ALSO

=over 4

=item

L<Gearman::Task>

=item

L<Gearman::Client::Async>

=back

=head1 COPYRIGHT

Copyright Alessandro Ranellucci
Some code copyright Six Apart, Ltd.

License granted to use/distribute under the same terms as Perl itself.

=head1 WARRANTY

This is free software.  This comes with no warranty whatsoever.

=head1 AUTHORS

 Alessandro Ranellucci (aar@cpan.org)
 based on code by Brad Fitzpatrick (brad@danga.com)

=cut
