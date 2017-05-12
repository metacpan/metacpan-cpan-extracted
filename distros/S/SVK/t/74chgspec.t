#!/usr/bin/perl -w
use Test::More tests => 1;
use strict;
use SVK::Test;

my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('cherrypicking');

$svk->checkout ('//', $copath);
mkdir "$copath/trunk";
overwrite_file ("$copath/trunk/foo", "foobar\n");
overwrite_file ("$copath/trunk/test.pl", "foobarbazzz\n");
$svk->add ("$copath/trunk");
$svk->commit ('-m', 'init', "$copath");

overwrite_file ("$copath/trunk/test.pl", q|#!/usr/bin/perl -w

sub main {
    print "this is main()\n";
#test
}

|);

$svk->commit ('-m', 'change on trunk', "$copath");

append_file ("$copath/trunk/test.pl", q|
sub test {
    print "this is test()\n";
}

|);

$svk->commit ('-m', 'more change on trunk', "$copath");

append_file ("$copath/trunk/test.pl", q|
END {
}

|);

$svk->commit ('-m', 'more change on trunk', "$copath");

$svk->propset ('someprop', 'propvalue', "$copath/trunk/test.pl");
$svk->status ($copath);
$svk->commit ('-m', 'and some prop', "$copath");

$svk->copy ('-m', 'branch //work', '//trunk', '//work');
$svk->update ($copath);

replace_file("$copath/work/test.pl", 'is main' => 'is local main');

$svk->commit ('-m', 'local mod', "$copath/work");

append_file ("$copath/trunk/test.pl", q|

# copyright etc
|);

$svk->commit ('-m', 'more mod on trunk', "$copath/trunk");

$svk->smerge ('-m', 'mergeback from //work', '//work', '//trunk');

$svk->smerge ('-m', 'mergeback from //trunk', '//trunk', '//work');

$svk->update ($copath);

replace_file("$copath/trunk/test.pl", '#!/usr/bin/' => '#!env ');

$svk->commit ('-m', 'mod on trunk before branch to featre', "$copath/trunk");

$svk->copy ('-m', 'branch //feature', '//trunk', '//feature');
$svk->update ($copath);

replace_file("$copath/work/test.pl", '^#test' => '    test();');

$svk->commit ('-m', 'call test() in main', "$copath/work");

append_file ("$copath/feature/test.pl", q|

sub newfeature {}

|);

$svk->commit ('-m', 'some new feature', "$copath/feature");

replace_file("$copath/feature/test.pl", 'newfeature' => 'newnewfeature');

$svk->commit ('-m', 'rename feature depends on c14', "$copath/feature");
append_file ("$copath/feature/test.pl", q|

sub fnord {}
|);

$svk->commit ('-m', 'more features unreleated to c14', "$copath/feature");

my (undef, undef, $repos) = $xd->find_repos ('//', 1);
my $uuid = $repos->fs->get_uuid;

is_output ($svk, 'cmerge', ['-m', 'merge change 14,16 from feature to work',
                            '-c', '14,HEAD', '//feature', '//work'],
['Committed revision 17.',
 'Merging with base /trunk 9: applying /feature 13:14.',
 'G   test.pl',
 'Merging with base /trunk 9: applying /feature 15:16.',
 'G   test.pl',
 'Committed revision 18.',
 'Committed revision 19.',
 "Auto-merging (0, 18) /feature-merge-$$ to /work (base /trunk:9).",
 'G   test.pl',
 "New merge ticket: $uuid:/feature-merge-$$:18",
 'Committed revision 20.']);

$svk->update ("$copath/work");
$svk->update ("$copath/feature");
