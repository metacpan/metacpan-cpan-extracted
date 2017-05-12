package Queue::Q::NaiveFIFO::Redis;
use strict;
use warnings;
use Carp qw(croak);

use Queue::Q::NaiveFIFO;
use parent 'Queue::Q::NaiveFIFO';

use Redis;
use Sereal::Encoder;
use Sereal::Decoder;

our $SerealEncoder;
our $SerealDecoder;

use Class::XSAccessor {
    getters => [qw(server port queue_name db _redis_conn)],
};

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
    } => $class);

    $self->{_redis_conn} = Redis->new(
        %{$params{redis_options} || {}},
        encoding => undef, # force undef for binary data
        server => join(":", $self->server, $self->port),
    );

    $self->_redis_conn->select($self->db) if $self->db;

    return $self;
}

sub enqueue_item {
    my $self = shift;
    croak("Need exactly one item to enqeue")
        if not @_ == 1;
    my ($blob) = $self->_serialize($_[0]);
    $self->_redis_conn->lpush($self->queue_name, $blob);
}

sub enqueue_items {
    my $self = shift;
    return if not @_;
    my $qn = $self->queue_name;
    my $conn = $self->_redis_conn;
    my @blobs = $self->_serialize(@_);
    $conn->lpush($qn, @blobs);
}

sub claim_item {
    my ($self) = @_;
    my ($rv) = $self->_deserialize( $self->_redis_conn->rpop($self->queue_name) );
    return $rv;
}

sub claim_items {
    my ($self, $n) = @_;
    $n ||= 1;
    my $conn = $self->_redis_conn;
    my $qn = $self->queue_name;
    if ($n > 100) {
        my ($l) = $self->_redis_conn->llen($qn);
        $n = $l if $l < $n;
    }
    my @elem;
    $conn->rpop($qn, sub {push @elem, $_[0]}) for 1..$n;
    $conn->wait_all_responses;
    return $self->_deserialize( grep defined, @elem );
}

sub flush_queue {
    my $self = shift;
    $self->_redis_conn->del($self->queue_name);
}

sub queue_length {
    my $self = shift;
    my ($len) = $self->_redis_conn->llen($self->queue_name);
    return $len;
}

sub _serialize {
    my $self = shift;
    $SerealEncoder ||= Sereal::Encoder->new({stringify_undef => 1, warn_undef => 1});
    return map $SerealEncoder->encode($_), @_;
}

sub _deserialize {
    my $self = shift;
    $SerealDecoder ||= Sereal::Decoder->new();
    return map defined($_) ? $SerealDecoder->decode($_) : $_, @_;
}

1;

__END__

=head1 NAME

Queue::Q::NaiveFIFO::Redis - In-memory Redis implementation of the NaiveFIFO queue

=head1 SYNOPSIS

  use Queue::Q::NaiveFIFO::Redis;
  my $q = Queue::Q::NaiveFIFO::Redis->new(
      server     => 'myredisserver',
      port       => 6379,
      queue_name => 'my_work_queue',
  );
  $q->enqueue_item("foo");
  $q->enqueue_item({ bar => "baz" }); # any Sereal-serializable data structure
  my $foo = $q->claim_item;
  my $bar = $q->claim_item;

=head1 DESCRIPTION

Implements interface defined in L<Queue::Q::NaiveFIFO>:
an implementation based on Redis lists.

The data structures passed to C<enqueue_item> are serialized
using Sereal (cf. L<Sereal::Encoder>, L<Sereal::Decoder>), so
any data structures supported by that can be enqueued.

=head1 METHODS

All methods of L<Queue::Q::NaiveFIFO> plus:

=head2 new

Constructor. Takes named parameters. Required parameters are
the C<server> hostname or address, the Redis C<port>, and
the name of the Redis key to use as the C<queue_name>.

You may optionally specify a Redis C<db> number to use.
Since this module will establish the Redis connection,
you may pass in a hash reference of options that are valid
for the constructor of the L<Redis> module. This can be
passed in as the C<redis_options> parameter.

=head2 claim_item($timeout_secs)

The claim_item method has an optional parameter here, which
is the timeout in seconds it will wait for a new item.
Default wait time is one second. Using a timeout > 0 sec, no
additional sleep() calls are needed and items will be available
to the consumer without a delay.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, 2013, 2014 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
