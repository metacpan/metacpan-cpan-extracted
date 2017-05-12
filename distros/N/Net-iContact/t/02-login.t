#!perl -T
use strict;

use Test::More tests => 2;
use Net::iContact;

my $api = Net::iContact->new(1,2,3,'fnord');
$api->login;
ok($api->error->{'code'} == 401);

SKIP: {
    skip 'no api login info found', 1 unless (open(FH, '< apiinfo') and $_=<FH>);

    chomp;
    my ($user, $pass, $key, $secret) = split(/:/);
    $api = Net::iContact->new($user,$pass,$key,$secret);
    ok($api->login);
}

