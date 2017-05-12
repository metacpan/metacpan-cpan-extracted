use warnings;
use strict;

use Test::More tests => 89;

my $test_input = 
	"\x1a\x21\xc3\x56\x0c\x20\x6a\x19"."\xa9\x46\xf6\xd1\x2e\xc6\xc8\xf8".
	"\x90\xb5\xc1\x8f\x00\xd8\x9c\x8d"."\xa6\xf6\xd3\x03\xaa\xa5\x7e\x57";

my $f;

ok open($f, "<", \$test_input);
$/ = \3;
is scalar(<$f>), "\x1a\x21\xc3";
is tell($f), 3;
ok binmode($f, ":rewindable");
is tell($f), 0;
is scalar(<$f>), "\x56\x0c\x20";
is tell($f), 3;
is scalar(<$f>), "\x6a\x19\xa9";
is tell($f), 6;
ok seek($f, 1, 0);
is tell($f), 1;
is scalar(<$f>), "\x0c\x20\x6a";
is tell($f), 4;
is scalar(<$f>), "\x19\xa9\x46";
is tell($f), 7;
ok seek($f, -2, 1);
is tell($f), 5;
is scalar(<$f>), "\xa9\x46\xf6";
is tell($f), 8;
is scalar(<$f>), "\xd1\x2e\xc6";
is tell($f), 11;
is scalar(<$f>), "\xc8\xf8\x90";
is tell($f), 14;
ok seek($f, 1, 0);
is tell($f), 1;
is scalar(<$f>), "\x0c\x20\x6a";
is tell($f), 4;
ok seek($f, 7, 0);
is tell($f), 7;
is scalar(<$f>), "\xf6\xd1\x2e";
is tell($f), 10;
ok seek($f, 2, 1);
is tell($f), 12;
is scalar(<$f>), "\xf8\x90\xb5";
is tell($f), 15;
$f = undef;

ok open($f, "<", \$test_input);
$/ = \8;
is scalar(<$f>), "\x1a\x21\xc3\x56\x0c\x20\x6a\x19";
ok binmode($f, ":rewindable");
ok !eof($f);
is scalar(<$f>), "\xa9\x46\xf6\xd1\x2e\xc6\xc8\xf8";
ok !eof($f);
is scalar(<$f>), "\x90\xb5\xc1\x8f\x00\xd8\x9c\x8d";
ok !eof($f);
is scalar(<$f>), "\xa6\xf6\xd3\x03\xaa\xa5\x7e\x57";
ok eof($f);
is scalar(<$f>), undef;
ok eof($f);
is tell($f), 24;
ok seek($f, -3, 1);
is tell($f), 21;
ok !eof($f);
is scalar(<$f>), "\xa5\x7e\x57";
ok eof($f);
is scalar(<$f>), undef;
$f = undef;

ok open($f, "<", \$test_input);
$/ = \8;
is scalar(<$f>), "\x1a\x21\xc3\x56\x0c\x20\x6a\x19";
ok binmode($f, ":rewindable");
is scalar(<$f>), "\xa9\x46\xf6\xd1\x2e\xc6\xc8\xf8";
ok !seek($f, -10, 1);
$f = undef;

ok open($f, "<", \$test_input);
$/ = \8;
is scalar(<$f>), "\x1a\x21\xc3\x56\x0c\x20\x6a\x19";
ok binmode($f, ":rewindable");
is scalar(<$f>), "\xa9\x46\xf6\xd1\x2e\xc6\xc8\xf8";
ok !seek($f, 1, 1);
$f = undef;

ok open($f, "<", \$test_input);
$/ = \8;
is scalar(<$f>), "\x1a\x21\xc3\x56\x0c\x20\x6a\x19";
ok binmode($f, ":rewindable");
is scalar(<$f>), "\xa9\x46\xf6\xd1\x2e\xc6\xc8\xf8";
ok !seek($f, 9, 0);
$f = undef;

ok open($f, "<", \$test_input);
$/ = \8;
is scalar(<$f>), "\x1a\x21\xc3\x56\x0c\x20\x6a\x19";
ok binmode($f, ":rewindable");
is scalar(<$f>), "\xa9\x46\xf6\xd1\x2e\xc6\xc8\xf8";
ok !seek($f, 0, 2);
$f = undef;

ok open($f, "<", \$test_input);
$/ = \8;
is scalar(<$f>), "\x1a\x21\xc3\x56\x0c\x20\x6a\x19";
ok binmode($f, ":rewindable");
is scalar(<$f>), "\xa9\x46\xf6\xd1\x2e\xc6\xc8\xf8";
is scalar(<$f>), "\x90\xb5\xc1\x8f\x00\xd8\x9c\x8d";
is scalar(<$f>), "\xa6\xf6\xd3\x03\xaa\xa5\x7e\x57";
ok eof($f);
ok !seek($f, 0, 2);
$f = undef;

ok open($f, "<", \$test_input);
$/ = \8;
is scalar(<$f>), "\x1a\x21\xc3\x56\x0c\x20\x6a\x19";
ok binmode($f, ":rewindable");
is scalar(<$f>), "\xa9\x46\xf6\xd1\x2e\xc6\xc8\xf8";
ok seek($f, -4, 1);
ok binmode($f, ":pop");
is scalar(<$f>), "\x2e\xc6\xc8\xf8\x90\xb5\xc1\x8f";
$f = undef;

1;
