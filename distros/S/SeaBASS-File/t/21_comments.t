#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use Test::Trap qw(:default);

use SeaBASS::File;

my @DATA = split(m"<BR/>\s*", join('', <DATA>));

my $sb_file = SeaBASS::File->new(\$DATA[0]);

is_deeply(scalar($sb_file->get_comments), ['! comment 1', '! comment 2'], "get comments 1");
is_deeply(scalar($sb_file->get_comments(0)), ['! comment 1'], "add comment 1");
is_deeply(scalar($sb_file->get_comments(0, 1)), ['! comment 1', '! comment 2'], "add comment 2");

$sb_file->add_comment('comment 3');
is_deeply(scalar($sb_file->get_comments), ['! comment 1', '! comment 2', '! comment 3'], "add comment 3");
$sb_file->add_comment('  comment 4', '! comment 5');
is_deeply(scalar($sb_file->get_comments), ['! comment 1', '! comment 2', '! comment 3', '! comment 4', '! comment 5'], "add comment 4");

$sb_file->set_comments('c1', '!c2');
is_deeply(scalar($sb_file->get_comments), ['! c1', '!c2'], "set comments 1");

__DATA__
/begin_header
/missing=-999
/delimiter=space
/fields=date,time,lat,lon,depth,wt,sal
! comment 1
! comment 2
/end_header
19920109 16:30:00 31.389 -64.702 3.4 -999 -999
