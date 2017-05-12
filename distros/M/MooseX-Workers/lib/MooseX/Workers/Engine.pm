package MooseX::Workers::Engine;
our $AUTHORITY = 'cpan:PERIGRIN';
$MooseX::Workers::Engine::VERSION = '0.24';
use Moose;
use POE qw(Wheel::Run);
use MooseX::Workers::Job ();
use Package::Stash ();
use Try::Tiny;

has visitor => (
    is       => 'ro',
    does     => 'MooseX::Workers',
);

has max_workers => (
    isa     => 'Int',
    is      => 'rw',
    default => sub { 5 },
);

# Processes currently running
has process_list => (
    traits     => [ 'Hash' ],
    isa        => 'HashRef',
    default    => sub { {} },
    handles    => {
        set_process    => 'set',
        get_process    => 'get',
        remove_process => 'delete',
        process_list   => 'kv',
    }
);

# Processes waiting to run
has process_queue => (
    traits     => [ 'Array' ],
    isa        => 'ArrayRef',
    default    => sub { [] },
    handles    => {
        enqueue_process => 'push',
        dequeue_process => 'shift',
        process_queue   => 'elements',
    }
);

has workers => (
    traits    => [ 'Hash' ],
    isa       => 'HashRef',
    is        => 'rw',
    lazy      => 1,
    required  => 1,
    default   => sub { {} },
    handles   => {
        set_worker     => 'set',
        get_worker     => 'get',
        remove_worker  => 'delete',
        has_workers    => 'count',
        num_workers    => 'count',
        get_worker_ids => 'keys',
    },
);

has jobs => (
    traits    => [ 'Hash' ],
    isa       => 'HashRef',
    is        => 'rw',
    lazy      => 1,
    required  => 1,
    default   => sub { {} },
    handles   => {
        set_job    => 'set',
        get_job    => 'get',
        remove_job => 'delete',
        has_jobs   => 'count',
        num_jobs   => 'count',
    },
);

has session => (
    isa      => 'POE::Session',
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub {
        POE::Session->create(
            object_states => [
                $_[0] => [
                    qw(
                      _start
                      _stop
                      _worker_stdout
                      _worker_stderr
                      _worker_error
                      _worker_done
                      _worker_started
                      _sig_child
                      add_worker
                      _kill_worker
                      )
                ],
            ],
        );
    },
    clearer   => 'remove_manager',
    predicate => 'has_manager',
);

sub yield {
    my $self = shift;
    $poe_kernel->post( $self->session => @_ );
}

sub call {
    my $self = shift;
    return $poe_kernel->call( $self->session => @_ );
}

sub put_worker {
    my ( $self, $wheel_id ) = splice @_, 0, 2;
    $self->get_worker($wheel_id)->put(@_);
}

sub kill_worker {
    my ( $self, $wheel_id ) = splice @_, 0, 2;
    $self->get_worker($wheel_id)->kill(@_);
    $self->remove_worker($wheel_id);
}

sub stdout_filter {
	my $self = $_[OBJECT];
	$self->visitor->stdout_filter;
}

sub stderr_filter {
	my $self = $_[OBJECT];
	$self->visitor->stderr_filter;
}

#
# EVENTS
#

sub add_worker {
    my ( $self, $job, $args, $kernel, $heap ) = @_[ OBJECT, ARG0, ARG1, KERNEL, HEAP ];

    # if we've reached the worker threashold, set off a warning
    if ( $self->num_workers >= $self->max_workers ) {
        if ( $args->{enqueue} ) {
            $self->enqueue_process([$job, $args]);
            return;
        } else {
            $self->visitor->max_workers_reached($job);
            return;
        }
    }

    my $command;

    if (not (blessed $job && $job->isa('MooseX::Workers::Job'))) {
        $job = MooseX::Workers::Job->new(command => $job);
    }

    $self->_fixup_job_for_win32($job) if $^O eq 'MSWin32';

    $command = $job->command;
    $args    = $job->args;

    my @optional_io_filters;
    push @optional_io_filters, 'StdoutFilter', $self->stdout_filter   if $self->stdout_filter;
    push @optional_io_filters, 'StderrFilter', $self->stderr_filter   if $self->stderr_filter;
	
    $args = [$args] if defined $args && (not ref $args eq 'ARRAY');

    my $wheel = POE::Wheel::Run->new(
        Program     => $command,
        ($args ? (ProgramArgs => $args) : ()),
	@optional_io_filters,
        StdoutEvent => '_worker_stdout',
        StderrEvent => '_worker_stderr',
        ErrorEvent  => '_worker_error',
        CloseEvent  => '_worker_done',
    );
    $kernel->sig_child($wheel->PID, "_sig_child");

    $self->set_worker( $wheel->ID => $wheel );
    $self->set_process( $wheel->PID => $wheel->ID );

    $job->ID($wheel->ID);
    $job->PID($wheel->PID);
    $self->set_job( $wheel->ID => $job );
    if ($job->timeout) {
        $heap->{wheel_to_timer}{$wheel->ID} =
        $kernel->delay_set('_kill_worker', $job->timeout, $wheel->ID);
    }

    $job->name($job->PID) unless defined $job->name;

    $self->yield( '_worker_started' => $wheel->ID => $job );
    return ( $wheel->ID => $wheel->PID );
}

sub _fixup_job_for_win32 {
    my ($self, $job) = @_;

    return unless $^O eq 'MSWin32';

    my $cmd = $job->command;

    if ($job->is_coderef) {
        # do the binmoding for the user, and set up an INT handler because we kill on timeouts with INT for win32
        $job->command(sub {
            binmode STDOUT;
            binmode STDERR;
            binmode STDIN;
            local $SIG{INT} = sub { exit 0 };
            $cmd->(@_);
        });
    }
    else {
        # this makes builtins like 'echo' work with Win32::Job which ::Wheel::Run uses
        $job->command('c:\windows\system32\cmd.exe');
        $job->args(['/c', $cmd, @{ $job->args || [] }]);

        # now translate CRLF -> LF for Filter::Line
        my $visitor_class = ref $self->visitor;
        my $visitor_stash = Package::Stash->new($visitor_class);
        
        if (not $visitor_stash->has_symbol('$__MX_WORKERS_STDIO_FIXED_UP')) {
            foreach my $stream (qw/stdout stderr/) {
                my $visitor = $self->visitor;
                my $method  = "worker_${stream}";
                my $filter  = try { $visitor->${\"${stream}_filter"} };

                if (((not defined $filter)
                     || (blessed $filter && $filter->isa('POE::Filter::Line'))
                    ) && $visitor->can($method)) {

                    my $was_immutable = not $visitor_class->meta->is_mutable;

                    $visitor_class->meta->make_mutable if $was_immutable;

                    $visitor_class->meta->add_around_method_modifier($method, sub {
                        my ($orig, $self, $input) = splice @_, 0, 3;

                        $input =~ s/\015\z//;

                        $self->$orig($input, @_);
                    });

                    $visitor_class->meta->make_immutable if $was_immutable;
                }
            }

            $visitor_stash->add_symbol('$__MX_WORKERS_STDIO_FIXED_UP', 1);
        }
    }
}

sub _kill_worker {
    my ( $self, $wheel_id ) = @_[ OBJECT, ARG0 ];
    my $job = $self->get_job($wheel_id);
    $self->visitor->worker_timeout( $job )
      if $self->visitor->can('worker_timeout');
    # we send win32 coderefs an INT, see _fixup_job_for_win32
    $self->get_worker($wheel_id)->kill($^O eq 'MSWin32' && $job->is_coderef ? 'INT' : ());
}

sub _start {
    my ($self) = $_[OBJECT];
    $self->visitor->worker_manager_start()
      if $self->visitor->can('worker_manager_start');

    # Set an alias to ensure our manager session is not cleaned up.
    $_[KERNEL]->alias_set("manager");

    # Register the generic signal handler for any signals our visitor
    # class wishes to receive.
    my @visitor_methods = map { $_->name } $self->visitor->meta->get_all_methods;
    for my $sig_handler (grep { /^sig_/ } @visitor_methods){
        (my $sig) = ($sig_handler =~ /^sig_(.*)/);
        next if uc($sig) eq 'CHLD' or uc($sig) eq 'CHILD';

        $poe_kernel->state( $sig_handler, $self, '_sig_handler' );
        $poe_kernel->sig( $sig => $sig_handler );
    }
}

sub _stop {
    my ($self) = $_[OBJECT];
    $self->visitor->worker_manager_stop()
      if $self->visitor->can('worker_manager_stop');
    $self->remove_manager;
}

sub _sig_child {
    my ($self) = $_[OBJECT];
    $self->visitor->sig_child( $self->get_process($_[ARG1]), $_[ARG2] )
      if $self->visitor->can('sig_child');
    $self->remove_process( $_[ARG1] );
    $_[KERNEL]->sig_handled();
}

# A generic sig handler (for everything except SIGCHLD)
sub _sig_handler {
    my ($self, $state) = @_[OBJECT,STATE];
    $self->visitor->$state( @_[ARG0..ARG9] );
    $_[KERNEL]->sig_handled();
}

sub _worker_stdout {
    my ($self, $input, $wheel_id) = @_[ OBJECT, ARG0, ARG1 ];
    my $job = $self->get_job($wheel_id);
    $self->visitor->worker_stdout( $input, $job )
      if $self->visitor->can('worker_stdout');
}

sub _worker_stderr {
    my ($self, $input, $wheel_id) = @_[ OBJECT, ARG0, ARG1 ];
    $wheel_id =~ tr[ -~][]cd;
    my $job = $self->get_job($wheel_id);
    $self->visitor->worker_stderr( $input, $job )
      if $self->visitor->can('worker_stderr');
}

sub _worker_error {
    my ($self) = $_[OBJECT];
    return if $_[ARG0] eq "read" && $_[ARG1] == 0;

    # $operation, $errnum, $errstr, $wheel_id
    $self->visitor->worker_error( @_[ ARG0 .. ARG3 ] )
      if $self->visitor->can('worker_error');
}

sub _worker_done {
    my ($self, $wheel_id, $kernel, $heap) = @_[ OBJECT, ARG0, KERNEL, HEAP ];
    my $job = $self->get_job($wheel_id);
    $kernel->alarm_remove(delete $heap->{wheel_to_timer}{$wheel_id}) if $heap->{wheel_to_timer}{$wheel_id};

    $self->visitor->worker_done( $job )
        if $self->visitor->can('worker_done');

    $self->delete_worker( $wheel_id );

    if (my $code = $self->visitor->can('worker_finished')) {
        $self->visitor->$code($job);
    }

    # If we have free workers and processes in queue, then dequeue one of them.
    while ( $self->num_workers < $self->max_workers && 
            (my $jobref = $self->dequeue_process)
    ) {
        my ($cmd, $args) = @$jobref;
        # This has to be call(), not yield() so num_workers increments before
        # next loop above.
        $self->call(add_worker => $cmd, $args);
    }
}

sub delete_worker {
    my ( $self, $wheelID ) = @_;
    my $wheel = $self->get_worker($wheelID);
    $self->remove_worker( $wheel->ID );
}

sub _worker_started {
    my ( $self, $wheel_id, $command ) = @_[ OBJECT, ARG0, ARG1 ];
    my $job = $self->get_job($wheel_id);
    $self->visitor->worker_started( $job, $command )
        if $self->visitor->can('worker_started');
}


no Moose;
1;
__END__

=head1 NAME

MooseX::Workers::Engine - Provide the workhorse to MooseX::Workers

=head1 SYNOPSIS

    package MooseX::Workers;

    has Engine => (
        isa      => 'MooseX::Workers::Engine',
        is       => 'ro',
        lazy     => 1,
        required => 1,
        default  => sub { MooseX::Workers::Engine->new( visitor => $_[0] ) },
        handles  => [
            qw(
              max_workers
              has_workers
              num_workers
              put_worker
              kill_worker
              )
        ],
    );

=head1 DESCRIPTION

MooseX::Workers::Engine provides the main functionality 
to MooseX::Workers. It wraps a POE::Session and as many POE::Wheel::Run
objects as it needs.

=head1 ATTRIBUTES

=over 

=item visitor

Hold a reference to our main object so we can use the callbacks on it.

=item max_workers

An Integer specifying the maximum number of workers we have.

=item workers

An ArrayRef of POE::Wheel::Run objects that are our workers.

=item session

Contains the POE::Session that controls the workers.

=back

=head1 METHODS

=over

=item yield

Helper method to post events to our internal manager session.

=item call

Helper method to call events to our internal manager session. 
This is synchronous and will block incoming data from the children 
if it takes too long to return.

=item set_worker($key)

Set the worker at $key

=item get_worker($key)

Retrieve the worker at $key

=item delete_worker($key)

Remove the worker atx $key

=item has_workers

Check to see if we have *any* workers currently. This is delegated to the MooseX::Workers::Engine object.

=item num_workers

Return the current number of workers. This is delegated to the MooseX::Workers::Engine object.

=item has_manager

Check to see if we have a manager session.

=item remove_manager

Remove the manager session.

=item meta

The Metaclass for MooseX::Workers::Engine see Moose's documentation.

=back

=head1 EVENTS

=over 

=item add_worker ($command)

Create a POE::Wheel::Run object to handle $command. If $command holds a scalar, it will be executed as exec($scalar). 
Shell metacharacters will be expanded in this form. If $command holds an array reference, 
it will executed as exec(@$array). This form of exec() doesn't expand shell metacharacters. 
If $command holds a code reference, it will be called in the forked child process, and then 
the child will exit. 

See POE::Wheel::Run for more details.

=back

=head1 INTERFACE 

MooseX::Worker::Engine fires the following callbacks to its visitor object:

=over

=item worker_manager_start

Called when the managing session is started.

=item worker_manager_stop

Called when the managing session stops.

=item max_workers_reached

Called when we reach the maximum number of workers.

=item worker_stdout

Called when a child prints to STDOUT.

=item worker_stderr

Called when a child prints to STDERR.

=item worker_error

Called when there is an error condition detected with the child.

=item worker_done

Called when a worker completes $command.

=item worker_started

Called when a worker starts $command.

=item sig_child($PID, $ret)

Called when the managing session receives a SIG CHLD event.

=item sig_*

Called when the underlying POE Kernel receives a signal; this is not limited to
OS signals (ie. what you'd usually handle in Perl's %SIG) so will also accept
arbitrary POE signals (sent via POE::Kernel->signal), but does exclude
SIGCHLD/SIGCHILD, which is instead handled by sig_child above.

These interface methods are automatically inserted when MooseX::Worker::Engine
detects that the visitor object contains any methods beginning with sig_.
Signals are case-sensitive, so if you wish to handle a TERM signal, you must
define a sig_TERM() method.  Note also that this action is performed upon
MooseX::Worker::Engine startup, so any run-time modification of the visitor
object is not likely to be detected.

=back

=cut

1;


