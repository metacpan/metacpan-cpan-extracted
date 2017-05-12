package Mojolicious::Plugin::RedisSubscriber;

use warnings;
use strict;
use Mojo::Base 'Mojo::EventEmitter';

use Cache::RedisDB;
use Mojo::Redis;
use YAML::XS;
use Try::Tiny;

our $VERSION = "0.0.1";

=head1 NAME

Mojolicious::Plugin::RedisSubscriber

=head1 SYNOPSIS

    use Mojolicious::Plugin::RedisSubscriber;
    my $redis = Mojolicious::Plugin::RedisSubscriber->new;
    my $cb = $redis->subscribe("feed::frxEURUSD", sub { ... });
    ...;
    $redis->unsubscribe("feed::frxEURUSD", $cb);

=head1 DESCRIPTION

Module subscribes to specified channels and emits events when there are messages.

=cut

has channel_hash => sub { return {'Mojo::RedisSubscriber' => 1} };

has redis => sub {
    my $self = shift;
    my $_subscribe;
    $_subscribe = sub {
        my $channels = shift;
        my $subs     = Mojo::Redis::Subscription->new(
            server   => Cache::RedisDB->redis_server_info,
            channels => $self->channels,
            encoding => '',
            timeout  => 300,
        );
        $subs->on(close   => sub { $_subscribe->($self->channels) });
        $subs->on(error   => sub { $_subscribe->($self->channels) });
        $subs->on(timeout => sub { $_subscribe->($self->channels) });
        $subs->on(
            message => sub {
                my (undef, $message, $channel) = @_;
                if ($message && $message =~ /^--/) {
                    $message = try { Load($message) };
                }
                $self->emit($channel => $message);
            },
        );
        $subs->connect;
        $self->redis($subs);
        return $subs;
    };
    return $_subscribe->($self->channels);
};

=head1 METHODS

Module provides the following methods:

=cut

=head2 $self->channel_hash

Returns the underlying subscriber object.

=head2 $self->channels

Returns reference to list of channel names to which redis is subscribed.

=cut

sub channels {
    my $self = shift;
    return [keys %{$self->channel_hash}];
}

=head2 $self->redis

returns the underlying redis server object.

=head2 $self->subscribe($channel => $callback)

Ensures that module subscribed to specified redis channels and adds
I<$callback> to the list invoked when there's a message in channel

=cut

sub subscribe {
    my ($self, $channel, $callback) = @_;
    my $redis = $self->redis;
    unless ($self->channel_hash->{$channel}++) {
        $redis->execute([subscribe => "$channel"]);
    }
    return $self->on($channel => $callback);
}

=head2 $self->unsubscribe($channel => $callback)

Unsubscribes I<$callback> from the I<$channel>

=cut

sub unsubscribe {
    my ($self, $channel, $callback) = @_;
    my $redis = $self->redis;
    return unless $self->channel_hash->{$channel};
    unless (--$self->channel_hash->{$channel}) {
        $redis->execute([unsubscribe => "$channel"]);
    }
    return $self->SUPER::unsubscribe($channel => $callback);
}

=head1 FEATURES NOT YET SUPPORTED

Configuration vs config yml files, particularly regarding default channels

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Regent Markets.  This may be distributed under the same terms as Perl itself.

=cut

1;
