package POE::Component::Gearman::Client::Connection;
use strict;
use warnings;

use Carp qw(croak);
use fields (
        'state',       # one of 3 state constants below
        'waiting',     # hashref of $handle -> [ Task+ ]
        'need_handle', # arrayref of Gearman::Task objects which
                       # have been submitted but need handles.
        'parser',      # parser object
        'hostspec',    # scalar: "host:ip"
        'deadtime',    # unixtime we're marked dead until.
        'task2handle', # hashref of stringified Task -> scalar handle
        'on_ready',    # arrayref of on_ready callbacks to run on connect success
        'on_error',    # arrayref of on_error callbacks to run on connect failure
        'poe_session_id',      # POE::Component::Client::TCP session ID
        );
use Gearman::Task;
use Gearman::Util;
use Scalar::Util qw(weaken);
use POE qw(Component::Client::TCP Filter::Stream);

use constant S_DISCONNECTED => \"disconnected";
use constant S_CONNECTING   => \"connecting";
use constant S_READY        => \"ready";

sub DEBUGGING () { 0 }

sub new {
    my __PACKAGE__ $self = shift;
    my %opts = @_;
    
    $self = fields::new($self) unless ref $self;
    
    $self->{hostspec} = delete($opts{hostspec}) or croak("hostspec required");
    croak("hostspec must be in host:port format") if ref $self->{hostspec};
    # TODO: read timeout param
    
    $self->{state}       = S_DISCONNECTED;
    $self->{waiting}     = {};
    $self->{need_handle} = [];
    $self->{deadtime}    = 0;
    $self->{on_ready}    = [];
    $self->{on_error}    = [];
    $self->{task2handle} = {};
    
    croak "Unknown parameters: " . join(", ", keys %opts) if %opts;
    return $self;
}

sub connect {
    my __PACKAGE__ $self = shift;
    
    $self->{state} = S_CONNECTING;
    
    my ($host, $port) = split /:/, $self->{hostspec};
    $port ||= 7003;
    warn "Connecting to $self->{hostspec}\n" if DEBUGGING;
    
    $self->{poe_session_id} = POE::Component::Client::TCP->new(
        RemoteAddress => $host,
        RemotePort => $port,
        Filter => POE::Filter::Stream->new(),
        Started => sub { $_[HEAP]{connection} = $self },
        Connected => \&_onConnect,
        ConnectError => \&_onConnectError,
        Disconnected => \&_onRead,
        ServerInput => \&_onRead,
        ServerError => \&_onError
    );
    
    $self->{parser} = Gearman::ResponseParser::Async->new($self);
}

sub get_session {
    my __PACKAGE__ $self = shift;
    return POE::Kernel->ID_id_to_session($self->{poe_session_id});
}

sub close {
    my __PACKAGE__ $self = shift;
    $self->{state} = S_DISCONNECTED;
    $self->_requeue_all;
    POE::Kernel->post( $self->get_session, 'shutdown' );
}

sub add_task {
    my __PACKAGE__ $self = shift;
    my Gearman::Task $task = shift;
    
    Carp::confess("add_task called when in wrong state")
        unless $self->{state} == S_READY;
    
    warn "writing task $task to $self->{hostspec}\n" if DEBUGGING;
    
    $self->write( $task->pack_submit_packet );
    push @{$self->{need_handle}}, $task;
    Scalar::Util::weaken($self->{need_handle}->[-1]);
}

# copy-and-paste from Gearman::Client::Async::Connection code
sub close_when_finished {
    my __PACKAGE__ $self = shift;
    # FIXME: implement
}

# copy-and-paste from Gearman::Client::Async::Connection code
sub hostspec {
    my __PACKAGE__ $self = shift;
    return $self->{hostspec};
}

# copy-and-paste from Gearman::Client::Async::Connection code
sub get_in_ready_state {
    my ($self, $on_ready, $on_error) = @_;
    
    if ($self->{state} == S_READY) {
        $on_ready->();
        return;
    }

    push @{$self->{on_ready}}, $on_ready if $on_ready;
    push @{$self->{on_error}}, $on_error if $on_error;

    $self->connect if $self->{state} == S_DISCONNECTED;
}

# copy-and-paste from Gearman::Client::Async::Connection code
sub mark_dead {
    my __PACKAGE__ $self = shift;
    $self->{deadtime} = time + 10;
    warn "$self->{hostspec} marked dead for a bit." if DEBUGGING;
}

# copy-and-paste from Gearman::Client::Async::Connection code
sub alive {
    my __PACKAGE__ $self = shift;
    return $self->{deadtime} <= time;
}

# copy-and-paste from Gearman::Client::Async::Connection code
sub destroy_callbacks {
    my __PACKAGE__ $self = shift;
    $self->{on_ready} = [];
    $self->{on_error} = [];
}

# copy-and-paste from Gearman::Client::Async::Connection code
sub stuff_outstanding {
    my __PACKAGE__ $self = shift;
    return
        @{$self->{need_handle}} ||
        %{$self->{waiting}};
}

# copy-and-paste from Gearman::Client::Async::Connection code
sub _requeue_all {
    my __PACKAGE__ $self = shift;

    my $need_handle = $self->{need_handle};
    my $waiting     = $self->{waiting};

    $self->{need_handle} = [];
    $self->{waiting}     = {};

    while (@$need_handle) {
        my $task = shift @$need_handle;
        warn "Task $task in need_handle queue during socket error, queueing for redispatch\n" if DEBUGGING;
        $task->fail if $task;
    }

    while (my ($shandle, $tasklist) = each( %$waiting )) {
        foreach my $task (@$tasklist) {
            warn "Task $task ($shandle) in waiting queue during socket error, queueing for redispatch\n" if DEBUGGING;
            $task->fail;
        }
    }
}

# copy-and-paste from Gearman::Client::Async::Connection code
sub process_packet {
    my __PACKAGE__ $self = shift;
    my $res = shift;

    warn "Got packet '$res->{type}' from $self->{hostspec}\n" if DEBUGGING;

    if ($res->{type} eq "job_created") {

        die "Um, got an unexpected job_created notification" unless @{ $self->{need_handle} };
        my Gearman::Task $task = shift @{ $self->{need_handle} } or
            return 1;


        my $shandle = ${ $res->{'blobref'} };
        if ($task) {
            $self->{task2handle}{"$task"} = $shandle;
            push @{ $self->{waiting}->{$shandle} ||= [] }, $task;
        }
        return 1;
    }

    if ($res->{type} eq "work_fail") {
        my $shandle = ${ $res->{'blobref'} };
        $self->_fail_jshandle($shandle);
        return 1;
    }

    if ($res->{type} eq "work_complete") {
        ${ $res->{'blobref'} } =~ s/^(.+?)\0//
            or die "Bogus work_complete from server";
        my $shandle = $1;

        my $task_list = $self->{waiting}{$shandle} or
            return;

        my Gearman::Task $task = shift @$task_list or
            return;

        $task->complete($res->{'blobref'});

        unless (@$task_list) {
            delete $self->{waiting}{$shandle};
            delete $self->{task2handle}{"$task"};
        }

        warn "Jobs: " . scalar( keys( %{$self->{waiting}} ) ) . "\n" if DEBUGGING;

        return 1;
    }

    if ($res->{type} eq "work_status") {
        my ($shandle, $nu, $de) = split(/\0/, ${ $res->{'blobref'} });

        my $task_list = $self->{waiting}{$shandle} or
            return;

        foreach my Gearman::Task $task (@$task_list) {
            $task->status($nu, $de);
        }

        return 1;
    }

    die "Unknown/unimplemented packet type: $res->{type}";

}

# copy-and-paste from Gearman::Client::Async::Connection code
sub give_up_on {
    my __PACKAGE__ $self = shift;
    my $task = shift;

    my $shandle = $self->{task2handle}{"$task"} or return;
    my $task_list = $self->{waiting}{$shandle} or return;
    @$task_list = grep { $_ != $task } @$task_list;
    unless (@$task_list) {
        delete $self->{waiting}{$shandle};
    }

}

# copy-and-paste from Gearman::Client::Async::Connection code
# note the failure of a task given by its jobserver-specific handle
sub _fail_jshandle {
    my __PACKAGE__ $self = shift;
    my $shandle = shift;

    my $task_list = $self->{waiting}->{$shandle} or
        return;

    my Gearman::Task $task = shift @$task_list or
        return;

    # cleanup
    unless (@$task_list) {
        delete $self->{task2handle}{"$task"};
        delete $self->{waiting}{$shandle};
    }

    $task->fail;
}

sub write {
    my $self = shift;
    my $input = shift;
    my $heap = $self->get_session->get_heap;
    croak("writing to non-connected socket") unless $heap->{connected};
    $heap->{server}->put($input);
}

sub _onConnect {
    my $self = $_[HEAP]{connection};
    
    if ($self->{state} == S_CONNECTING) {
        $self->{state} = S_READY;
        warn "$self->{hostspec} connected and ready.\n" if DEBUGGING;
        $_->() foreach @{$self->{on_ready}};
        $self->destroy_callbacks;
    }
}

sub _onConnectError {
    my $self = $_[HEAP]{connection};
    warn "Jobserver, $self->{hostspec} ($self) has failed to connect properly\n" if DEBUGGING;
    
    $self->mark_dead;
    $self->close;
    $_->() foreach @{$self->{on_error}};
    $self->destroy_callbacks;
}

sub _onError {
    my $self = $_[HEAP]{connection};
    my $was_connecting = ($self->{state} == S_CONNECTING);

    if ($was_connecting && $self->{t_offline}) {
        return;
    }

    $self->mark_dead;
    $self->close;
    $self->on_connect_error if $was_connecting;
}

sub _onRead {
    my $self = $_[HEAP]{connection};
    
    my $input = $_[ARG0];  # should we tell POE::Filter to buffer in chunks of 128 * 1024?
    unless (defined $input) {
        $self->mark_dead if $self->stuff_outstanding;
        $self->close;
        return;
    }

    $self->{parser}->parse_data(\$input);
}


# copy-and-paste from Gearman::Client::Async::Connection code
package Gearman::ResponseParser::Async;

use strict;
use warnings;
use Scalar::Util qw(weaken);

use Gearman::ResponseParser;
use base 'Gearman::ResponseParser';

sub new {
    my $class = shift;

    my $self = $class->SUPER::new;

    $self->{_conn} = shift;
    weaken($self->{_conn});

    return $self;
}

sub on_packet {
    my $self = shift;
    my $packet = shift;

    return unless $self->{_conn};
    $self->{_conn}->process_packet( $packet );
}

sub on_error {
    my $self = shift;

    return unless $self->{_conn};
    $self->{_conn}->mark_unsafe;  # where's this?
    $self->{_conn}->close;
}

1;
