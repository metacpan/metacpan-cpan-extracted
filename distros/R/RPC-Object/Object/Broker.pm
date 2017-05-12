package RPC::Object::Broker;
use constant DEFAULT_PORT => 8049;
use constant DEFAULT_LISTENER => 5;
use constant DEFAULT_WORKER => 5;
use constant DEFAULT_HEART_BEAT => 1000;
use constant DEFAULT_WORKER_PENDING_SIZE => 10;
use strict;
use threads;
use threads::shared;
use warnings;
use Carp;
use IO::Socket;
use Scalar::Util qw(blessed refaddr);
use Storable qw(nfreeze thaw);
use Thread::Semaphore;
use Thread::Queue;
use RPC::Object::Container;
use RPC::Object::Transport;

sub new {
    my ($class, %arg) = @_;
    my $self = &share({});
    $self->{config} = &share({});
    my $preload = delete $arg{preload};
    $self->{config}{port} = DEFAULT_PORT;
    $self->{config}{listener} = DEFAULT_LISTENER;
    $self->{config}{worker} = DEFAULT_WORKER;
    $self->{config}{heart_beat} = DEFAULT_HEART_BEAT;
    $self->{config}{worker_pending_size} = DEFAULT_WORKER_PENDING_SIZE;
    for (keys %arg) {
        $self->{config}{$_} = $arg{$_};
    }
    $self->{listener_state} = &share({});
    $self->{worker_state} = &share({});
    my $accept_lock = 0;
    $self->{accept_lock} = &share(\$accept_lock);
    $self->{job_pending} = Thread::Queue->new();
    $self->{job_done} = &share({});
    $self->{container} = &share(RPC::Object::Container->new());
    $self->{preload} = &share({});
    my @preload;
    @preload = @{$self->{config}{preload}} if ref $self->{config}{preload} eq 'ARRAY';
    for (@preload) {
        eval { $self->load_module($_) };
        $@ ? carp $@ : ($self->{preload}{$_} = 1);
    }
    bless $self, $class;
    return $self;
}

sub start {
    my $self = shift;
    my %config = %{$self->{config}};

    my $trans = RPC::Object::Transport->new({LocalPort => $config{port},
                                             Listen => SOMAXCONN,
                                             ReuseAddr => 1,
                                            },
                                            Thread::Semaphore->new(),
                                           );

    $self->add_listener($config{listener}, $trans);
    $self->add_worker($config{worker});

    while (1) {
        $self->add_listener(1, $trans) if $self->need_add_listener();
        $self->add_worker(1) if $self->need_add_worker();
        sleep 1;
    }
}

sub need_add_listener {
    my ($self) = @_;
    lock %{$self->{listener_state}};
    return $self->{listener_state}{count} < $self->{config}{listener}
      || $self->{listener_state}{busy};
}

sub need_add_worker {
    my ($self) = @_;
    lock %{$self->{worker_state}};
    return $self->{worker_state}{count} < $self->{config}{worker}
      || $self->{job_pending}->pending() > $self->{worker_state}{count} * $self->{config}{worker_pending_size};
}

sub add_listener {
    my ($self, $n, $trans) = @_;
    while ($n--) {
        warn "adding new listener\n";
        eval {
            lock %{$self->{listener_state}};
            threads->create(\&listener_handler, $self, $trans);
            ++$self->{listener_state}{count};
            $self->{listener_state}{busy} = 0;
        };
        carp "failed to add new listener: $@" if $@;
    }
}

sub add_worker {
    my ($self, $n) = @_;
    while ($n--) {
        warn "adding new worker\n";
        eval {
            lock %{$self->{worker_state}};
            threads->create(\&worker_handler, $self);
            ++$self->{worker_state}{count};
        };
        carp "failed to add new worker: $@" if $@;
    }
}

sub listener_handler {
    my ($self, $trans) = @_;
    threads->detach();
    my $heart_beat = $self->{config}{heart_beat};
    while ($heart_beat--) {
        eval {
            $trans->response(sub{
                                 my ($retry, $req) = @_;
                                 my $cmd = substr $req, 0, 1;
                                 my $arg = substr $req, 1;
                                 my $ret;
                                 if ($retry) {
                                     lock %{$self->{listener_state}};
                                     $self->{listener_state}{busy} = 1;
                                 }
                                 if ($cmd eq 'a') {
                                     $ret = $self->add_job($arg);
                                 }
                                 elsif ($cmd eq 'r') {
                                     $ret = $self->remove_job($arg);
                                 }
                                 return $ret;
                             });
        };
        carp $@ if $@;
    }
    lock %{$self->{listener_state}};
    --$self->{listener_state}{count};
}

sub worker_handler {
    my ($self) = @_;
    threads->detach();
    my $heart_beat = $self->{config}{heart_beat};
    while ($heart_beat--) {
        eval {
            my ($id, $job);
            $job = $self->{job_pending}->dequeue();
            ($id, $job) = unpack('Na*', $job);
            my $arg = thaw($job);
            my $ret = $self->handle_method_call($arg);
            {
                lock %{$self->{job_done}};
                $self->{job_done}{$id} = nfreeze($ret);
            }
        };
        carp $@ if $@;
    }
    lock %{$self->{worker_state}};
    --$self->{worker_state}{count};
}

sub handle_method_call {
    my ($self, $arg) = @_;
    my $context = shift @$arg;
    my $func = shift @$arg;
    my $ref = shift @$arg;
    my $container = $self->{container};

    if ($func eq '_rpc_object_find_instance' && $ref eq __PACKAGE__) {
        my $ret = $container->find($arg->[0]);
        return ['r', $ret];
    }

    my $obj = $container->get($ref);
    $obj = $ref unless $obj;
    my $pack = blessed($obj);
    $pack = $ref unless $pack;
    eval { $self->load_module($pack) };
    return ['e', $@] if $@;

    no strict;
    no warnings 'uninitialized';
    my @ret = ();
    if ($context) {
       @ret = eval { $obj->$func(@$arg) };
    } elsif (defined $context) {
        $ret[0] = eval { $obj->$func(@$arg) };
    } else {
        eval { $obj->$func(@$arg) };
    }
    if (blessed $ret[0]) {
        $ret[0] = $container->insert($ret[0]);
    }
    return $@ ? ['e', $@] : ['o', @ret];
}

sub load_module {
    my ($self, $pack) = @_;
    return if $pack eq __PACKAGE__;
    return if !$pack || $self->{preload}{$pack};
    eval qq(require $pack);
    croak $@ if $@;
}

sub add_job {
    my ($self, $arg) = @_;
    my $id;
    while (1) {
        $id = int(rand(time()));
        lock %{$self->{job_done}};
        last unless exists $self->{job_done}{$id};
    }
    $self->{job_pending}->enqueue(pack('Na*', $id, $arg));
    return $id
}

sub remove_job {
    my ($self, $id) = @_;
    lock %{$self->{job_done}};
    my $ret = delete $self->{job_done}{$id};
    return $ret;
}

1;
