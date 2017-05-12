#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockModule;
use Plack::App::ServiceStatus::NetStomp;

Test::MockObject->fake_module('Net::Stomp::Frame');
Test::MockObject->fake_new('Net::Stomp::Frame');

my $stomp              = Test::MockObject->new();
my $reconnect_attempts = 0;
$stomp->mock(
    reconnect_attempts => sub {
        if ( scalar @_ == 2 ) {
            $reconnect_attempts = $_[1];
        }
        return $reconnect_attempts;
    }
);
$stomp->mock( send_frame => sub { } );
my $txns = 0;
$stomp->mock( _get_next_transaction => sub { $txns++ } );

subtest 'check success case' => sub {
    my @result = Plack::App::ServiceStatus::NetStomp->check($stomp);
    is( scalar @result,      1,    'result length ok' );
    is( $result[0],          'ok', 'status ok' );
    is( $reconnect_attempts, 0,    'reconnect attempts reset' );

    @result = Plack::App::ServiceStatus::NetStomp->check( sub { $stomp } );
    is( $result[0], 'ok', 'status ok' );
};

subtest 'check failure case' => sub {
    $stomp->mock( send_frame => sub { die 'Connect failed' } );
    my @result = Plack::App::ServiceStatus::NetStomp->check($stomp);
    is( scalar @result, 2,     'result length ok' );
    is( $result[0],     'nok', 'status not ok' );
    like( $result[1], qr{Not connected: Connect failed}, 'message correct' );
    is( $reconnect_attempts, 0, 'reconnect attempts reset' );

    @result = Plack::App::ServiceStatus::NetStomp->check( sub { $stomp } );
    is( $result[0], 'nok', 'status not ok' );
};

done_testing;
