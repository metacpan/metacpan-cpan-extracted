#!/usr/bin/env perl

package main;

use strict;
use warnings;

use Net::Curl::Easy qw(:constants);

use Linux::Perl::epoll ();

my @urls = (
    'http://perl.com',
    'http://metacpan.org',
);

my $epoll = Linux::Perl::epoll->new();

#----------------------------------------------------------------------

my $http = My::Curl::Epoll->new($epoll);

for my $url (@urls) {
    my $handle = Net::Curl::Easy->new();
    $handle->setopt( CURLOPT_URL() => $url );
    $handle->setopt( CURLOPT_FOLLOWLOCATION() => 1 );
    $http->add_handle($handle)->then(
        sub { print "$url completed.$/" },
        sub { warn "$url: " . shift },
    );
}

#----------------------------------------------------------------------

while ($http->handles()) {
    my @events = $epoll->wait(
        maxevents => 10,
        timeout => $http->get_timeout() / 1000,
    );

    if (@events) {
        $http->process( \@events );
    }
    else {
        $http->time_out();
    }
}

#----------------------------------------------------------------------

package My::Curl::Epoll;

use parent 'Net::Curl::Promiser';

sub _INIT {
    my ($self, $args_ar) = @_;

    $self->{'_epoll'} = $args_ar->[0];
    $self->{'_fds'} = {};

    return;
}

sub _GET_FD_ACTION {
    my ($self, $args_ar) = @_;

    my %fd_action;

    my $events_ar = $args_ar->[0];

    while ( my ($fd, $evts_num) = splice @$events_ar, 0, 2 ) {
        if ($evts_num & $epoll->EVENT_NUMBER()->{'IN'}) {
            $fd_action{$fd} = Net::Curl::Multi::CURL_CSELECT_IN();
        }

        if ($evts_num & $epoll->EVENT_NUMBER()->{'OUT'}) {
            $fd_action{$fd} += Net::Curl::Multi::CURL_CSELECT_OUT();
        }
    }

    return \%fd_action;
}

sub _set_epoll {
    my ($self, $fd, @events) = @_;

    if ( exists $self->{'_fds'}{$fd} ) {
        $self->{'_epoll'}->modify( $fd, events => \@events );
    }
    else {
        $self->{'_epoll'}->add( $fd, events => \@events );
        $self->{'_fds'}{$fd} = undef;
    }

    return;
}

sub _SET_POLL_IN {
    my ($self, $fd) = @_;

    return $self->_set_epoll( $fd, 'IN' );
}

sub _SET_POLL_OUT {
    my ($self, $fd) = @_;
    return $self->_set_epoll( $fd, 'OUT' );
}

sub _SET_POLL_INOUT {
    my ($self, $fd) = @_;
    return $self->_set_epoll( $fd, 'IN', 'OUT' );
}

sub _STOP_POLL {
    my ($self, $fd) = @_;
    if ( delete $self->{'_fds'}{$fd} ) {
        $self->{'_epoll'}->delete( $fd );
    }

    return;
}

1;
