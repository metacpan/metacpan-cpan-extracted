#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More tests => 8;
BEGIN { use_ok("Net::WoRMS"); }

my $WORMS = Net::WoRMS->new();
ok(defined $WORMS, 'Tool accessible');

my $AUT_DIAG = $WORMS->quoteAuthor("D'Alambert");
my $AUT_OUT  = "D’Alambert";

my $MAL_CTRL_DIAG = $WORMS->quoteString("Control sequence\n\r", 'SQL');
my $MAL_CTRL_OUT  = "'Control sequence<LF><CR>'";

my $MAL_BCKS_DIAG = $WORMS->quoteString('Backspace control \r', 'SQL'); 
my $MAL_BCKS_OUT  = "'Backspace control \\\\r'";

ok($AUT_DIAG eq $AUT_OUT, 'Author quote french shorts');
ok($MAL_CTRL_DIAG eq $MAL_CTRL_OUT, 'Control sequence');
ok($MAL_BCKS_DIAG eq $MAL_BCKS_OUT, 'Backspace sequence');
ok($WORMS->quoteString(undef, 'SQL') eq 'NULL', 'SQL: NULL');
ok($WORMS->quoteString(undef, 'TEXT') eq 'NA', 'TEXT: NA');
ok($WORMS->quoteString(undef, 'CSV') eq 'NA', 'CSV: NA');

done_testing();
