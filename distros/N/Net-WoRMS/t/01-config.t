#!/usr/bin/env perl
# MODULE ACCESABILITY ==================================================
# (C) 2026 by A. Weidauer
# Contact: alex.weidauer@huckfinn.de
# ======================================================================
use strict;
use warnings;
use Test::More tests => 15;
use feature qw(signatures);
no warnings 'once';
no warnings 'experimental::signatures';


BEGIN { use_ok("Net::WoRMS"); }
my $WORMS = Net::WoRMS->new();
ok(defined $WORMS, 'Tool accessible');

sub test($fun, $arg) {
    my $set = "change$fun";
    my $get = $fun;
    my $setOK = eval { $WORMS->$set($arg); 1 ; };
    ok($setOK, "Set $fun") or diag($@);
    my $getOK = eval { $WORMS->$get() eq $arg; };
    ok($getOK , "Get $fun") or diag($@);
}

test('EndPoint','URL');
test('AphiaURI','URI');
test('AphiaNS','NS');
test('Debug',1);
test('Format','TEXT');
ok($WORMS->getFormats()->{TEXT} == 1, 'Format TEXT');
ok($WORMS->getFormats()->{SQL}  == 2, 'Format SQL');
ok($WORMS->getFormats()->{CSV}  == 3, 'Format CSV');

done_testing();
# EOF ==================================================================
