#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Net::ZooIt;
use Net::ZooKeeper qw(:all);
use Test::More;

Net::ZooIt::set_log_level(ZOOIT_DEBUG);

pipe RD, WR;
if (my $pid = fork) {
    close WR;
    my $line;

    $line = <RD>;
    print $line;
    ok($line =~ /$pid ZOOIT_DEBUG/, 'ZOOIT_DEBUG format');
    $line = <RD>;
    print $line;
    ok($line =~ /$pid ZOOIT_INFO/, 'ZOOIT_INFO format');
    $line = <RD>;
    print $line;
    ok($line =~ /$pid ZOOIT_WARN/, 'ZOOIT_WARN format');
    $line = <RD>;
    print $line;
    ok($line =~ /$pid ZOOIT_ERR/, 'ZOOIT_ERR format');
    $line = <RD>;
    print $line;
    ok($line =~ /$pid ZOOIT_DIE/, 'ZOOIT_DIE format, no zdebug at ZOOIT_DIE');
    $line = <RD>;
    print $line;
    ok($line =~ /^message at/, 'zdie dies');

    wait;
    ok($?, 'zdie nonzero exit status');
    close RD;
} else {
    close RD;
    open STDERR, '>&', WR or die $!;
    Net::ZooIt::zdebug "message";
    Net::ZooIt::zinfo "message\n";
    Net::ZooIt::zwarn "message";
    Net::ZooIt::zerr "message\n";
    Net::ZooIt::set_log_level(ZOOIT_DIE);
    Net::ZooIt::zdebug "message";
    Net::ZooIt::zdie "message";
}

ok(Net::ZooIt::zerr2txt(ZOK) eq 'ZOK', 'ZOK is ZOK');
ok(Net::ZooIt::z2txt('err', ZOK) eq 'ZOK', 'err errors');
ok(Net::ZooIt::z2txt('flag', ZOO_EPHEMERAL) eq 'ZOO_EPHEMERAL', 'flag node_flags');
ok(Net::ZooIt::z2txt('ev', ZOO_SESSION_EVENT) eq 'ZOO_SESSION_EVENT', 'ev events');
ok(Net::ZooIt::z2txt('st', ZOO_CONNECTED_STATE) eq 'ZOO_CONNECTED_STATE', 'st states');

done_testing;
