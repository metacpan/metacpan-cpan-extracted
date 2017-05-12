package Queue::Q::ClaimFIFO::Redis;
use strict;
use warnings;
use Carp qw(croak);

use Scalar::Util qw(blessed);
use Redis;
use Redis::ScriptCache;

use Queue::Q::ClaimFIFO;
use parent 'Queue::Q::ClaimFIFO';

use Class::XSAccessor {
    getters => [qw(server port queue_name db _redis_conn _script_cache)],
};

use constant CLAIMED_SUFFIX => '_claimed';
use constant STORAGE_SUFFIX => '_storage';

# in: queue_name, itemkey, value
# out: nothing
our $EnqueueScript = qq#
    redis.call('lpush', KEYS[1], ARGV[1])
    redis.call('hset', KEYS[1] .. "${\STORAGE_SUFFIX()}", ARGV[1], ARGV[2])
#;

# in: queue_name, time
# out: itemkey, value
our $ClaimScript = qq#
    local itemkey = redis.call('rpop', KEYS[1])
    if not itemkey then
        return {nil, nil}
    end
    local data = redis.call('hget', KEYS[1] .. "${\STORAGE_SUFFIX()}", itemkey)
    redis.call('zadd', KEYS[1] .. "${\CLAIMED_SUFFIX()}", ARGV[1], itemkey)
    return {itemkey, data}
#;

# in: queue_name, itemkey
# out: nothing
our $FinishScript = qq#
    redis.call('hdel', KEYS[1] .. "${\STORAGE_SUFFIX()}", ARGV[1])
    redis.call('zrem', KEYS[1] .. "${\CLAIMED_SUFFIX()}", ARGV[1])
#;

sub new {
    my ($class, %params) = @_;
    for (qw(server port queue_name)) {
        croak("Need '$_' parameter")
            if not defined $params{$_};
    }

    my $self = bless({
        (map {$_ => $params{$_}} qw(server port queue_name) ),
        db => $params{db} || 0,
        _redis_conn => undef,
        _script_ok => 0, # not yet known if lua script available
    } => $class);

    $self->{_redis_conn} = Redis->new(
        %{$params{redis_options} || {}},
        encoding => undef, # force undef for binary data
        server => join(":", $self->server, $self->port),
    );
    $self->{_script_cache}
        = Redis::ScriptCache->new(redis_conn => $self->_redis_conn);
    $self->{_script_cache}->register_script(
        'enqueue_script',
        $EnqueueScript,
    );
    $self->{_script_cache}->register_script(
        'claim_script',
        $ClaimScript,
    );
    $self->{_script_cache}->register_script(
        'finish_script',
        $FinishScript,
    );

    $self->_redis_conn->select($self->db) if $self->db;

    return $self;
}


sub enqueue_item {
    my $self = shift;
    croak("Need exactly one item to enqeue")
        if not @_ == 1;

    my $item = shift;
    if (blessed($item) and $item->isa("Queue::Q::ClaimFIFO::Item")) {
        croak("Don't pass a Queue::Q::ClaimFIFO::Item object to enqueue_item: "
              . "Your data structure will be wrapped in one");
    }
    $item = Queue::Q::ClaimFIFO::Item->new(item_data => $item);

    $self->_script_cache->run_script(
        'enqueue_script',
        [1, $self->queue_name, $item->_key, $item->_serialized_data],
    );

    return $item;
}

sub enqueue_items {
    my $self = shift;
    return if not @_;

    my @items;
    foreach my $item (@_) {
        if (blessed($item) and $item->isa("Queue::Q::ClaimFIFO::Item")) {
            croak("Don't pass a Queue::Q::ClaimFIFO::Item object to enqueue_items: "
                  . "Your data structure will be wrapped in one");
        }
        push @items, Queue::Q::ClaimFIFO::Item->new(item_data => $item);
    }

    # FIXME, move loop onto the server or pipeline if possible!
    my $qn = $self->queue_name;
    for (0..$#items) {
        my $key  = $items[$_]->_key;
        my $data = $items[$_]->_serialized_data;

        $self->_script_cache->run_script(
            'enqueue_script',
            [1, $qn, $key, $data],
        );
    }

    return @items;
}

sub claim_item {
    my $self = shift;

    my ($key, $serialized_data) = $self->_script_cache->run_script(
        'claim_script',
        [1, $self->queue_name, time()],
    );
    return undef if not defined $key;

    my $item = Queue::Q::ClaimFIFO::Item->new(
        _serialized_data => $serialized_data,
        _key => $key,
    );
    $item->{item_data} = $item->_deserialize_data($serialized_data);

    return $item;
}

sub claim_items {
    my $self = shift;
    my $n = shift || 1;

    my @items;
    for (1..$n) {
        # TODO Lua script for multiple items!
        my ($key, $serialized_data) = $self->_script_cache->run_script(
            'claim_script',
            [1, $self->queue_name, time()],
        );
        last if not defined $key;

        my $item = Queue::Q::ClaimFIFO::Item->new(
            _serialized_data => $serialized_data,
            _key => $key,
        );
        $item->{item_data} = $item->_deserialize_data($serialized_data);
        push @items, $item;
    }

    return @items;
}

sub mark_item_as_done {
    my ($self, $item) = @_;

    my $key = $item->_key;
    $self->_script_cache->run_script(
        'finish_script',
        [1, $self->queue_name, $key],
    );
}

sub mark_items_as_done {
    my ($self) = shift;

    foreach (@_) {
        # TODO Lua script for multiple items!
        my $key = $_->_key;
        $self->_script_cache->run_script(
            'finish_script',
            [1, $self->queue_name, $key],
        );
    }
}

sub flush_queue {
    my $self = shift;
    $self->_redis_conn->del($self->queue_name);
    $self->_redis_conn->del($self->queue_name . CLAIMED_SUFFIX);
    $self->_redis_conn->del($self->queue_name . STORAGE_SUFFIX);
}

sub queue_length {
    my $self = shift;
    my ($len) = $self->_redis_conn->llen($self->queue_name);
    return $len;
}

sub claimed_count {
    my $self = shift;
    my ($len) = $self->_redis_conn->zcard($self->queue_name . CLAIMED_SUFFIX);
    return $len;
}

1;
