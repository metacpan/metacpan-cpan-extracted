use strict;
use warnings;
use lib './lib';
use Path::Resolve;
my $isWindows = $^O eq 'MSWin32';
use Cwd;
my $cwd = Cwd::cwd();
$cwd =~ s/[\\\/]+/\\/g;
if ($isWindows) {
    eval "use Test::More";
} else {
    eval "use Test::More skip_all => 'windows tests'";
}

my $path = Path::Resolve->new();

is($path->basename('\\dir\\basename.ext'), 'basename.ext');
is($path->basename('\\basename.ext'), 'basename.ext');
is($path->basename('basename.ext'), 'basename.ext');
is($path->basename('basename.ext\\'), 'basename.ext');
is($path->basename('basename.ext\\\\'), 'basename.ext');

is($path->dirname('c:\\'), 'c:\\');
is($path->dirname('c:\\foo'), 'c:\\');
is($path->dirname('c:\\foo\\'), 'c:\\');
is($path->dirname('c:\\foo\\bar'), 'c:\\foo');
is($path->dirname('c:\\foo\\bar\\'), 'c:\\foo');
is($path->dirname('c:\\foo\\bar\\baz'), 'c:\\foo\\bar');
is($path->dirname('\\'), '\\');
is($path->dirname('\\foo'), '\\');
is($path->dirname('\\foo\\'), '\\');
is($path->dirname('\\foo\\bar'), '\\foo');
is($path->dirname('\\foo\\bar\\'), '\\foo');
is($path->dirname('\\foo\\bar\\baz'), '\\foo\\bar');
is($path->dirname('c:'), 'c:');
is($path->dirname('c:foo'), 'c:');
is($path->dirname('c:foo\\'), 'c:');
is($path->dirname('c:foo\\bar'), 'c:foo');
is($path->dirname('c:foo\\bar\\'), 'c:foo');
is($path->dirname('c:foo\\bar\\baz'), 'c:foo\\bar');
is($path->dirname('\\\\unc\\share'), '\\\\unc\\share');
is($path->dirname('\\\\unc\\share\\foo'), '\\\\unc\\share\\');
is($path->dirname('\\\\unc\\share\\foo\\'), '\\\\unc\\share\\');
is($path->dirname('\\\\unc\\share\\foo\\bar'),'\\\\unc\\share\\foo');
is($path->dirname('\\\\unc\\share\\foo\\bar\\'),'\\\\unc\\share\\foo');
is($path->dirname('\\\\unc\\share\\foo\\bar\\baz'),'\\\\unc\\share\\foo\\bar');

#On windows, backspace is a path separator.
is($path->extname('.\\'), '');
is($path->extname('..\\'), '');
is($path->extname('file.ext\\'), '.ext');
is($path->extname('file.ext\\\\'), '.ext');
is($path->extname('file\\'), '');
is($path->extname('file\\\\'), '');
is($path->extname('file.\\'), '.');
is($path->extname('file.\\\\'), '.');

#path normalize tests
is($path->normalize('./fixtures///b/../b/c.js'),'fixtures\\b\\c.js');
is($path->normalize('/foo/../../../bar'), '\\bar');
is($path->normalize('a//b//../b'), 'a\\b');
is($path->normalize('a//b//./c'), 'a\\b\\c');
is($path->normalize('a//b//.'), 'a\\b');
is($path->normalize('//server/share/dir/file.ext'),'\\\\server\\share\\dir\\file.ext');

#path resolve

my $resolveTests = [
    # arguments                                    result
    [['c:/blah\\blah', 'd:/games', 'c:../a'], 'c:\\blah\\a'],
    [['c:/ignore', 'd:\\a/b\\c/d', '\\e.exe'], 'd:\\e.exe'],
    [['c:/ignore', 'c:/some/file'], 'c:\\some\\file'],
    [['d:/ignore', 'd:some/dir//'], 'd:\\ignore\\some\\dir'],
    [['.'], $cwd],
    [['//server/share', '..', 'relative\\'], '\\\\server\\share\\relative'],
    [['c:/', '//'], 'c:\\'],
    [['c:/', '//dir'], 'c:\\dir'],
    [['c:/', '//server/share'], '\\\\server\\share\\'],
    [['c:/', '//server//share'], '\\\\server\\share\\'],
    [['c:/', '///some//dir'], 'c:\\some\\dir']
];

foreach my $test (@$resolveTests) {
    my $actual = $path->resolve( @{$test->[0]} );
    my $expected = $test->[1];
    is ($actual,$expected, join ' ', @{$test->[0]});
};


##path relative tests
my $relativeTests = [
    #arguments                     result
    ['c:/blah\\blah', 'd:/games', 'd:\\games'],
    ['c:/aaaa/bbbb', 'c:/aaaa', '..'],
    ['c:/aaaa/bbbb', 'c:/cccc', '..\\..\\cccc'],
    ['c:/aaaa/bbbb', 'c:/aaaa/bbbb', ''],
    ['c:/aaaa/bbbb', 'c:/aaaa/cccc', '..\\cccc'],
    ['c:/aaaa/', 'c:/aaaa/cccc', 'cccc'],
    ['c:/', 'c:\\aaaa\\bbbb', 'aaaa\\bbbb'],
    ['c:/aaaa/bbbb', 'd:\\', 'd:\\']
];

foreach my $test (@$relativeTests) {
    my $actual = $path->relative($test->[0], $test->[1]);
    my $expected = $test->[2];
    is($actual,$expected);
}

#delimiter
is($path->delimiter,';');
#seperators
is($path->sep,'\\');

ok($path->isAbsolute('c:/foo/'));
ok($path->isAbsolute('/foo/'));
ok(!$path->isAbsolute('./foo/'));
ok(!$path->isAbsolute('foo/'));

done_testing(68);
