#!perl -T
use strict;

use Test::More tests => 3;
use Net::iContact;

SKIP: {
    skip 'no api login info found', 3 unless (open(FH, '< apiinfo') and $_=<FH>);

    chomp;
    my ($user, $pass, $key, $secret) = split(/:/);
    my $api = Net::iContact->new($user,$pass,$key,$secret);
    $api->login or die("Failed to log in");

### Test campaigns()
    my $campaigns = $api->campaigns;
    ## This campaign exists in the test account
    ok(grep(1405,@$campaigns));
    ## This campaign does not.
    ok(grep(1,@$campaigns));

### campaign()
    my $campaign = $api->campaign(1405);
    ok($campaign->{name} eq 'apitest');
}
