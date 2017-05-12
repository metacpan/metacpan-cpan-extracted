use warnings;
use strict;
use Test::More;
use Try::Tiny;

use_ok('Reflexive::ZmqSocket');
use_ok('Reflexive::ZmqSocket::ZmqError');
use_ok('Reflexive::ZmqSocket::ZmqMessage');
use_ok('Reflexive::ZmqSocket::ReplySocket');
use_ok('Reflexive::ZmqSocket::RequestSocket');
use_ok('Reflexive::ZmqSocket::PullSocket');
use_ok('Reflexive::ZmqSocket::PushSocket');
use_ok('Reflexive::ZmqSocket::DealerSocket');
use_ok('Reflexive::ZmqSocket::RouterSocket');
use_ok('Reflexive::ZmqSocket::PairSocket');
use_ok('Reflexive::ZmqSocket::PubSocket');
use_ok('Reflexive::ZmqSocket::SubSocket');

my $module;
foreach my $type (qw/Reply Request Pull Push Dealer Router Pair Sub Pub/)
{
    $module = "Reflexive::ZmqSocket::${type}Socket";
    try
    {
        $module->new(active => 0);
        pass("Instantiated $module");
    }
    catch
    {
        fail("Failed to instantiate $module: $_");
    };
}

done_testing();
