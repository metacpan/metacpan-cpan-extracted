package Queue::Q::ReliableFIFO::Item;
use strict;
use warnings;

use Class::XSAccessor {getters => ['_serialized']};

# for reasons of debugging, JSON is easier, while Sereal::* is
# faster (about 7%) and delivers smaller serialized blobs.
use JSON::XS; # use the real stuff, no fall back on pure Perl JSON please
my $serializer   = JSON::XS->new->utf8->pretty(0);
my $deserializer = JSON::XS->new->utf8->pretty(0);

#use Sereal::Encoder;
#use Sereal::Decoder;
#my $serializer   = Sereal::Encoder->new();
#my $deserializer = Sereal::Decoder->new();

my @item_info = (
    't',        # time the item was created
    'rc',       # requeue counter (how often the item is requeued)
    'fc',       # fail counter (how often the item reached max-requeue)
    'error',    # last error message
);

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;

    die "'data' or '_serialized' named parameters required for constructor"
        if not exists $self->{data} and not exists $self->{_serialized};

    if (not exists $self->{_serialized}) {
        $self->{_serialized} ||=
            $serializer->encode({
                t => time(),
                b => $self->{data}
             });
    }
    return $self;
}

sub _get { 
    my ($self, $elem) = @_;
    $self->_deserialize
        if not exists $self->{data};
    return $self->{$elem};
}

sub time_created  { $_[0]->_get('t_created') || $_[0]->_get('t') }
sub time_queued   { $_[0]->_get('t') }
sub data          { $_[0]->_get('data') }
sub requeue_count { $_[0]->_get('rc') || 0 }
sub fail_count    { $_[0]->_get('fc') || 0 }
sub last_error    { $_[0]->_get('error') }

sub inc_nr_requeues {
    my $self = shift;
    my $plain = $deserializer->decode($self->{_serialized});
    $self->{rc} = ++$plain->{rc};
    $self->{_serialized} =  $serializer->encode($plain);
    return $self->{rc};
}

sub _deserialize {
    my $self = shift;
    my $plain = $deserializer->decode($self->{_serialized});
    $self->{data} = $plain->{b};
    for my $k (@item_info) {
        if (exists $plain->{$k}) {
            $self->{$k} = $plain->{$k};
        }
        else {
            delete $self->{$k};
        }
    }
}
1;
__END__

=head1 NAME

Queue::Q::ReliableFIFO::Item - An item object of an queue item

=head1 SYNOPSIS

  use Queue::Q::ReliableFIFO::Item;
  my $item = Queue::Q::ReliableFIFO::Item->new(data => { id => 23 });
  my $time_created = $item->time_created;   # epoch time


  # items can be created from serialized data (to be used by 
  # Queue::Q::ReliableFIFO::Redis).
  my $item = Queue::Q::ReliableFIFO::Item->new(_serialized => $serialized);
  my $data = $item->data();
  my $last_error = $item->last_error();

=head1 METHODS

=head2 $item = new(data => $data)

Constructor for an item object (key "data" for plain data that needs to 
be serialized, key "_serialized" for data that needs to be deserialzed).

=head2 $data = $item->data()

Returns the data where the item was created from.

=head2 $time_created = $item->time_created()

Returns de time (epoch) the item was originally created (put in the queue).

=head2 $time_queued = $item->time_queued()

Returns de time (epoch) the item was put in the queue for the last time.

=head2 $n = $item->requeue_count()

Returns the number the item was requeued. Requeuing can happen when
processing the item fails.

=head2 $n = $item->fail_count()

Returns the number the item was requeued. An item fails after the it has
been retried up to requeue_limit times (See Redis.pm).

=head2 $n = $item->last_error()

Returns the last error message of processing this item.

=head2 inc_nr_requeues()

Increases the requeue counter of this item.

=cut
