#!/usr/bin/perl -w
use strict;
use Test::More;
use SVK::Test;
eval { require SVN::Mirror; 1 } or plan skip_all => 'require SVN::Mirror';
plan tests => 26;

use Cwd;
use File::Path;

my ($xd, $svk) = build_test('test');
my ($copath, $corpath) = get_copath ('import');
my ($repospath, undef, $repos) = $xd->find_repos ('//', 1);

sub copath { SVK::Path::Checkout->copath($copath, @_) }

is_output_like ($svk, 'import', [], qr'SYNOPSIS', 'import - help');
is_output_like ($svk, 'import', ['foo','bar','baz'], qr'SYNOPSIS', 'import - help');

mkdir $copath;
overwrite_file ("$copath/filea", "foobarbazz");
overwrite_file ("$copath/fileb", "foobarbazz");
overwrite_file ("$copath/filec", "foobarbazz");
overwrite_file ("$copath/exe", "foobarbazz");
overwrite_file ("$copath/filea~","foobarbazz"); # Test for import honoring global ignores
mkdir "$copath/.DS_Store"; # Test for import honoring global ignores for directories
overwrite_file ("$copath/.DS_Store/ignored","foobarbazz"); # Test for import pruning trees on directories in global ignores

chmod (0755, "$copath/exe");
mkdir "$copath/dir";
overwrite_file ("$copath/dir/filed", "foobarbazz");

is_output ($svk, 'import', ['-Cm', 'test import', $copath, '//import'],
	   ['Import path //import will be created.',
	    "Directory $corpath will be imported to depotpath //import."]);
is_output ($svk, 'import', ['-m', 'test import', $copath, '//import'],
	   ['Committed revision 1.',
	    'Import path //import initialized.',
	    'Committed revision 2.',
	    "Directory $corpath imported to depotpath //import as revision 2."]);

is_output_like ($svk, 'status', [$copath], qr'not a checkout path');

overwrite_file ("$copath/filea", "foobarbazzblah");
overwrite_file ("$copath/dir/filed", "foobarbazzbozo");

unlink "$copath/fileb";

$svk->import ('-m', 'test import', '//import', $copath);
is_output ($svk, 'import', ['-m', 'test import into file', '//import/filec', $copath], 
	   [qr'^import destination cannot be a file at ']);

unlink "$copath/filec";
$svk->import ('-t', '-m', 'import -t', '//import', $copath);
ok($xd->{modified}, 'will update svk config');
is_output ($svk, 'status', [$copath], []);
rmtree [$copath];
$svk->checkout ('//import', $copath);

ok (-e copath ('filea'));
ok (!-e copath ('fileb'));
ok (!-e copath ('filec'));
ok (-e copath ('dir/filed'));
ok (_x(copath ('exe')), 'executable bit imported');
ok (!-e copath ('filea~'));
ok (!-e copath ('.DS_Store'));
ok (!-e copath ('.DS_Store/ignored'));
unlink (copath ('exe'));

my $oldwd = getcwd;
chdir ($copath);

is_output ($svk, 'import', ['//import'], ["Import source ($corpath) is a checkout path; use --from-checkout."]);

$svk->import ('-f', '-m', 'import -f', '//import');
is_output ($svk, 'status', [], []);

chdir ($oldwd);

rmtree ["$copath/dir"];

overwrite_file ("$copath/dir", "now file\n");
$svk->import ('-C', '-f', '//import', $copath);
$svk->import ('-f', '-m', 'import -f', '//import', $copath);

rmtree [$copath];
$svk->checkout ('//import', $copath);
ok (-f copath ('dir'));

my ($srepospath, $spath, $srepos) = $xd->find_repos ('/test/A', 1);
$svk->mkdir ('-m', 'init', '/test/A');
SKIP: {
skip 'SVN::Mirror not installed', 7 unless HAS_SVN_MIRROR;
my $uri = uri($srepospath.($spath eq '/' ? '' : $spath));
$svk->mirror ('//m', $uri);
$svk->sync ('//m');
is_output ($svk, 'import', ['--from-checkout', '-m', 'import into mirrored path', '//m', $copath],
	   ["Import path (/m) is different from the copath (/import)"]);
rmtree [$copath];
$svk->checkout ('//m', $copath);
overwrite_file ("$copath/filea", "foobarbazz");
waste_rev ($svk, '/test/F') for 1..10;
$svk->import ('--from-checkout', '-m', 'import into mirrored path', '//m', $copath);

is ($srepos->fs->youngest_rev, 22, 'import to remote directly');

append_file ("$copath/filea", "fnord");

$svk->import ('--from-checkout', '-m', 'import into mirrored path', '//m', $copath);

is ($srepos->fs->youngest_rev, 23, 'import to remote directly with proper base rev');

$svk->import ('--from-checkout', '-m', 'import into mirrored path', $copath, '//m');

is ($srepos->fs->youngest_rev, 24, 'import to remote directly with proper base rev');

$svk->checkout ('--detach', $copath);

is_output ($svk, 'import', ['-m', 'import into mirrored path from noncheckout', '//m/hate', $copath],
	   ["Merging back to mirror source $uri.",
	    'Merge back committed as revision 25.',
	    "Syncing $uri",
	    "Retrieving log information from 24 to 25",
	    "Committed revision 11 from revision 25.",
	    "Import path //m/hate initialized.",
	    "Merging back to mirror source $uri.",
	    "Merge back committed as revision 26.",
	    "Syncing $uri",
	    "Retrieving log information from 26 to 26",
	    "Committed revision 12 from revision 26.",
	    "Directory $corpath imported to depotpath //m/hate as revision 12."]);
our $answer = ['//m/hate'];
$svk->import (-m => 'via prompt', $copath);
is ($srepos->fs->youngest_rev, 27);

rmtree [$copath];
is_output ($svk, 'import', ['-m', 'bad copath', '//m/more', $copath],
	   [__"Path $corpath does not exist."]);

}
