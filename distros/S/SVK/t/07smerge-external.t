#!/usr/bin/perl -w
use strict;
use Test::More tests => 25;
use SVK::Test;

our ($answer, $output);

my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('smerge-external');

$answer = 's'; # skip

$svk->mkdir ('-m', 'the trunk', '//trunk');
$svk->co ('//trunk', $copath);
overwrite_file ("$copath/test.pl", "#!/usr/bin/perl -w\nsub { 'this is sub' }\n#common\n#common2\n\n\n");
$svk->add ("$copath/test.pl");
$svk->ps ("svn:eol-style", "native", "$copath/test.pl");
$svk->commit ('-m', 'test.pl', $copath);

$svk->cp ('-m', 'local branch of trunk', '//trunk', '//local');

overwrite_file ("$copath/test.pl", "#!/usr/bin/perl -T -w\nsub { 'this is sub on local' }\n#common\n\nsub newsub { undef }\n#common2\n\n\n");
$svk->commit ('-m', 'change on trunk', $copath);

$svk->switch ('//local', $copath);
overwrite_file ("$copath/test.pl", "#!/usr/bin/perl -w\nsub { 'this is sub on trunk' }\n#common\n\nsub newsub { undef }\n#common2\n\n\n#trunk\ntrunk additions (do not kill!)\n");

$svk->commit ('-m', 'change on local', $copath);

is_output_like ($svk, 'sm', ['-C', '//trunk', '//local'],
		qr|1 conflict found.|);

$ENV{SVKRESOLVE} = '';
$answer = 't'; # yours
$svk->sm ('//trunk', $copath);

is_output ($svk, 'diff', ["$copath/test.pl"],
	   [__"=== $copath/test.pl",
            "==================================================================",
            __"--- $copath/test.pl\t(revision 5)",
            __"+++ $copath/test.pl\t(local)",
            __('@@ -1,5 +1,5 @@'),
            "-#!/usr/bin/perl -w",
            "-sub { 'this is sub on trunk' }",
            "+#!/usr/bin/perl -T -w",
            "+sub { 'this is sub on local' }",
            " #common",
            " ",
            " sub newsub { undef }",
           ], 'svk-merge mine');

$answer = 't'; # theirs
$svk->sm ('-m', 'merge from trunk to local', '//trunk', '//local');

is_output ($svk, 'diff', ["//trunk/test.pl", "//local/test.pl"],
	   [__"=== test.pl",
	    "==================================================================",
	    "--- test.pl\t(/trunk/test.pl)\t(revision 6)",
	    "+++ test.pl\t(/local/test.pl)\t(revision 6)",
	    __('@@ -6,3 +6,5 @@'),
	    " #common2",
	    " ",
	    " ",
	    "+#trunk",
	    "+trunk additions (do not kill!)",
	   ], 'svk-merge mine');
is_output ($svk, 'up', ["$copath"],
	   ["Syncing //local(/local) in $corpath to 6.",
	    __"g   $copath/test.pl",
	    __" g  $copath"], 'svk-merge theirs');

overwrite_file ("$copath/test.pl", "#!/usr/bin/perl -T -w\nsub { 'this is sub on trunk' }\n#local\n#common\n\nsub newsub { undef }\n");
$svk->commit ('-m', 'change on local', $copath);
$svk->switch ('//trunk', $copath);
overwrite_file ("$copath/test.pl", "#!/usr/bin/perl -T -w\nsub { 'this is sub on trunk' }\n#common\n\nsub newsub { undef }\n#trunk\n");
$svk->commit ('-m', 'change on trunk', $copath);

is_output_like ($svk, 'sm', ['-m', 'merge to local again', '//trunk', '//local'],
		qr|G   test\.pl|);

overwrite_file ("$copath/test.pl", "trunk!\n");
$svk->commit ('-m', 'change on trunk', $copath);
$svk->switch ('//local', $copath);
$svk->up($copath);
overwrite_file ("$copath/test.pl", "local!\n");
$svk->commit ('-m', 'change on local', $copath);

is_output_like ($svk, 'sm', ['-C', '//trunk', '//local'],
		qr|1 conflict found.|);

# $SVKRESOLVE trumps $answer
$ENV{SVKRESOLVE} = 's'; # skip
is_output_like ($svk, 'sm', ['-m', 'merge to local again', '//trunk', '//local'],
		qr|C   test\.pl|);

$answer = 's'; # skip

$ENV{SVKRESOLVE} = 'd'; # diff
is_output_like ($svk, 'sm', ['-m', 'merge to local again', '//trunk', '//local'], qr|
\+>>>> YOUR VERSION test\.pl \(/local\) (\d+)\r?
 .*\r?
\+==== ORIGINAL VERSION test\.pl \1\r?
\+.*\r?
\+==== THEIR VERSION test\.pl \(/trunk\) \1\r?
\+.*!\r?
\+<<<< \1\r?
|s);

$ENV{SVKRESOLVE} = 'dm'; # diff merged
is_output_like ($svk, 'sm', ['-m', 'merge to local again', '//trunk', '//local'], qr|
\+>>>> YOUR VERSION test.pl \(/local\) (\d+)\r?
\+.*\r?
\+==== ORIGINAL VERSION test.pl \1\r?
 .*\r?
\+==== THEIR VERSION test.pl \(/trunk\) \1\r?
\+.*\r?
\+<<<< \1\r?
|s);

$ENV{SVKRESOLVE} = 'dy'; # diff yours
is_output_like ($svk, 'sm', ['-m', 'merge to local again', '//trunk', '//local'], qr|
-#!/usr/bin/perl -T -w\r?
-sub { 'this is sub on trunk' }\r?
-#common\r?
-\r?
-sub newsub { undef }\r?
-#trunk\r?
\+local!\r?
|s);

$ENV{SVKRESOLVE} = 'dt'; # diff theirs
is_output_like ($svk, 'sm', ['-m', 'merge to local again', '//trunk', '//local'], qr|
-#!/usr/bin/perl -T -w\r?
-sub { 'this is sub on trunk' }\r?
-#common\r?
-\r?
-sub newsub { undef }\r?
-#trunk\r?
\+trunk!\r?
|s);

$ENV{SVKRESOLVE} = 'h'; # help
is_output_like ($svk, 'sm', ['-m', 'merge to local again', '//trunk', '//local'],
                qr|NAME.*DESCRIPTION|s);

$ENV{SVKRESOLVE} = 'e'; # edit
$answer = 'a'; # accept

set_editor(<< "TMP");
\$_ = shift;
open _, ">\$_" or die \$!;
print _ "edited\\n";
TMP

is_output_like ($svk, 'sm', ['-m', 'merge to local again', '//trunk', '//local'],
                qr|G   test\.pl|);
$svk->up($copath);
is_file_content ("$copath/test.pl", "edited\n");

$svk->switch ('//trunk', $copath);
overwrite_file ("$copath/test.pl", "trunk 2!\n");
$svk->commit ('-m', 'change on trunk', $copath);
$svk->switch ('//local', $copath);
overwrite_file ("$copath/test.pl", "local 2!\n");
$svk->commit ('-m', 'change on local', $copath);

is_output_like ($svk, 'sm', ['-C', '//trunk', '//local'],
		qr|1 conflict found.|);

set_editor(<< "TMP");
\$_ = \$ARGV[6];
open _, ">\$_" or die \$!;
print _ "merged\\n";
TMP

$ENV{SVKMERGE} = $ENV{SVN_EDITOR};
$ENV{SVKRESOLVE} = 'm'; # merge
$answer = 'a'; # accept

is_output_like ($svk, 'sm', ['-m', 'merge to local again', '//trunk', '//local'],
                qr|G   test\.pl|);
$svk->up($copath);
is_file_content ("$copath/test.pl", "merged\n");

# merge deleted files interactive
$svk->switch ('//trunk', $copath);
$svk->up($copath);
overwrite_file ("$copath/foo", "trunk\n");
$svk->add ("$copath/foo");
$svk->commit ('-m', 'foo', $copath);
$svk->sm ('-m', 'merge from trunk to local', '//trunk', '//local');
$svk->delete ('-m', 'delete foo in trunk', '//trunk/foo');
$svk->switch ('//local', $copath);
$svk->up($copath);
overwrite_file ("$copath/foo", "local\n");
$svk->commit ('-m', 'change on local', $copath);

$ENV{SVKRESOLVE} = 't'; # thiers
is_output ($svk, 'sm', ['-C', '//trunk', '//local'],
	   ['Auto-merging (16, 18) /trunk to /local (base /trunk:16).',
	    'C   foo',
	    qr'New merge ticket:',
	    'Empty merge.',
	    '1 conflict found.']);
is_output ($svk, 'sm', ['-m', 'merge to local again', '//trunk', '//local'],
	   ['Auto-merging (16, 18) /trunk to /local (base /trunk:16).',
	    'D   foo',
	    qr'New merge ticket:',
	    'Committed revision 20.']);

$svk->switch ('//trunk', $copath);
$svk->up($copath);
overwrite_file ("$copath/foo", "trunk\n");
$svk->add ("$copath/foo");
$svk->commit ('-m', 'foo', $copath);
$svk->sm ('-m', 'merge from trunk to local', '//trunk', '//local');
$svk->delete ('-m', 'delete foo in trunk', '//trunk/foo');
$svk->switch ('//local', $copath);
$svk->up($copath);
overwrite_file ("$copath/foo", "local\n");
$svk->commit ('-m', 'change on local', $copath);

$ENV{SVKRESOLVE} = 'y'; # thiers
is_output_like ($svk, 'sm', ['-C', '//trunk', '//local'],
		qr|1 conflict found.|);
is_output_like ($svk, 'sm', ['-m', 'merge to local again', '//trunk', '//local'],
		qr|G   foo|);
is_file_content ("$copath/foo", "local\n");
$svk->delete ('-m', 'delete foo in local(cleanup)', '//local/foo');

$svk->switch ('//trunk', $copath);
$svk->up($copath);
overwrite_file ("$copath/foo", "trunk\n");
$svk->add ("$copath/foo");
$svk->commit ('-m', 'foo', $copath);
$svk->sm ('-m', 'merge from trunk to local', '//trunk', '//local');
$svk->delete ('-m', 'delete foo in trunk', '//trunk/foo');
$svk->switch ('//local', $copath);
$svk->up($copath);
overwrite_file ("$copath/foo", "local\n");
$svk->commit ('-m', 'change on local', $copath);

$ENV{SVKRESOLVE} = 'e'; # thiers
$answer = 'a';
set_editor(<< "TMP");
\$_ = shift;
open _, ">\$_" or die \$!;
print _ "merged\\n";
TMP
is_output_like ($svk, 'sm', ['-C', '//trunk', '//local'],
		qr|1 conflict found.|);
is_output_like ($svk, 'sm', ['-m', 'merge to local again', '//trunk', '//local'],
		qr|G   foo|);
$svk->up($copath);
is_file_content ("$copath/foo", "merged\n");
$svk->delete ('-m', 'delete foo in local(cleanup)', '//local/foo');
