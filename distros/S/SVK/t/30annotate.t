#!/usr/bin/perl -w
use Test::More tests => 10;
use strict;
use SVK::Test;
our $output;
my ($xd, $svk) = build_test();
my ($copath, $corpath) = get_copath ('annotate');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);
$svk->checkout ('//', $copath);

is_output_like ($svk, 'blame', ['--help'], qr'SYNOPSIS', 'annotate - help');
is_output_like ($svk, 'blame', [], qr'SYNOPSIS', 'annotate - help');

chdir ($copath);
mkdir ('A');
overwrite_file ("A/foo", "foobar\nbarbar\n");
$svk->add ('A');
$svk->commit ('-m', 'init');
overwrite_file ("A/foo", "#!/usr/bin/perl -w\nfoobar\nbarbaz\n");
$svk->commit ('-m', 'more');
overwrite_file ("A/foo", "#!/usr/bin/perl -w\nfoobar\nbarbaz\nfnord\nahh");
$svk->commit ('-m', 'and more');
overwrite_file ("A/foo", "#!/usr/bin/perl -w\nfoobar\nat checkout\nbarbaz\nfnord\nahh");

is_annotate (['A/foo'], [2,1,undef,2,3,3], 'annotate - checkout');
is_annotate (['//A/foo'], [2,1,2,3,3], 'annotate - depotpath');
is_annotate ([-r => 2, 'A/foo'], [2,1,2], 'annotate - -rN checkout');
is_annotate (['//A/foo@2'], [2,1,2], 'annotate - depotpath@rev');
is_annotate (['A/foo@2'], [2,1,undef,2,undef,undef], 'annotate - checkout@rev');

$svk->cp ('-m', 'copy', '//A/foo', '//A/bar');
$svk->update ;
is_annotate (['A/bar'], [4,4,4,4,4], 'annotate - copied not cross');
is_annotate (['-x', 'A/bar'], [2,1,2,3,3], 'annotate - copied');
$svk->mv ('-m', 'rename', '//A/foo', '//A/baz');
$svk->update ;
is_annotate (['A/baz'], [2,1,2,3,3], 'annotate - move crossed');

sub is_annotate {
    my ($arg, $annotate, $test) = @_;
    $svk->annotate (@$arg);
    my @out = map {m/(\d+).*\(/; $1}split ("\n", $output);
    splice @out, 0, 2,;
    @_ = (\@out, $annotate, $test);
    goto &is_deeply;
}
