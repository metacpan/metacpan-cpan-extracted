package Queue::Q::ReliableFIFO::Redis;
use strict;
use warnings;
use Carp qw(croak cluck);

use parent 'Queue::Q::ReliableFIFO';
use Queue::Q::ReliableFIFO::Item;
use Queue::Q::ReliableFIFO::Lua;
use Redis;
use Time::HiRes qw(usleep);

use Class::XSAccessor {
    getters => [qw(
                server
                port
                db
                queue_name
                busy_expiry_time
                claim_wait_timeout
                requeue_limit
                redis_conn
                redis_options
                warn_on_requeue
                _main_queue
                _busy_queue
                _failed_queue
                _time_queue
                _temp_queue
                _log_queue
                _script_cache
                _lua
                )],
    setters => {
        set_requeue_limit => 'requeue_limit',
        set_busy_expiry_time => 'busy_expiry_time',
        set_claim_wait_timeout => 'claim_wait_timeout',
    }
};

my %QueueType = map { $_ => undef } (qw(main busy failed time temp log));

sub new {
    my ($class, %params) = @_;
    for (qw(server port queue_name)) {
        croak("Need '$_' parameter")
            if not defined $params{$_};
    }

    my %AllowedNewParams = map { $_ => undef } (qw(
        server port db queue_name busy_expiry_time
        claim_wait_timeout requeue_limit redis_conn redis_options
        warn_on_requeue));
    for (keys %params) {
        croak("Invalid parameter '$_'")
            if not exists $AllowedNewParams{$_};
    }

    my $self = bless({
        requeue_limit      => 5,
        busy_expiry_time   => 30,
        claim_wait_timeout => 1,
        db                 => 0,
        warn_on_requeue    => 0,
        %params
    } => $class);
    $self->{"_$_" . '_queue'} = $params{queue_name} . "_$_"
        for keys %QueueType;

    $self->{redis_options} ||= { reconnect => 60 };
    $self->{redis_conn} ||= Redis->new(
        # by default, auto-reconnect during 60 seconds
        %{$self->{redis_options}},
        encoding => undef, # force undef for binary data
        server => join(":", $self->server, $self->port),
    );

    $self->redis_conn->select($self->db) if $self->db;

    $self->{_lua}
        = Queue::Q::ReliableFIFO::Lua->new(redis_conn => $self->redis_conn);

    return $self;
}

sub clone {
    my ($class, $org, %params) = @_;
    my %default = map { $_ => $org->{$_} }
                  grep m/^[a-zA-Z]/,
                  keys %$org;
    return $class->new(%default, %params);
}

sub enqueue_item {
    my $self = shift;
    return if not @_;

    return $self->redis_conn->lpush(
        $self->_main_queue,
        map { Queue::Q::ReliableFIFO::Item->new(data => $_)->_serialized } @_
    );
}

use constant NONBLOCKING => 0;
use constant BLOCKING => 1;

sub claim_item {
    my ($self, $n) = @_;
    return $self->_claim_item_internal($n, BLOCKING);
}

sub claim_item_nonblocking {
    my ($self, $n) = @_;
    return $self->_claim_item_internal($n, NONBLOCKING);
}

sub _claim_item_internal {
    my ($self, $n, $doblocking) = @_;
    $n ||= 1;
    my $timeout = $self->claim_wait_timeout;
    if ($n == 1) {
        # rpoplpush gives higher throughput than the blocking version
        # (i.e. brpoplpush). So use the blocked version only when we
        # need to wait.
        my $value;
        $value = $self->redis_conn->rpoplpush($self->_main_queue, $self->_busy_queue);
        if (not defined($value) and $doblocking == BLOCKING) {
            $value = $self->redis_conn->brpoplpush($self->_main_queue, $self->_busy_queue, $timeout);
        }
        return if not $value;
        my $item;
        eval { ($item) = Queue::Q::ReliableFIFO::Item->new(_serialized => $value); };
        # FIXME ignoring exception in eval{}!
        return $item;
    }
    else {
        my $conn = $self->redis_conn;
        my $qn = $self->_main_queue;
        my $bq = $self->_busy_queue;
        my @items;
        my $serial;
        if ($n > 30) {
            # yes, there is a race, but it's an optimization only
            my ($l) = $self->redis_conn->llen($qn);
            $n = $l if $l < $n;
        }
        eval {
            $conn->rpoplpush($qn, $bq, sub {
                if (defined $_[0]) {
                    push @items,
                    Queue::Q::ReliableFIFO::Item->new(_serialized => $_[0])
                }
            }) for 1..$n;
            $conn->wait_all_responses;
            if (@items == 0 && $doblocking == BLOCKING) {
                # list seems empty, use the blocking version
                $serial = $conn->brpoplpush($qn, $bq, $timeout);
                if (defined $serial) {
                    push(@items,
                        Queue::Q::ReliableFIFO::Item->new(_serialized => $serial));
                    undef $serial;
                    $conn->rpoplpush($qn, $bq, sub {
                        if (defined $_[0]) {
                            push @items,
                                Queue::Q::ReliableFIFO::Item->new(
                                    _serialized => $_[0]);
                        }
                    }) for 1 .. ($n-1);
                    $conn->wait_all_responses;
                }
            }
            1;
        }
        or do {
            return @items;  # return with whatever we have...
        };
        return @items;
    }
}

sub mark_item_as_done {
    my $self = shift;
    if (@_ == 1) {
        return $self->redis_conn->lrem(
            $self->_busy_queue, -1, $_[0]->_serialized);
    }
    else {
        # TODO since lrem is an O(n) operation in size of busy list,
        #      there's a crossover point at which having l items to remove
        #      from said list is better done in a single O(n) loop through
        #      the list (in Lua?) rather than in l*O(n)=O(ln) operations via
        #      _lrem!
        my $conn = $self->redis_conn;
        my $count = 0;
        $conn->lrem(
            $self->_busy_queue, -1, $_->_serialized, sub { $count += $_[0] })
                for @_;
        $conn->wait_all_responses;
        return $count;
    }
}

sub unclaim  {
    my $self = shift;
    return $self->__requeue_busy(1, undef, @_);
}

sub requeue_busy_item {
    my ($self, $raw) = @_;
    return $self->__requeue_busy(0, undef, $raw);
}

sub requeue_busy {
    my $self = shift;
    return $self->__requeue_busy(0, undef, @_);
}

sub requeue_busy_error {
    my $self = shift;
    my $error= shift;
    return $self->__requeue_busy(0, $error, @_);
}

sub __requeue_busy  {
    my $self = shift;
    my $place = shift;  # 0: producer side, 1: consumer side
    my $error = shift;  # error message
    my $n = 0;
    eval {
        $n += $self->_lua->call(
            'requeue_busy',
            3,
            $self->_busy_queue,
            $self->_main_queue,
            $self->_failed_queue,
            time(),
            $_->_serialized,
            $self->requeue_limit,
            $place,
            $error || '',
        ) for @_;
        1;
    }
    or do {
        cluck("Lua call went wrong! $@");
    };
    return $n;
}

sub requeue_failed_item {
    #
    # **deprecated ***
    # This can stress Redis very hard when there are many failed items.
    # The lrem operation does a scan. If the item is not
    # at the position where the lrem-search start, the scan goes on.
    # A sleep is added in case the method is called for multiple items.
    #
    my $self = shift;
    my $n = 0;
    eval {
        for (@_) {
            $n += $self->_lua->call(
                'requeue_failed_item',
                2,
                $self->_failed_queue,
                $self->_main_queue,
                time(),
                $_->_serialized,
            );
            usleep(1e5);
        }
        1;
    }
    or do {
        cluck("Lua call went wrong! $@");
    };
    return $n;
}

sub requeue_failed_items {
    my $self = shift;
    if (@_ == 1) {
        # old API
        my $limit = shift;
        my $n = $self->_lua->call(
            'requeue_failed',
            2,
            $self->_failed_queue,
            $self->_main_queue,
            time(),
            $limit
        );
        if (!defined $n) {
            cluck("Lua call went wrong! $@");
        }
        return $n;
    }
    my %options = @_;
    # delay: how long before trying again after a (temporary) fail
    my $delay   = delete $options{Delay}        || 0;
    my $max_fc  = delete $options{MaxFailCount} || -1;
    my $chunk   = delete $options{Chunk}        || 100;
    cluck("Invalid option: $_") for (keys %options);

    my $total_requeued = 0;
    if ($self->queue_length('failed') > 0) {
        my ($todo, $requeued) = (0,0);
        do {
            ($todo, $requeued) = split(/\s+/, $self->_lua->call(
                'requeue_failed_gentle',
                3,
                $self->_failed_queue,
                $self->_main_queue,
                $self->_temp_queue,
                time(),
                $chunk,
                $delay,
                $max_fc,
            ));
            $total_requeued += $requeued;
            usleep(1e5);
        }
        while($todo > 0);
    }
    return $total_requeued;
}

sub get_and_flush_failed_items {
    # depreacted, use remove_failed_items
    my ($self, %options) = @_;
    my (undef, $failures) = $self->remove_failed_items(%options);
    return @$failures;
}

sub remove_failed_items {
    my ($self, %options) = @_;
    my $min_age = delete $options{MinAge}       || 0;
    my $min_fc  = delete $options{MinFailCount} || 0;
    my $chunk   = delete $options{Chunk}        || 100;
    my $loglimit= delete $options{LogLimit}     || 100;
    cluck("Invalid option: $_") for (keys %options);

    my $total_removed= 0;
    if ($self->queue_length('failed') > 0) {
        my ($todo, $removed) = (0,0);
        do {
            my $now = time();
            ($todo, $removed) = split(/\s+/, $self->_lua->call(
                'remove_failed_gentle',
                3,
                $self->_failed_queue,
                $self->_temp_queue,
                $self->_log_queue,
                $now,
                $chunk,
                ($now - $min_age),
                $min_fc,
                $loglimit,
            ));
            $total_removed += $removed;
            usleep(1e5);
        }
        while($todo > 0);
    }
    return (0,[])
        if $total_removed == 0;

    my $conn = $self->redis_conn;
    my @serial = 
        map { Queue::Q::ReliableFIFO::Item->new(_serialized => $_) }
        $conn->lrange($self->_log_queue, 0, -1);
    $conn->del($self->_log_queue);
    return ($total_removed, \@serial);
}

sub flush_queue {
    my $self = shift;
    my $conn = $self->redis_conn;
    $conn->multi;
    $conn->del($_)
        for ($self->_main_queue, $self->_busy_queue,
             $self->_failed_queue, $self->_time_queue);
    $conn->exec;
    return;
}

sub queue_length {
    my ($self, $type) = @_;
    __validate_type(\$type);
    my $qn = $self->queue_name . "_$type";
    my ($len) = $self->redis_conn->llen($qn);
    return $len;
}

sub peek_item {
    my ($self, $type) = @_;
    # this function returns the value of oldest item in the queue
    __validate_type(\$type);
    my $qn = $self->queue_name . "_$type";

    # take oldest item
    my ($serial) = $self->redis_conn->lrange($qn,-1,-1);
    return undef if ! $serial;    # empty queue

    my $item = Queue::Q::ReliableFIFO::Item->new(_serialized => $serial);
    return $item->data();
}

sub age {
    my ($self, $type) = @_;
    # this function returns age of oldest item in the queue (in seconds)
    __validate_type(\$type);
    my $qn = $self->queue_name . "_$type";

    # take oldest item
    my ($serial) = $self->redis_conn->lrange($qn,-1,-1);
    return 0 if ! $serial;    # empty queue, so age 0

    my $item = Queue::Q::ReliableFIFO::Item->new(_serialized => $serial);
    return time() - $item->time_queued;
}

sub raw_items_main {
    my $self = shift;
    return $self->_raw_items('main', @_);
}

sub raw_items_busy {
    my $self = shift;
    return $self->_raw_items('busy', @_);
}

sub raw_items_failed {
    my $self = shift;
    return $self->_raw_items('failed', @_);
}

sub _raw_items {
    my ($self, $type, $n) = @_;
    #__validate_type(\$type); # truism, cf. the ten lines above this
    $n ||= 0;
    my $qn = $self->queue_name . "_$type";
    return
        map { Queue::Q::ReliableFIFO::Item->new(_serialized => $_); }
        $self->redis_conn->lrange($qn, -$n, -1);
}

sub __validate_type {
    my $type = shift;
    $$type ||= 'main';
    croak("Unknown queue type $$type")
        if not exists $QueueType{$$type};
}

sub memory_usage_perc {
    my $self = shift;
    my $conn = $self->redis_conn;
    my $info = $conn->info('memory');
    my $mem_used = $info->{used_memory};
    my (undef, $mem_avail) = $conn->config('get', 'maxmemory');
    return 100 if $mem_avail == 0; # if nothing is available, it's full!
    return $mem_used * 100 / $mem_avail;
}


SCOPE: {
    my %ValidErrorActions = map { $_ => 1 } (qw(drop requeue));
    my %ValidOptions       = map { $_ => 1 } (qw(
        Chunk DieOnError ReturnOnDie MaxItems MaxSeconds ProcessAll Pause ReturnWhenEmpty NoSigHandlers WarnOnError
    ));

    sub consume {
        my ($self, $callback, $error_action, $options) = @_;
        # validation of input
        $error_action ||= 'requeue';
        croak("Unknown error action")
            if not exists $ValidErrorActions{$error_action};
        my %error_subs = (
            'drop'    => sub { my ($self, $item) = @_;
                                $self->mark_item_as_done($item); },
            'requeue' => sub { my ($self, $item, $error) = @_;
                               $self->requeue_busy_error($error, $item); },
        );
        my $onerror = $error_subs{$error_action}
            || croak("no handler for $error_action");

        $options = $options ? {%$options} : {};
        my $chunk       = delete $options->{Chunk} || 1;
        croak("Chunk should be a number > 0") if (! $chunk > 0);
        cluck("DieOnError is deprecated, use ReturnOnDie instead")
            if exists $options->{DieOnError};
        my $return      = delete $options->{ReturnOnDie} || delete $options->{DieOnError} || 0;
        my $maxitems    = delete $options->{MaxItems} || -1;
        my $maxseconds  = delete $options->{MaxSeconds} || 0;
        my $pause       = delete $options->{Pause} || 0;
        my $process_all = delete $options->{ProcessAll} || 0;
        my $return_when_empty= delete $options->{ReturnWhenEmpty} || 0;
        my $nohandlers  = delete $options->{NoSigHandlers} || 0;
        my $warn_on_error = delete $options->{WarnOnError} || 0;
        croak("Option ProcessAll without Chunk does not make sense")
            if $process_all && $chunk <= 1;
        croak("Option Pause without Chunk does not make sense")
            if $pause && $chunk <= 1;

        for (keys %$options) {
            croak("Unknown option $_") if not exists $ValidOptions{$_};
        }
        my $stop_time = $maxseconds > 0 ? time() + $maxseconds : 0;

        # Now we can start...
        my $stop = 0;
        my $MAX_RECONNECT = 60;
        my $sigint  = ref $SIG{INT}  eq 'CODE' ? $SIG{INT}  : undef;
        my $sigterm = ref $SIG{TERM} eq 'CODE' ? $SIG{TERM} : undef;
        local $SIG{INT} = $nohandlers ? $sigint : sub {
            print "stopping\n";
            $stop = 1;
            &$sigint if $sigint;
        };
        local $SIG{TERM} = $nohandlers ? $sigterm : sub {
            print "stopping\n";
            $stop = 1;
            &$sigterm if $sigterm;
        };

        if ($chunk == 1) {
            my $die_afterwards = 0;
            my $claimed_count = 0;
            my $done_count = 0;
            while(!$stop) {
                my $item = eval { $self->claim_item(); };
                if (!$item) {
                    last if $return_when_empty
                                || ($stop_time > 0 && time() >= $stop_time);
                    next;    # nothing claimed this time, try again
                }
                $claimed_count++;
                my $ok = eval { $callback->($item->data); 1; };
                if (!$ok) {
                    my $error = _clean_error($@);
                    warn "callback had an error: $error"
                      if $warn_on_error and $error;
                    for (1 .. $MAX_RECONNECT) {    # retry if connection is lost
                        eval { $onerror->($self, $item, $error); 1; }
                        or do {
                            last if $stop;
                            sleep 1;
                            next;
                        };
                        last;
                    }
                    if ($return) {
                        $stop = 1;
                        cluck("Stopping because of ReturnOnDie\n");
                    }
                } else {
                    for (1 .. $MAX_RECONNECT) {    # retry if connection is lost
                        eval {
                            $done_count += $self->mark_item_as_done($item);
                            1;
                        } or do {
                            last if $stop;
                            sleep 1;
                            next;
                        };
                        last;
                    }
                }
                $stop = 1 if ($maxitems > 0 && --$maxitems == 0)
                                || ($stop_time > 0 && time() >= $stop_time);
            }
            my $still_busy = $claimed_count - $done_count;
            warn "not all items removed from busy queue ($still_busy)\n"
                if $self->warn_on_requeue && $still_busy;
        }
        else {
            my $die_afterwards = 0;
            my $t0 = Time::HiRes::time();
            while(!$stop) {
                my @items;

                # give queue some time to grow
                if ($pause) {
                    my $pt = ($pause - (Time::HiRes::time()-$t0))*1e6;
                    Time::HiRes::usleep($pt) if $pt > 0;
                }

                eval { @items = $self->claim_item($chunk); 1; }
                or do {
                    print "error with claim\n";
                };
                $t0 = Time::HiRes::time() if $pause; # only relevant for pause
                if (@items == 0) {
                    last if $return_when_empty
                                || ($stop_time > 0 && time() >= $stop_time);
                    next;    # nothing claimed this time, try again
                }
                my @done;
                if ($process_all) {
                    # process all items in one call (option ProcessAll)
                    my $ok = eval { $callback->(map { $_->data } @items); 1; };
                    if ($ok) {
                        @done = splice @items;
                    }
                    else {
                        # we need to call onerror for all items now
                        @done = (); # consider all items failed
                        my $error = _clean_error($@);
                        warn "callback had an error: $error"
                          if $warn_on_error and $error;
                        while (my $item = shift @items) {
                            for (1 .. $MAX_RECONNECT) {
                                eval { $onerror->($self, $item, $error); 1; }
                                or do {
                                    last if $stop; # items might stay in busy mode
                                    sleep 1;
                                    next;
                                };
                                last;
                            }
                            if ($return) {
                                cluck("Stopping because of ReturnOnDie\n");
                                $stop = 1;
                            }
                            last if $stop;
                        }
                    }
                }
                else {
                    # normal case: process items one by one
                    while (my $item = shift @items) {
                        my $ok = eval { $callback->($item->data); 1; };
                        if ($ok) {
                            push @done, $item;
                        }
                        else {
                            my $error = _clean_error($@);
                            warn "callback had an error: $error"
                              if $warn_on_error and $error;
                            # retry if connection is lost
                            for (1 .. $MAX_RECONNECT) {
                                eval { $onerror->($self, $item, $error); 1; }
                                or do {
                                    last if $stop;
                                    sleep 1;
                                    next;
                                };
                                last;
                            }
                            if ($return) {
                                cluck("Stopping because of ReturnOnDie\n");
                                $stop = 1;
                            }
                        }
                        last if $stop;
                    }
                }
                my $count = 0;
                for (1 .. $MAX_RECONNECT) {
                    eval { $count += $self->mark_item_as_done(@done); 1; }
                    or do {
                        last if $stop;
                        sleep 1;
                        next;
                    };
                    last;
                }
                warn "not all items removed from busy queue ($count)\n"
                    if $self->warn_on_requeue && $count != @done;

                # put back the claimed but not touched items
                if (@items > 0) {
                    my $n = @items;
                    print "unclaiming $n items\n";
                    for (1 .. $MAX_RECONNECT) {
                        eval { $self->unclaim($_) for @items; 1; }
                        or do {
                            last if $stop;
                            sleep 1;
                            next;
                        };
                        last;
                    }
                }
                $stop = 1 if ($maxitems > 0 && ($maxitems -= @done) <= 0)
                                || ($stop_time > 0 && time() >= $stop_time);
            }
        }
    } # end 'sub consume'
} # end SCOPE

sub _clean_error {
    $_[0] =~ s/, <GEN0> line [0-9]+//;
    chomp $_[0];
    return $_[0];
}

# methods to be used for cleanup script and Nagios checks
# the methods read or remove items from the busy queue
sub handle_expired_items {
    my ($self, $timeout, $action) = @_;
    $timeout ||= 10;
    die "timeout should be a number> 0" if not int($timeout);
    die "unknown action"
        if not $action or $action !~ /^(?:requeue|drop)$/;
    my $conn = $self->redis_conn;
    my @serial = $conn->lrange($self->_busy_queue, 0, -1);
    my $time = time;
    my %timetable =
        map { reverse split /-/,$_,2 }
        $conn->lrange($self->_time_queue, 0, -1);
    my @match = grep { exists $timetable{$_} } @serial;
    my %match = map { $_ => undef } @match;
    my @timedout = grep { $time - $timetable{$_} >= $timeout } @match;
    my @log;

    if ($action eq 'requeue') {
        for my $serial (@timedout) {
            my $item = Queue::Q::ReliableFIFO::Item->new(
                _serialized => $serial
            );
            my $n = $self->requeue_busy_item($item);
            push @log, $item
                if $n;
        }
    }
    elsif ($action eq 'drop') {
        for my $serial (@timedout) {
            my $n = $conn->lrem( $self->_busy_queue, -1, $serial);
            push @log, Queue::Q::ReliableFIFO::Item->new(_serialized => $serial)
                if $n;
        }
    }

    # We create a new timetable. We take the original timetable and
    # exclude:
    # 1. the busy items which timed out and we just handled
    # 2. timetable items which have no corresponding busy items anymore
    my %timedout = map { $_ => undef } @timedout;
    my %busy = map { $_ => undef } @serial;
    my %newtimetable =
        map  { $_ => $timetable{$_} }
        grep { exists $busy{$_} }        # exclude (ad 2.)
        grep { ! exists $timedout{$_} }  # exclude (ad 1.)
        keys %timetable;                 # original timetable
    # put in the items of latest scan we did not see before
    $newtimetable{$_} = $time
        for (grep { !exists $newtimetable{$_} } @serial);
    $conn->multi;
    $conn->del($self->_time_queue);
    $conn->lpush($self->_time_queue, join('-',$newtimetable{$_},$_))
        for (keys %newtimetable);
    $conn->exec;
    #FIXME the log info should also show what is done with the items
    # (e.g. dropped after requeue limit).
    return @log;
}
1;

__END__

=head1 NAME

Queue::Q::ReliableFIFO::Redis - In-memory Redis implementation of the ReliableFIFO queue

=head1 SYNOPSIS

  use Queue::Q::ReliableFIFO::Redis;
  my $q = Queue::Q::ReliableFIFO::Redis->new(
      server     => 'myredisserver',
      port       => 6379,
      queue_name => 'my_work_queue',
  );

  # reuse same connection and create a new object for another queue
  # Note: don't use the same connection in different threads (of course)!
  my $q2 = Queue::Q::ReliableFIFO::Redis->clone(
      $q, queue_name => 'other_queue'
  );

  # Producer:
  $q->enqueue_item("foo");
  # You can pass any JSON-serializable data structure
  $q->enqueue_item({ bar => "baz" });
  $q->enqueue_item({ id=> 12},{id =>34});   # two items
  # get rid of everything in the queue:
  $q->flush_queue();    # get a clean state, removes queue

  # Consumer:
  $q->consume(\&callback);
  $q->consume(
    sub { my $data = shift; print 'Received: ', Dumper($data); });

  # Cleanup script
  my $action = 'requeue';
  while (1) {
      my @handled_items = $q->handle_expired_items($timeout, $action);
      for my $item (@handled_items) {
          printf "%s: item %s, in queue since %s, requeued % times\n",
              $action, Dumper($item->data),
              scalar localtime $item->time,
              $item->requeue_count;
      }
      sleep(60);
  }
  # retry items that failed before:
  $q->requeue_failed_items();
  $q->requeue_failed_items(
    MaxFailCount => 3,  # only requeue if there were not more than 3 failures
    Delay => 3600,      # only requeue if the previous fail is at least 1 hour ago
  );

  # Nagios?
  $q->queue_length();
  $q->queue_length('failed');

  # Depricated (consumer)
  my $item = $q->claim_item;
  my @items= $q->claim_item(100);
  my $foo  = $item->data;
  $q->mark_item_as_done($item);     # single item
  $q->mark_item_as_done(@items);    # multiple items

=head1 DESCRIPTION

Implements interface defined in L<Queue::Q::ReliableFIFO>:
an implementation based on Redis.

The data structures passed to C<enqueue_item> are serialized
using JSON (cf. L<JSON::XS>), so
any data structures supported by that can be enqueued.
We use JSON because that is supported at the Lua side as well (the cjson
library).

The implementation is kept very lightweight at the Redis level
in order to get a hight throughput. With this implementation it is
easy to get a throughput of 10,000 items per second on a single core.

At the Redis side this is basically done at the following events:

=over

=item putting an item: lput

=item getting an item: (b)rpoplpush

=item mark as done: lrem

=item mark an item as failed: lrem + lpush

=item requeue an item: lrem + lpush (or lrem + rpush)

=back

Note that only exceptions need multiple commands.

To detect hanging items, a cronjob is needed, looking at how long items
stay in the busy status.

The queues are implemented as list data structures in Redis. The lists
ave as name the queue name plus an extension. The extension is:

 _main for the working queue
 _busy for the list with items that are claimed but not finished
 _failed for the items that failed

There can also be a list with extension "_time" if a cronjob is monitoring
how long items are in the busy list (see method handle_expired_items()).

=head1 METHODS

B<Important note>:
At the Redis level a lost connection will always throw an
exception, even if auto-reconnect is switched on.
As consequence, the methods that do Redis commands, like
C<enqueue_item()>, C<claim_item()> and
C<mark_item_as_done()>, will throw an exception when the connection to the
Redis server is lost. The C<consume()> method handles these exceptions.
For other methods you need to catch and handle the exception.

All methods of L<Queue::Q::ReliableFIFO>. Other methods are:

=head2 new

Constructor. Takes named parameters. Required parameters are

=over

=item the B<server> hostname or address

=item the Redis B<port>, and

=item the name of the Redis key to use as the B<queue_name>.

=back

Optional parameters are

=over

=item a Redis B<db> number to use. C<Default value is 0>.

=item B<redis_options> for connection options

=item B<redis_connection> for reusing an existing Redis connection

=item B<requeue_limit> to specify how often an item is allowed to
enter the queue again before ending up in the failed queue.
C<Default value is 5>.

=item B<claim_wait_timeout> (in seconds) to specify how long the
C<claim_item()> method is allowed to wait before it returns.
This applies to the situation with an empty queue.
A value of "0" means "wait forever".
C<Default value is 1>.

=item B<busy_expiry_time> to specify the threshold (in seconds)
after which an item is supposed to get stuck. After this time a follow
up strategy should be applied. (Normally done by the C<handle_expired_items()>
method, typically done by a cronjob).
C<Default value is 30>.

=item C<warn_on_requeue> to emit warning messages when we fail to process
all items we tried to claim.

=back

=head2 clone($q, %options)

The clone method can be use to use the default (and existing connection)
to create another queue object.

=head2 enqueue_item(@items)

Special for the Redis imlementation is that the return value is
the length of the queue after the items are added.

=head2 claim_item($count)

Attempts to claim C<$count> items from the main queue and
atomically transfers them to the busy queue. Returns the items as
C<Queue::Q::ReliableFIFO::Item> objects (as a list for C<$count E<gt> 1>).
C<$count> defaults to 1. Will block for C<claim_wait_timeout> seconds.

=head2 claim_item_nonblocking($count)

Same as C<claim_item>, but non-blocking.

=head2 queue_length($subqueue_name)

This method can be used to obtain a simple count of the specified subqueue
(i.e. main/busy/failed). Useful for monitoring checks, and also as a
backpressure mechanism for throttling.

=head2 consume(\&callback, $action, %options)

This method is called by the consumer to consume the items of a
queue. For each item in the queue, the callback function will be
called. The function will receive that data of the queued item
as parameter. While the consume method deals with the queue related
actions, like claiming, "marking as done" etc, the callback function
only deals with processing the item.

The C<$action> parameter is applied when the callback function returns
a "die". Allowed values are:

By default, the consume method will keep on reading the queue forever or
until the process receives a SIGINT or SIGTERM signal. You can make the
consume method return earlier by using one of the options C<MaxItems>,
C<MaxSeconds> or C<ReturnWhenEmpty>. If you still want to have a "near real time"
behavior you need to make sure there are always consumers running,
which can be achieved using cron and C<IPC::ConcurrencyLimit::WithStandby>.

This method also uses B<claim_wait_timeout>.

=over

=item * B<requeue>. (C<Default>). I.e. do it again, the item will be put at the
tail of the queue. The requeue_limit property is the queue indicates
the limit to how many times an item can be requeued.
The default is 5 times. You can change that by setting by calling
the C<set_requeue_limit()> method or by passing the property to the
constructor. When the requeue limit is reached, the item will go
to the failed queue.

Note: by setting the queue_limit to "0" you can force the item to
go to the "failed" status right away (without being requeued).

=item * B<drop>. Forget about it.

=back


=head3 Options

=over

=item * B<Chunk>.  The Chunk option is used to set a chunk size
for number of items to claim and to mark as done in one go.
This helps to fight latency.

=item * B<DieOnError>.
DEPRECATED. See C<ReturnOnDie>.

=item * B<ReturnOnDie>
If this option has a true value, the consumer will stop if the
callback function does a C<die> call. Default is "false".

=item * B<WarnOnError>
If this option has a true value, the consumer will warn if the
callback function dies. Default is "false".

=item * B<MaxItems>
This can be used to limit the consume method to process only a limited amount
of items, which can be useful in cases of memory leaks. When you use
this option, you will probably need to look into restarting
strategies with cron. Of course this comes with delays in handling the
items.

=item * B<MaxSeconds>
This can be used to limit the consume method to process items for a limited
amount of time.

=item * B<ReturnWhenEmpty>
Use this when you want to let consume() return when the queue is empty.
Note that comsume will wait for
claim_wait_timeout seconds until it can come to the conclusion
that the queue is empty.

=item * B<Pause>.
This can be used to give the queue some time to grow, so that more
items at the time can be claimed. The value of Pause is in seconds and
can be a fraction of a second (e.g. 0.5).
Default value is 0. This option only makes sense if
larger Chunks are read from the queue (so together with option "Chunk").

=item * B<ProcessAll>.
This can be used to process all claimed items by one invocation of
the callback function. The value of ProcessAll should be a true or false
value. Default value is "0". Note that this changes the @_ content of
callback: normally the callback function is called with one item
data structure, while in this case @_ will contain an array with item
data structures.
This  option only makes sense if larger Chunks are read from the queue
(so together with option "Chunk").

=item * B<NoSigHandlers>
When this option is used, no signal handlers for SIGINT and SIGTERM will be
installed. By default, consume() installs handlers that will make the queue
consuming stop on reception of those signals.

=back

Examples:

    $q->consume(\&callback,);
    $q->consume(\&callback, 'requeue'); # same, because 'requeue' is default

    # takes 50 items a time. Faster because less latency
    $q->consume(\&callback, 'requeue', { Chunk => 50 });

=head2 @item_obj = $q->handle_expired_items($timeout, $action);

This method can be used by a cleanup job to ensure that items don't
stick forever in the B<busy> status. When an item has been in this status
for $timeout seconds, the action specified by the $action will be done.
The $action parameter is the same as with the consume() method.

The method returns item objects of type L<Queue::Q::ReliableFIFO::Item>
which has the item data as well as the time when it was queued at the first
time, how often it was requeued.

To set/change the limit of how often an item can be requeued, use the
requeue_limit parameter in the new() constructor or use the method
set_requeue_limit.

Once an item is moved to the failed queue, the counter is reset. The
item can be put back into the main queue by using the requeue_failed_items()
method (or via the CLI). Then it will be retried again up to
requeue_limit times.

=head2 my $count = $q->unclaim(@items)

This method puts the items that are passed, back to the queue
at the consumer side,
so that they can be picked up a.s.a.p. This method is e.g. be used
when a chunk of items are claimed but the consumer aborts before all
items are processed.

=head2 my $count = $q->requeue_busy(@items)

This puts items that are claimed back to the queue so that other consumers
can pick this up. In this case the items are put at the back of the queue,
so depending the queue length it can take some time before it is
available for consumers.

=head2 my $count = $q->requeue_failed_items(%options);

This method will move items from the failed queue to the
working queue. The %options can be used to restrict what should be requeued.
The number of items actually moved will be the return value.

=over

=item * B<MaxFailCount>
Takes only the items with not more than MaxFailCount failures. Value "-1"
means "regardless how many times it fails". Default: -1

=item * B<Delay>
Takes only the items that failed at least Delay seconds ago. Default: 0.

=item * B<Chunk>
Performance related: amount of items to handle in one lua call.
Higher values will result in higher throughput, but more stress on Redis.
Default: 100.

An item will only be requeued if B<both> criteria (MaxFailCount and Delay
are met.

=back

NOTE:
Previous versions supported a single "limit" parameter to requeue only
a few items.  This API is still supported but may go away in the future.

=head2 my $count = $q->requeue_failed_item(@raw_items)

** deprecated **
This method can stress Redis really hard when the queue is very long.
If you want to requeue items, use requeue_failed_items() instead.

This method will move the specified item(s) to the main queue so that it
will be processed again. It will return 0 or 1 (i.e. the number of items
moved).

=head2 my $count = $q->requeue_busy_item($raw_item)

Same as requeue_busy, it only accepts one value instead of a list.

=head2 my @raw_failed_items = $q->get_and_flush_failed_items(%options);

** deprecated ** Use remove_failed_items() instead.

This method is now using remove_failed_items() under the hood.
The default values for Chunk and Loglimit are used.
Because ot the Loglimit, there is a maximum of the amount it failed items
this method will return. So if it returns 100, it is possible that 
the actual amount is higher.

Typical use could be a cronjob that warns about failed items
(e.g. via email) and cleans them up.

Supported options:

=over 2

=item * B<MaxAge>
Only the failed items that are older then $seconds will be retrieved and
removed.

=item * B<MinFailCount>
Takes only the items with have at least MaxFailCount failures. Default: 0

=back

If both options are used, only one of the two needs to be true to retrieve and remove an item.

=head2 my ($n_removed, \@raw_failed_items) = $q->remove_failed_items(%options);

This method will remove the items that are considered as failing
permanently, according the the criteria passed via the options.

Returns array ($n_removed, \@raw_items) where $n_removed indicates how many 
items are removed from the failed queue. The @raw_items will contain objects
of the type Queue::Q::Reliable::Item which failed permanently. The number of
objects is the lowest number of $n_removed and of the LogLimit option
(see below).

The way this method works is moving failed items to a temporary list in Redis
and process that sequentially with a server side lua script. This lua
script is called repeatedly and will handle up to "Chunk" number of items
in each call. Depending the criteria items will be put back in the failed
queue or not. When the temporary queue is empty, the lua script is not longer
called. The items that are not put back in the queue are put in a "log" list.

Usually you will want to know the details of the failed items. But if there
many (e.g. millions) it is not likely you will read the details.
That is the reason there is a LogLimit option. 

Typical use could be a cronjob that warns about failed items
(e.g. via email) and cleans them up.

Supported options:

=over 2

=item * B<MinAge>
Takes only the items older than MinAge seconds. Default: 0.

=item * B<MinFailCount>
Takes only the items with have at least MaxFailCount failures. Default: 0

=item * B<Chunk>
Performance related: amount of items to handle in one lua call.
Higher values will result in higher throughput, but more stress on Redis.
Default: 100.

=item * B<LogLimit>
The maximum number of raw items (with messages) you want to get back after one call
of this function. Default: 100

=back

If one or two of the MinAge and MinFailCount related criteria are true,
the item is considered as permanently failed.

=head2 my $age = $q->age([$type]);

This methods returns maximum wait time of items in the queue. This
method will simply lookup the item in the head of the queue (i.e.
at the consumer side of the queue) and will return the age of that item.
So this is a relatively cheap method.

=head2 my @raw_items = $q->raw_items_busy( [$max_number] );

Returns objects of type Queue::Q::ReliableFIFO::Item from the busy list.
You can limit the number of items by passing the limit to the method.

If you require a simple count, and not the actual queue items themselves,
consider using the method C<queue_length>. This avoids the overhead of
deserialising each queue item by calling Redis's C<LLEN> command instead.

=head2 my @raw_items = $q->raw_items_failed( [$max_number] );

Similar to raw_items_busy() but for failed items.

If you require a simple count, and not the actual queue items themselves,
consider using the method C<queue_length>. This avoids the overhead of
deserialising each queue item by calling Redis's C<LLEN> command instead.

=head2 my @raw_items = $q->raw_items_main( [$max_number] );

Similar to raw_items_busy() but for items in the working queue. Note that
the main queue can be large, so a limit is strongly recommended here.

If you require a simple count, and not the actual queue items themselves,
consider using the method C<queue_length>. This avoids the overhead of
deserialising each queue item by calling Redis's C<LLEN> command instead.

=head2 my $memory_usage = $q->memory_usage_perc();

Returns the memory usage percentage of the Redis instance where the queue
is located.

=head2 peek_item([$type])

Returns value of oldest item in the queue (about to be consumed), without
removing the item from the queue.

=head1 AUTHOR

Herald van der Breggen, E<lt>herald.vanderbreggen@booking.comE<gt>

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, 2013, 2014 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
