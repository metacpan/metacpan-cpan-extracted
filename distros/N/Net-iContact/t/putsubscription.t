#!perl -T
use strict;

use Test::More tests => 3;
use Net::iContact;

SKIP: {
    skip 'no api login info found', 3 unless (open(FH, '< apiinfo') and $_=<FH>);

    chomp;
    my ($user, $pass, $key, $secret) = split(/:/);
    my $api = Net::iContact->new($user,$pass,$key,$secret);
    my $ret = $api->login();

    $ret = $api->putsubscription(695535, 1936, 'unsubscribed');
    ok($ret);
    ok($api->subscriptions(695535)->{1936} eq 'unsubscribed');

    $ret = $api->putsubscription(695535, 1936, 'subscribed');
    ok($api->subscriptions(695535)->{1936} eq 'subscribed');
}

