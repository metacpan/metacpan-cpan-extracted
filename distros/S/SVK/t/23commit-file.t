use Test::More tests => 8;
use strict;
use SVK::Test;
our($output, $answer);
my ($xd, $svk) = build_test();
$svk->mkdir ('-m', 'init', '//V');
my $tree = create_basic_tree ($xd, '//V');
my ($copath, $corpath) = get_copath ('commit-file');
mkdir($copath);
chdir($copath);
is_output ($svk, 'checkout', ['//V/A/Q/qu'],
	   ["Syncing //V/A/Q/qu(/V/A/Q/qu) in ".__"$corpath/qu to 3.",
	    'A   qu']);
ok (-e 'qu');

append_file("qu", "change single file\n");

is_output($svk, 'diff', ['qu'],
	  ['=== qu',
	   '==================================================================',
	   "--- qu\t(revision 3)",
	   "+++ qu\t(local)",
	   '@@ -1,2 +1,3 @@',
	   ' first line in qu',
	   ' 2nd line in qu',
	   '+change single file',
	  ]);


is_output($svk, 'ci', [-m => 'commit single checkout', "qu"],
	  ['Committed revision 4.']);

is_output ($svk, 'checkout', ['//V/A/Q/qu', "boo"],
	   ["Syncing //V/A/Q/qu(/V/A/Q/qu) in ".__"$corpath/boo to 4.",
	    'A   boo']);
ok (-e 'boo');

TODO: {

local $TODO = 'checkout single file with different name';

append_file("boo", "change single file\n");
is_output($svk, 'diff', ['boo'],
	  ['=== boo',
	   '==================================================================',
	   "--- boo\t(revision 4)",
	   "+++ boo\t(local)",
	   '@@ -1,2 +1,3 @@',
	   ' first line in qu',
	   ' 2nd line in qu',
	   ' change single file',
	   '+change again',
	  ]);

is_output($svk, 'ci', [-m => 'commit single checkout', "boo"],
	  ['Committed revision 4.']);
}
