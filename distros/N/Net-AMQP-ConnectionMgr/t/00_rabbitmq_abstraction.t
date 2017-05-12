#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Net::AMQP::ConnectionMgr;

# Now let's test that lazy intializations happen when we need it to connect.
my $safe_to_call = 0;
my $calls = 0;
my $underlying_object = bless {}, 'TestRabbitMQConn_1';
{ package TestRabbitMQConn_1;
  sub new {
      return $underlying_object;
  }
  sub connect {
      my $self = shift;
      $self->{connected} = 1;
      $calls++;
      ::ok($safe_to_call,__LINE__." called connect on the right time");
  }
  sub channel_open {
      $calls++;
      ::ok($safe_to_call,__LINE__." called channel_open on the right time");
  }
  sub is_connected {
      my $self = shift;
      $calls++;
      ::ok($safe_to_call,__LINE__." called is_connected on the right time");
      return $self->{connected};
  }
}

my $cmgr = Net::AMQP::ConnectionMgr->new(undef, undef, 'TestRabbitMQConn_1');
ok($cmgr, "Creates connectionmgr object");
is($cmgr->declare_channel
   (sub { my ($rmq, $channel) = @_;
          is($rmq, $underlying_object,__LINE__." correct rmq object");
          is($channel, 1, __LINE__." this is channel 1");
          $calls++;
          ok($safe_to_call, __LINE__." Called on the right time")}),
   1, "First channel is 1");
eval {
    $cmgr->declare_resource
      (sub { my ($rmq, $channel) = @_;
             is($rmq, $underlying_object, __LINE__." correct rmq object");
             is($channel, 2, __LINE__." this is channel 2");
             $calls++;
             ok($safe_to_call, __LINE__." Called on the right time")});
};
is($@, '', __LINE__." does not die.");
is($calls,0,__LINE__." did not make any unexpected calls");

# now we expect it to do the whole initialization.
$safe_to_call = 1;
$cmgr->with_connection_do
  (sub {
       my ($rmq) = @_;

       # we don't expect it to retry at this point.
       $safe_to_call = 0;

       is($rmq, $underlying_object, __LINE__.' correct rmq object');
       # 0 is_connected (no object, so it assumes disconnected)
       # 1 connect
       # 2 channel_open
       # 1 declare_channel callback
       # 1 declare_resource callback
       is($calls, 5, __LINE__." Called all the right things");
   });

# now we expect it to do the reinitialization
$safe_to_call = 1;
my $cause_failure = 1;
$cmgr->with_connection_do
  (sub {
       my ($rmq) = @_;

       if ($cause_failure) {
           $cause_failure = 0;
           $underlying_object->{connected} = 0;
           die "should retry";
       }
       is($rmq, $underlying_object, __LINE__.' correct rmq object');
       # the 5 from before
       # 1 is_connected (in the first run that fails)
       # 1 is_connected (after failing)
       # 1 connect
       # 2 channel_open
       # 1 declare_channel callback
       # 1 declare_resource callback
       is($calls, 12, __LINE__." Called all the right things");
   });


done_testing();

