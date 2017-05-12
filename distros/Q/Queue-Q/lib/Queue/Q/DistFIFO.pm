package Queue::Q::DistFIFO;
use strict;
use warnings;
use Carp qw(croak);

use List::Util ();
use Scalar::Util qw(refaddr blessed);

use Class::XSAccessor {
    getters => [qw(shards next_shard)],
};

sub new {
    my $class = shift;
    my $self = bless({
        @_,
        next_shard => 0,
    } => $class);

    if (not defined $self->{shards}
        or not ref($self->{shards}) eq 'ARRAY'
        or not @{$self->{shards}})
    {
        croak("Need 'shards' parameter being an array of shards");
    }

    $self->{shards_order} = [ List::Util::shuffle( @{$self->shards} ) ];

    return $self;
}

sub _next_shard {
    my $self = shift;
    my $ns = $self->{next_shard};
    my $so = $self->{shards_order};
    if ($ns > $#{$so}) {
        $ns = $self->{next_shard} = 0;
    }
    ++$self->{next_shard};
    return $so->[$ns];
}

sub enqueue_item {
    my $self = shift;
    croak("Need exactly one item to enqeue")
        if not @_ == 1;
    return $self->_next_shard->enqueue_item($_[0]);
}

sub enqueue_items {
    my $self = shift;
    return if not @_;
    my @rv;
    push @rv, $self->_next_shard->enqueue_item($_) for @_;
    return @rv;
}

sub enqueue_items_strict_ordering {
    my $self = shift;
    return if not @_;
    my $shard = $self->_next_shard;
    return $shard->enqueue_items(@_);
}

sub claim_item {
    my $self = shift;
    # FIXME very inefficient!
    my $shard = $self->_next_shard;
    my $first_shard_addr = refaddr($shard);
    my $class;
    while (1) {
        my $item = $shard->claim_item;
        if (defined $item) {
            $item->{_shard} = $shard
                if blessed($item)
                and $item->isa('Queue::Q::ClaimFIFO::Item');
            return $item;
        }
        $shard = $self->_next_shard;
        return undef if refaddr($shard) == $first_shard_addr;
    }
}

sub claim_items {
    my ($self, $n) = @_;
    $n ||= 1;

    my $nshards = $self->num_shards;
    my $at_a_time = int( $n / $nshards );
    my $left_over = $n % $nshards;
    my @shard_items = (($at_a_time) x $nshards);
    ++$shard_items[$_] for 0 .. ($left_over-1);

    my @elem;

    my $shard = $self->_next_shard;
    my $first_shard_addr = refaddr($shard);
    my $i = 0;
    my $nmissing = 0;
    while (1) {
        my $thisn = $shard_items[$i];
        my @items = $shard->claim_items($thisn);
        $shard_items[$i] -= scalar @items;
        $nmissing += $shard_items[$i];
        @items = map {
                $_->{_shard} = $shard
                    if blessed($_)
                    and $_->isa('Queue::Q::ClaimFIFO::Item');
                $_
            } @items;
        push @elem, @items;
        $shard = $self->_next_shard;
        last if scalar(@elem) == $n
             or refaddr($shard) == $first_shard_addr;
        ++$i;
    }

    # Fall back to naive mode - this could be done much
    # better by redistributing the remaining items to the
    # shards that had data... FIXME
    for (1 .. $nmissing) {
        my $item = $self->claim_item;
        last if not defined $item;
        push @elem, $item;
    }

    return @elem;
}

sub flush_queue {
    my $self = shift;
    my $shards = $self->{shards};
    for my $i (0..$#$shards) {
        $shards->[$i]->flush_queue;
    }
    return();
}

sub queue_length {
    my $self = shift;
    my $shards = $self->{shards};
    my $len = 0;
    for my $i (0..$#$shards) {
        $len += $shards->[$i]->queue_length;
    }
    return $len;
}

sub claimed_count {
    my $self = shift;
    my $shards = $self->{shards};
    my $ccount = 0;
    for my $i (0..$#$shards) {
        my $shard = $shards->[$i];
        my $meth = $shard->can("claimed_count");
        if (not $meth) {
            Carp::croak("Shard $i does not support claimed count. Is it of type NaiveFIFO?");
        }
        $ccount += $meth->($shard);
    }
    return $ccount;
}

sub mark_item_as_done {
    my $self = shift;
    my $item = shift;
    my $shard = delete $item->{_shard};
    die "Need item's shard to mark it as done! "
        . "Or was this item previously marked as done?" if not $shard;
    $shard->mark_item_as_done($item);
}

sub mark_items_as_done {
    my $self = shift;
    $self->mark_item_as_done($_) for @_;
}

sub num_shards {
    my $self = shift;
    return scalar(@{ $self->{shards} });
}

1;
