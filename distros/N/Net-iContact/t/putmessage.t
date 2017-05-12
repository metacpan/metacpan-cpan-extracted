#!perl -T
use strict;

use Test::More tests => 1;
use Net::iContact;

SKIP: {
    skip 'no api login info found', 1 unless (open(FH, '< apiinfo') and $_=<FH>);
    skip 'will not create messages', 1 unless (exists($ENV{TESTALL}));

    chomp;
    my ($user, $pass, $key, $secret) = split(/:/);
    my $api = Net::iContact->new($user,$pass,$key,$secret);
    my $ret = $api->login();
    diag("login error: " . $api->error->{'code'} . ': ' . $api->error->{'message'}) unless ($ret);

    my $msgid = $api->putmessage('lollersub', 1405, 'text', 'html');
    diag("Got error: " . $api->error->{'code'} . ': ' . $api->error->{'message'}) unless ($msgid);
    ok($msgid =~ /\d+/, 'message created');
}

