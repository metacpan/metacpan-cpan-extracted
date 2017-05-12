#!perl -T
use strict;

use Test::More tests => 5;
use Net::iContact;

SKIP: {
    skip 'no api login info found', 5 unless (open(FH, '< apiinfo') and $_=<FH>);

    chomp;
    my ($user, $pass, $key, $secret) = split(/:/);
    my $api = Net::iContact->new($user,$pass,$key,$secret);
    $api->login or die("Failed to log in");
    my $seq = $api->seq;

### Test lists()
    my $lists = $api->lists;
    ## That call should have incremented the sequence number..
    ok($api->seq == $seq+1);
    ## This list exists in the test account
    ok(grep(1936,@$lists));
    ## This list does not.
    ok(grep(1,@$lists));

### list()
    my $list = $api->list(1936);
    ok($api->seq == $seq+2);
    ok($list->{name} eq 'apitest');
}
