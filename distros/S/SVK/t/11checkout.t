#!/usr/bin/perl -w
use Test::More tests => 69;
use strict;
use SVK::Test;
our($output, $answer);
my ($xd, $svk) = build_test();
$svk->mkdir ('-m', 'init', '//V');
$svk->mkdir ('-m', 'init', '//V-3.1');
my $tree = create_basic_tree ($xd, '//V');
my $tree2 = create_basic_tree ($xd, '//V-3.1');
my ($copath, $corpath) = get_copath ('checkout');
mkdir ($copath);
is_output_like ($svk, 'checkout', [], qr'SYNOPSIS', 'checkout - help');
is_output_like ($svk, 'checkout', ['A', 'B', 'C'], qr'SYNOPSIS', 'checkout - help');

my $cofile = __"$copath/co-root/V-3.1/A/Q/qz";
is_output_like ($svk, 'checkout', ['//', "$copath/co-root"],
		qr{A   \Q$cofile\E},
		'checkout - report path');
ok (-e "$copath/co-root/V/A/Q/qu");

$svk->checkout ('//V/A', "$copath/co-root-a");
ok (-e "$copath/co-root-a/Q/qu");

$svk->checkout ('//V/A', "$copath/co-root-deep/there");
ok (-e "$copath/co-root-deep/there/Q/qu");

$svk->checkout ('--export', '//V/A', "$copath/co-root-export");
ok (-e "$copath/co-root-export/Q/qu");

is_output ($svk, 'checkout', ['-q', '//V-3.1', "$copath/co-root-v3.1"],
	   ["Syncing //V-3.1(/V-3.1) in ".__"$corpath/co-root-v3.1 to 6."],
	   'quiet');
ok (-e "$copath/co-root-v3.1/A/Q/qu");

chdir ($copath);
$svk->checkout('//V-3.1/A', 'foo/bar');
ok (-e 'foo/bar/Q/qu');

is_output ($svk, 'update', ['foo/bar/oz'], ["Path //V-3.1/A/oz does not exist."]);
is_output ($svk, 'update', ['foo/bar'], ["Syncing //V-3.1/A(/V-3.1/A) in ".__"$corpath/foo/bar to 6."]);
is_output ($svk, 'update', [-N => -r5 => 'foo/bar/P'],
	   ['Non-recursive update not supported.']);

is_output ($svk, 'update', [-r5 => 'foo/bar/P'],
	   ["Syncing //V-3.1/A/P(/V-3.1/A/P) in ".__"$corpath/foo/bar/P to 5.",
	    __('A   foo/bar/P/pe'),
	   ]);
is_output ($svk, 'update', [-r6 => 'foo/bar/P'],
	   ["Syncing //V-3.1/A(/V-3.1/A) in ".__"$corpath/foo/bar to 6.",
	    __('D   foo/bar/P'),
	   ]);
is_output ($svk, 'st', ['foo/bar'], []);
is_output ($svk, 'revert', ['-R', 'foo/bar'], []);

$svk->checkout('-d', 'foo/bar');
rmtree ['foo'];

$svk->checkout ('//V-3.1');
ok (-e 'V-3.1/A/Q/qu');
is_output_like ($svk, 'checkout', ['//'], qr"don't know where to checkout");

is_output ($svk, 'checkout', ['//V-3.1'], ["Syncing //V-3.1(/V-3.1) in ".__"$corpath/V-3.1 to 6."], 'check same depot path became update');
overwrite_file ('some-file', 'blah blah blah');
is_output_like ($svk, 'checkout', ['//V-3.1', 'some-file'], qr'already exists');
is_output_like ($svk, 'checkout', ['//V-3.1', 'V-3.1/l2'], qr'Overlapping checkout');

$svk->checkout ('-r5', '//V-3.1', 'V-3.1-r5');
ok (-e 'V-3.1-r5/A/P/pe');

is_output ($svk, 'checkout', ['-Nr5', '//V-3.1', 'V-3.1-nr'],
	   ["Syncing //V-3.1(/V-3.1) in ".__"$corpath/V-3.1-nr to 5.",
	    __('A   V-3.1-nr/me')], 'checkout - non-recursive');

ok (!-e 'V-3.1-nr/A');
ok (-e 'V-3.1-nr/me');

is_output ($svk, 'checkout', ['//V-3.1/A/Q/qu'],
	   ["Syncing //V-3.1/A/Q/qu(/V-3.1/A/Q/qu) in ".__"$corpath/qu to 6.",
	    'A   qu']);
ok (-e 'qu');

is_output ($svk, 'checkout', ['//V-3.1/A/Q/qu', 'boo'],
	   ["Syncing //V-3.1/A/Q/qu(/V-3.1/A/Q/qu) in ".__"$corpath/boo to 6.",
	    'A   boo']);
ok (-e 'boo');

is_output ($svk, 'checkout', ['//V-3.1/A/Q', '0'],
	   ["Syncing //V-3.1/A/Q(/V-3.1/A/Q) in ".__"$corpath/0 to 6.",
	    __"A   0/qu",
	    __"A   0/qz",
	    __" U  0"]);
$svk->co (-d => '0');
is_output ($svk, 'checkout', ['//V-3.1/A/Q', "../checkout/just-q"],
	   ["Syncing //V-3.1/A/Q(/V-3.1/A/Q) in ".__"$corpath/just-q to 6.",
	    __('A   ../checkout/just-q/qu'),
	    __('A   ../checkout/just-q/qz'),
	    __(' U  ../checkout/just-q'),
	   ], 'checkout report');

is_output ($svk, 'checkout', ['//V-3.1//A/Q/', "../checkout/just-q-slash"],
	   ["Syncing //V-3.1/A/Q(/V-3.1/A/Q) in ".__"$corpath/just-q-slash to 6.",
	    __('A   ../checkout/just-q-slash/qu'),
	    __('A   ../checkout/just-q-slash/qz'),
	    __(' U  ../checkout/just-q-slash'),
	   ], 'checkout report');

is_output ($svk, 'checkout', ['//V-3.1/A/Q', "../checkout/just-q-slashco/"],
	   ["Syncing //V-3.1/A/Q(/V-3.1/A/Q) in ".__"$corpath/just-q-slashco to 6.",
	    __('A   ../checkout/just-q-slashco/qu'),
	    __('A   ../checkout/just-q-slashco/qz'),
	    __(' U  ../checkout/just-q-slashco'),
	   ], 'checkout report');


is_output_like ($svk, 'checkout', ['//V-3.1-non'],
		qr'not exist');

is_output ($svk, 'checkout', ['--list'], [
            "  Depot Path                    \tPath",
            "========================================================================",
            "  //                            \t".__("$corpath/co-root"),
            "  //V-3.1                       \t".__("$corpath/V-3.1"),
            "  //V-3.1                       \t".__("$corpath/V-3.1-nr"),
            "  //V-3.1                       \t".__("$corpath/V-3.1-r5"),
            "  //V-3.1                       \t".__("$corpath/co-root-v3.1"),
            "  //V-3.1/A/Q                   \t".__("$corpath/just-q"),
            "  //V-3.1/A/Q                   \t".__("$corpath/just-q-slash"),
            "  //V-3.1/A/Q                   \t".__("$corpath/just-q-slashco"),
            "  //V-3.1/A/Q/qu                \t".__("$corpath/boo"),
            "  //V-3.1/A/Q/qu                \t".__("$corpath/qu"),
            "  //V/A                         \t".__("$corpath/co-root-a"),
	    "  //V/A                         \t".__("$corpath/co-root-deep/there"),
            "? //V-3.1-non                   \t".__("$corpath/V-3.1-non"),
            ]);

is_output ($svk, 'checkout', ['//V-3.1/A/Q', "."],
	   ["Syncing //V-3.1/A/Q(/V-3.1/A/Q) in ".__"$corpath/Q to 6.",
	    __('A   Q/qu'),
	    __('A   Q/qz'),
	    __(' U  Q'),
	   ], 'checkout report');

is_output ($svk, 'checkout', ['--detach', '//V-3.1'], [
            __("Checkout path '$corpath/V-3.1' detached."),
            __("Checkout path '$corpath/V-3.1-nr' detached."),
            __("Checkout path '$corpath/V-3.1-r5' detached."),
            __("Checkout path '$corpath/co-root-v3.1' detached."),
            ]);

is_output ($svk, 'checkout', ['--detach', '//V-3.1'], [
            "'//V-3.1' is not a checkout path.",
            ]);

is_output ($svk, 'checkout', ['--detach', __("$corpath/boo")], [
            __("Checkout path '$corpath/boo' detached."),
            ]);

is_output ($svk, 'checkout', ['--detach', __("$corpath/boo")], [
            __("'$corpath/boo' is not a checkout path."),
            ]);

is_output ($svk, 'checkout', ['--relocate', "//V-3.1", $corpath], [
            "'//V-3.1' is not a checkout path."
            ]);

is_output ($svk, 'checkout', ['--relocate', "//V-3.1/A/Q", $corpath], [
            "'//V-3.1/A/Q' maps to multiple checkout paths."
            ]);

is_output ($svk, 'checkout', ['--relocate', "//V-3.1-non", __("$corpath/co-root-a")], [
            __("Overlapping checkout path is not supported ($corpath/co-root-a); use 'svk checkout --detach' to remove it first.")
            ]);

chdir ('co-root-a') or die $!;
is_output ($svk, 'checkout', ['--relocate', "//V-3.1"],
	   ["Do you mean svk switch //V-3.1?"],
	  );
chdir ('..');
is_output($svk, 'update', [-r3 =>'co-root-a'],
	  ['Syncing //V/A(/V/A) in '.__("$corpath/co-root-a").' to 3.',
	   __('A   co-root-a/P'),
	   __('A   co-root-a/P/pe')]);
is_output($svk, 'co', ['//V/A' =>'co-root-a'],
	  ['Syncing //V/A(/V/A) in '.__("$corpath/co-root-a").' to 6.',
	   __('D   co-root-a/P')]);

rmtree ['co-root-a'];
is_output ($svk, 'update', ['co-root-a'],
	   ["Syncing //V/A(/V/A) in ".__"$corpath/co-root-a to 6.",
	    "Checkout directory gone. Use 'checkout //V/A co-root-a' instead."]);

SKIP: {
chmod (0555, '.');
skip 'no working chmod', 1 if -w '.' || chmod_probably_useless();
is_output ($svk, 'checkout', ['//V/A', 'co-root-a'],
	   ["Syncing //V/A(/V/A) in ".__"$corpath/co-root-a to 6.",
	    "Can't create directory co-root-a for checkout: Permission denied."]);

chmod (0755, '.');
}
is_output ($svk, 'checkout', ['--relocate', "//V-3.1-non", __("$corpath/foo")], [
            "Checkout '//V-3.1-non' ".__("relocated to '$corpath/foo'.")
            ]);

is_output ($svk, 'checkout', ['--relocate', "//V-3.1-non", __("$corpath/bar")], [
            "Checkout '//V-3.1-non' ".__("relocated to '$corpath/bar'.")
            ]);

ok (!-e "$corpath/bar", '... did not create a new copath');

is_output ($svk, 'checkout', ['--relocate', __("$corpath/just-q"), __("$corpath/baz/boo")], [
            __("Checkout '$corpath/just-q' relocated to '$corpath/baz/boo'.")
            ]);

ok (-e "$corpath/baz", '... did create a new copath');

is_output ($svk, 'checkout', ['--relocate', __("$corpath/just-q"), __("$corpath/baz/boo")], [
            __("'$corpath/just-q' is not a checkout path.")
            ]);

is_output ($svk, 'checkout', ['--relocate', __("$corpath/baz/boo"), __("$corpath/baz")], [
            __("Cannot rename $corpath/baz/boo to $corpath/baz; please move it manually."),
            __("Checkout '$corpath/baz/boo' relocated to '$corpath/baz'."),
            ]);

$svk->checkout (-r5 => '//V-3.1', "3.1");
SKIP: {
chmod 0500, "3.1/B";
skip 'no working chmod', 4 if -w "3.1/B" || chmod_probably_useless();

is_sorted_output ($svk, 'up', ["3.1"],
	   ["Syncing //V-3.1(/V-3.1) in ".__"$corpath/3.1 to 6.",
	    __('D   3.1/A/P'),
	    __('    3.1/B/S - skipped'),
	    __('    3.1/B/S/P - skipped'),
	    __('    3.1/B/S/P/pe - skipped'),
	    __('    3.1/B/S/Q - skipped'),
	    __('    3.1/B/S/Q/qu - skipped'),
	    __('    3.1/B/S/Q/qz - skipped'),
	    __('    3.1/B/S/be - skipped'),
	    __('    3.1/B/fe - skipped'),
	    __('U   3.1/me'),
	    __('A   3.1/D'),
	    __('A   3.1/D/de')]);
TODO: {
local $TODO = 'unwritable subdirectory should remain old state';

is_output ($svk, 'st', ['3.1'],
	   []);
}

chmod 0700, "3.1/B";

append_file ('3.1/D/de', "foo\n\n");
$svk->ci (-m => 'change', '3.1');
append_file ('3.1/D/de', "bar\n");
chmod 0500, "3.1/D";
is_output ($svk, 'up', [-r6 => "3.1"],
	   ["Syncing //V-3.1(/V-3.1) in ".__"$corpath/3.1 to 6.",
	    __('    3.1/D/de - skipped')]);
TODO: {
local $TODO = 'unwritable subdirectory should remain old state';
is_output_like ($svk, 'diff', ['3.1'], qr'revision 7');
}

chmod 0700, "3.1/D";            # clean up

#$svk->up (-r5 => '3.1');
#warn $output;
#$svk->up (-r3 => '3.1');
#warn $output;
}

my ($copath_noexist, $corpath_noexist) = get_copath ('checkout-noexist');
mkdir ($copath_noexist);
$svk->checkout ('//V/A', "$copath_noexist/A");
rmtree [$corpath_noexist];

# note: the results of the next test have not been sanity-checked!
is_output ($svk, 'checkout', ['--list'], [
            "  Depot Path                    \tPath",
            "========================================================================",
            "  //                            \t".__("$corpath/co-root"),
            "  //V-3.1                       \t".__("$corpath/3.1"),
            "  //V-3.1/A/Q                   \t".__("$corpath/Q"),
            "  //V-3.1/A/Q                   \t".__("$corpath/baz"),
            "  //V-3.1/A/Q                   \t".__("$corpath/just-q-slash"),
            "  //V-3.1/A/Q                   \t".__("$corpath/just-q-slashco"),
            "  //V-3.1/A/Q/qu                \t".__("$corpath/qu"),
	    "  //V/A                         \t".__("$corpath/co-root-deep/there"),
            "? //V-3.1-non                   \t".__("$corpath/bar"),
            "? //V/A                         \t".__("$corpath/co-root-a"),
            "? //V/A                         \t".__("$corpath/$copath_noexist/A"),
            ]);

is_output ($svk, 'checkout', ['--detach', __("$corpath_noexist/A")], [
            __("Checkout path '$corpath_noexist/A' detached.")]);


is_output ($svk, 'checkout', ['--list'], [
            "  Depot Path                    \tPath",
            "========================================================================",
            "  //                            \t".__("$corpath/co-root"),
            "  //V-3.1                       \t".__("$corpath/3.1"),
            "  //V-3.1/A/Q                   \t".__("$corpath/Q"),
            "  //V-3.1/A/Q                   \t".__("$corpath/baz"),
            "  //V-3.1/A/Q                   \t".__("$corpath/just-q-slash"),
            "  //V-3.1/A/Q                   \t".__("$corpath/just-q-slashco"),
            "  //V-3.1/A/Q/qu                \t".__("$corpath/qu"),
	    "  //V/A                         \t".__("$corpath/co-root-deep/there"),
            "? //V-3.1-non                   \t".__("$corpath/bar"),
            "? //V/A                         \t".__("$corpath/co-root-a"),
            ]);

$answer = ['y', 'n'];
is_output ($svk, 'checkout', ['--purge'], [
#	    "Purge checkout of //V-3.1-non to non-existing directory ".__("$corpath/bar")."? (y/n) ",
            __("Checkout path '$corpath/bar' detached."),
#	    "Purge checkout of //V/A to non-existing directory ".__("$corpath/co-root-a")."? (y/n) ",
	    ]);

is_output ($svk, 'checkout', ['--list'], [
            "  Depot Path                    \tPath",
            "========================================================================",
            "  //                            \t".__("$corpath/co-root"),
            "  //V-3.1                       \t".__("$corpath/3.1"),
            "  //V-3.1/A/Q                   \t".__("$corpath/Q"),
            "  //V-3.1/A/Q                   \t".__("$corpath/baz"),
            "  //V-3.1/A/Q                   \t".__("$corpath/just-q-slash"),
            "  //V-3.1/A/Q                   \t".__("$corpath/just-q-slashco"),
            "  //V-3.1/A/Q/qu                \t".__("$corpath/qu"),
	    "  //V/A                         \t".__("$corpath/co-root-deep/there"),
            "? //V/A                         \t".__("$corpath/co-root-a"),
            ]);

# make sure we can detach multiple checkouts at once
is_output ($svk, 'checkout', ['--detach', __("$corpath/qu"), __("$corpath/Q"), __("$corpath/3.1")], [
            __("Checkout path '$corpath/qu' detached."),
            __("Checkout path '$corpath/Q' detached."),
            __("Checkout path '$corpath/3.1' detached."),
            ]);

chdir("$corpath/co-root-deep/there");
$svk->mkdir("newdir");
is_output($svk, 'st', [], ['A   newdir']);

chdir($corpath);
rename("$corpath/co-root-deep/there", "$corpath/tmp");
rmtree ["$corpath/co-root-deep"] or die $!;
rename("$corpath/tmp", "$corpath/co-root-deep");

is_output ($svk, 'checkout', ['--relocate', __("$corpath/co-root-deep/there"), __("$corpath/co-root-deep")], [
            __("Checkout '$corpath/co-root-deep/there' relocated to '$corpath/co-root-deep'."),
            ]);

chdir("$corpath/co-root-deep");
is_output($svk, 'st', [], ['A   newdir']);


