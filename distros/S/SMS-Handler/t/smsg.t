# This -*- perl -*- code tests the split_msg stuff for completeness

# $Id: smsg.t,v 1.2 2002/12/27 19:43:42 lem Exp $

use Test::More tests => 13;
use SMS::Handler::Utils qw(Split_msg);

my $r_msg;

$r_msg = Split_msg(160, \ ('a' x 161));

#warn "# ret is $r_msg\n";

is(@$r_msg, 2, "Proper number of messages splitted");
#warn "# [0] $r_msg->[0]\n";
is($r_msg->[0], "1/2\n" . 'a' x 153 . '...');
#warn "# [1] $r_msg->[1]\n";
is($r_msg->[1], "2/2\n" . 'a' x 8);

$r_msg = Split_msg(160, \ ('a' x 320));
is(@$r_msg, 3, "Proper number of messages splitted");
is($r_msg->[0], "1/3\n" . 'a' x 153 . '...');
is($r_msg->[1], "2/3\n" . 'a' x 153 . '...');
is($r_msg->[2], "3/3\n" . 'a' x 14);

$r_msg = Split_msg(160, \( 'a' x 321));
is(@$r_msg, 3, "Proper number of messages splitted");
is($r_msg->[0], "1/3\n" . 'a' x 153 . '...');
is($r_msg->[1], "2/3\n" . 'a' x 153 . '...');
is($r_msg->[2], "3/3\n" . 'a' x 15);

$r_msg = Split_msg(160, \ ('a' x 150));
is(@$r_msg, 1, "Proper number of messages splitted");
is($r_msg->[0], "1/1\n" . 'a' x 150);

