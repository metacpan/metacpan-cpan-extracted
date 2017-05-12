#!perl
use strict;
use warnings;
{package CallBacks;
 use Net::Stomp::Frame;
 our @calls;
 sub new { bless {},shift }
 for my $m (qw(subscribe unsubscribe
               receive_frame ack
               send send_frame)) {
     no strict 'refs';
     *$m=sub {
         push @calls,[$m,@_];
         return 1;
     };
 }
 sub current_host { return 0 };
 sub connect {
     push @calls,['connect',@_];
     return Net::Stomp::Frame->new({
         command => 'CONNECTED',
         headers => {
             session => 'ID:foo',
         },
         body => '',
     });
 }
}
{package TestThing;
 use Moose;
 with 'Net::Stomp::MooseHelpers::CanConnect';
 with 'Net::Stomp::MooseHelpers::CanSubscribe';

 has '+connection_builder' => (
     default => sub { sub {
         return CallBacks->new();
     } },
 );
}

package main;
use Test::More;
use Test::Fatal;
use Test::Deep;
use Data::Printer;

my $obj;
is(exception {
    $obj = TestThing->new({
        servers => [ {
            hostname => 'test-host', port => 9999,
            subscribe_headers => { server_level => 'header' },
            connect_headers => { server_level => 'connect' },
        } ],
        connect_headers => { foo => 'bar' },
        subscribe_headers => { global => 'header' },
        subscriptions => [
            {
                destination => '/queue/somewhere',
                headers => { subscription_level => 'header' },
            },
            {
                destination => '/topic/something',
            },
        ],
    });

    $obj->connect;
    $obj->subscribe;
},undef,'can build & connect & subscribe');

cmp_deeply(\@CallBacks::calls,
           [
               [
                   'connect',
                   ignore(),
                   {
                       foo => 'bar',
                       server_level => 'connect',
                   },
               ],
               [
                   'subscribe',
                   ignore(),
                   {
                       ack => "client",
                       destination => "/queue/somewhere",
                       id => 0,
                       global => 'header',
                       server_level => "header",
                       subscription_level => "header"
                   }
               ],
               [
                   'subscribe',
                   ignore(),
                   {
                       ack => "client",
                       destination => "/topic/something",
                       id => 1,
                       global => 'header',
                       server_level => "header",
                   }
               ],
           ],
           'STOMP connect called with expected params')
    or note p @CallBacks::calls;

done_testing();


