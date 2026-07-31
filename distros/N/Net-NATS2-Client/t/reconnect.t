use strict;
use warnings;

use Test::More;
use Net::NATS2::Client;
use Net::NATS2::Subscription;

{

    package Local::Connection;

    sub new { bless {sent => []}, shift }

    sub send {
        push @{$_[0]->{sent}}, $_[1];
        return 1;
    }

    sub sent { $_[0]->{sent} }
}

{

    package Local::ReconnectClient;

    our @ISA = ('Net::NATS2::Client');

    sub connect {
        my $self = shift;
        ++$self->{connect_calls};
        return if $self->{connect_calls} < 2;
        $self->connection(Local::Connection->new);
        return 1;
    }

    sub read_line {return}
}

my $client       = Local::ReconnectClient->new(auto_reconnect => 0, reconnect_attempts => 2, reconnect_delay => 0,);
my $subscription = Net::NATS2::Subscription->new(
    subject  => 'reconnect.test',
    group    => '',
    sid      => 7,
    callback => sub { },
    client   => $client,
);
$client->subscriptions({7 => $subscription});

ok($client->wait_for_op(0), 'reconnects after a read-side disconnect');
is($client->{connect_calls}, 2, 'unlimited reconnect mode retries until success');
is_deeply($client->connection->sent, ['SUB reconnect.test 7'], 'restores subscriptions with their original SID');

my $disabled = Local::ReconnectClient->new(reconnect_delay => 0);
ok(!$disabled->wait_for_op(0), 'does not reconnect unless configured');

done_testing;
