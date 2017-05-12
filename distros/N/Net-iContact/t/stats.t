#!perl -T
use strict;

use Test::More tests => 5;
use Net::iContact;

SKIP: {
    skip 'no api login info found', 5 unless (open(FH, '< apiinfo') and $_=<FH>);

    chomp;
    my ($user, $pass, $key, $secret) = split(/:/);
    my $api = Net::iContact->new($user,$pass,$key,$secret);
    my $ret = $api->login();
    diag("login error: " . $api->error->{'code'} . ': ' . $api->error->{'message'}) unless ($ret);

    my $stats = $api->stats(19521);
    ok($stats->{opens}->{unique} =~ /^\d+$/);
    ok($stats->{opens}->{count} =~ /^\d+$/);
    ok($stats->{bounces}->{percent} =~ /^\d+$/);
    ok($stats->{unsubscribes}->{count} =~ /^\d+$/);

    $TODO = 'not done yet';
    my $opens = $api->opens(19521);
    ok($opens->{'aoeu@mailinator.com'}->[0]->{date} =~ /^\w+ \d+, \d+ \d+:\d+:\d+ \w+$/);
}

