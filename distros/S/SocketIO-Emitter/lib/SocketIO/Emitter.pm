package SocketIO::Emitter;
use strict;
use warnings;
our $VERSION = 0.04;

use Redis;
use Data::MessagePack;

use Moo;
use namespace::clean;

has redis  => ( is => 'rw');
has key    => ( is => 'rw');
has prefix => ( is => 'rw');
has rooms  => ( is => 'rw', default => sub {[]} );
has flags  => ( is => 'rw', default => sub {{}} );
has messagepack => ( is => 'rw', default => sub { Data::MessagePack->new() } );

my $UID = 'emitter';
my $EVENT = 2;
my $BINARY_EVENT = 5;

sub BUILD {
     my $self = shift;
     # redis
     my $redis = $self->redis || Redis->new();
     $self->redis($redis);
     # prefix
     $self->prefix($self->key ? $self->key : 'socket.io');
}

sub json      { $_[0]->flags->{json}      = 1; $_[0]; }
sub volatile  { $_[0]->flags->{volatile}  = 1; $_[0]; }
sub broadcast { $_[0]->flags->{broadcast} = 1; $_[0]; }

sub in {
    my ($self, $room) = @_;
    push @{$self->rooms}, $room
        unless grep { $_ eq $room } @{$self->rooms};
    $self;
}

sub to {
    my ($self, $room) = @_;
    $self->in($room);
    $self;
}

sub of {
    my ($self, $nsp) = @_;
    $self->flags->{nsp} = $nsp;
    $self;
}

sub emit {
    my ($self, @args) = @_;

    $self->flags->{nsp} = '/' unless exists $self->{flags}->{nsp};
    my $chn = $self->prefix . '#' . $self->flags->{nsp} . '#';

    my $pack_data = $self->pack(@args);
    my $packed = $self->messagepack->utf8->pack($pack_data);

    if (scalar @{ $self->rooms }) {
        for my $room (@{ $self->rooms }) {
            my $chn_room = $chn . $room . '#';
            $self->redis->publish($chn_room, $packed);
        }
    } else {
        $self->redis->publish($chn, $packed);
    }

    # clear
    $self->clear;

    $self;
}

sub pack {
    my ($self, @args) = @_;

    my %packet;
    $packet{type} = ($self->include_binary(@args)) ? $BINARY_EVENT : $EVENT;
    $packet{data} = \@args;
    $packet{nsp}  = delete $self->flags->{'nsp'};

    return [$UID, \%packet, { rooms => $self->rooms, flags => $self->flags }];
}

sub clear {
    my ($self) = @_;

    $self->rooms([]);
    $self->flags({});
}

sub include_binary {
    my ($self, @args) = @_;
    for(@args) {
        return 1 if $_ && /[[:^ascii:]]/;
    }
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

SocketIO::Emitter - A Perl implementation of socket.io-emitter.

=head1 SYNOPSIS

    use strict;
    use warnings;
    use SocketIO::Emitter;

    my $em = SocketIO::Emitter->new(
      #  key => 'another-key',
      #  redis => Redis->new(server => 'localhost:6380'),
    );

    # emit
    $em->emit('event', 'broadcast blah blah blah');

    # namespace emit
    $em->of('/nsp')->emit('event', 'nsp broadcast blah blah blah');

    # namespace room broadcast
    $em->of('/nsp')->room('roomId')->broadcast->emit('event', 'yahooooooo!!!!');


=head1 DESCRIPTION

A Perl implementation of socket.io-emitter.

This project uses redis. Make sure your environment has redis.


=head1 LICENSE

Copyright (C) Tsuyoshi Torii

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Tsuyoshi Torii E<lt>toritori0318@gmail.comE<gt>

=cut
