use strict;
use warnings;
use lib './lib';
use Path::Resolve;
use Test::More;
my $isWindows = $^O eq 'MSWin32';
my $path = Path::Resolve->new();

is($path->dirname('/a/b/'), '/a');
is($path->dirname('/a/b'), '/a');
is($path->dirname('/a'), '/');
is($path->dirname(''), '.');
is($path->dirname('/'), '/');
is($path->dirname('////'), '/');

is($path->basename(''), '');
is($path->basename('/dir/basename.ext'), 'basename.ext');
is($path->basename('/basename.ext'), 'basename.ext');
is($path->basename('basename.ext'), 'basename.ext');
is($path->basename('basename.ext/'), 'basename.ext');
is($path->basename('basename.ext//'), 'basename.ext');

is($path->extname(''), '');
is($path->extname('/path/to/file'), '');
is($path->extname('/path/to/file.ext'), '.ext');
is($path->extname('/path.to/file.ext'), '.ext');
is($path->extname('/path.to/file'), '');
is($path->extname('/path.to/.file'), '');
is($path->extname('/path.to/.file.ext'), '.ext');
is($path->extname('/path/to/f.ext'), '.ext');
is($path->extname('/path/to/..ext'), '.ext');
is($path->extname('file'), '');
is($path->extname('file.ext'), '.ext');
is($path->extname('.file'), '');
is($path->extname('.file.ext'), '.ext');
is($path->extname('/file'), '');
is($path->extname('/file.ext'), '.ext');
is($path->extname('/.file'), '');
is($path->extname('/.file.ext'), '.ext');
is($path->extname('.path/file.ext'), '.ext');
is($path->extname('file.ext.ext'), '.ext');
is($path->extname('file.'), '.');
is($path->extname('.'), '');
is($path->extname('./'), '');
is($path->extname('.file.ext'), '.ext');
is($path->extname('.file'), '');
is($path->extname('.file.'), '.');
is($path->extname('.file..'), '.');
is($path->extname('..'), '');
is($path->extname('../'), '');
is($path->extname('..file.ext'), '.ext');
is($path->extname('..file'), '.file');
is($path->extname('..file.'), '.');
is($path->extname('..file..'), '.');
is($path->extname('...'), '.');
is($path->extname('...ext'), '.ext');
is($path->extname('....'), '.');
is($path->extname('file.ext/'), '.ext');
is($path->extname('file.ext//'), '.ext');
is($path->extname('file/'), '');
is($path->extname('file//'), '');
is($path->extname('file./'), '.');
is($path->extname('file.//'), '.');

##join tests
my $joinTests =[
    # arguments                     result
    [['.', 'x/b', '..', '/b/c.js'], 'x/b/c.js'],
    [['/.', 'x/b', '..', '/b/c.js'], '/x/b/c.js'],
    [['/foo', '../../../bar'], '/bar'],
    [['foo', '../../../bar'], '../../bar'],
    [['foo/', '../../../bar'], '../../bar'],
    [['foo/x', '../../../bar'], '../bar'],
    [['foo/x', './bar'], 'foo/x/bar'],
    [['foo/x/', './bar'], 'foo/x/bar'],
    [['foo/x/', '.', 'bar'], 'foo/x/bar'],
    [['./'], './'],
    [['.', './'], './'],
    [['.', '.', '.'], '.'],
    [['.', './', '.'], '.'],
    [['.', '/./', '.'], '.'],
    [['.', '/////./', '.'], '.'],
    [['.'], '.'],
    [['', '.'], '.'],
    [['', 'foo'], 'foo'],
    [['foo', '/bar'], 'foo/bar'],
    [['', '/foo'], '/foo'],
    [['', '', '/foo'], '/foo'],
    [['', '', 'foo'], 'foo'],
    [['foo', ''], 'foo'],
    [['foo/', ''], 'foo/'],
    [['foo', '', '/bar'], 'foo/bar'],
    [['./', '..', '/foo'], '../foo'],
    [['./', '..', '..', '/foo'], '../../foo'],
    [['.', '..', '..', '/foo'], '../../foo'],
    [['', '..', '..', '/foo'], '../../foo'],
    [['/'], '/'],
    [['/', '.'], '/'],
    [['/', '..'], '/'],
    [['/', '..', '..'], '/'],
    [[''], '.'],
    [['', ''], '.'],
    [[' /foo'], ' /foo'],
    [[' ', 'foo'], ' /foo'],
    [[' ', '.'], ' '],
    [[' ', '/'], ' /'],
    [[' ', ''], ' '],
    [['/', 'foo'], '/foo'],
    [['/', '/foo'], '/foo'],
    [['/', '//foo'], '/foo'],
    [['/', '', '/foo'], '/foo'],
    [['', '/', 'foo'], '/foo'],
    [['', '/', '/foo'], '/foo']
];

##windows only tests
if ($isWindows) {
    my $joinTests2 = [
        #UNC path expected
        [['//foo/bar'], '//foo/bar/'],
        [['\\/foo/bar'], '//foo/bar/'],
        [['\\\\foo/bar'], '//foo/bar/'],
        # UNC path expected - server and share separate
        [['//foo', 'bar'], '//foo/bar/'],
        [['//foo/', 'bar'], '//foo/bar/'],
        [['//foo', '/bar'], '//foo/bar/'],
        # UNC path expected - questionable
        [['//foo', '', 'bar'], '//foo/bar/'],
        [['//foo/', '', 'bar'], '//foo/bar/'],
        [['//foo/', '', '/bar'], '//foo/bar/'],
        # UNC path expected - even more questionable
        [['', '//foo', 'bar'], '//foo/bar/'],
        [['', '//foo/', 'bar'], '//foo/bar/'],
        [['', '//foo/', '/bar'], '//foo/bar/'],
        # No UNC path expected (no double slash in first component)
        [['\\', 'foo/bar'], '/foo/bar'],
        [['\\', '/foo/bar'], '/foo/bar'],
        [['', '/', '/foo/bar'], '/foo/bar'],
        # No UNC path expected (no non-slashes in first component - questionable)
        [['//', 'foo/bar'], '/foo/bar'],
        [['//', '/foo/bar'], '/foo/bar'],
        [['\\\\', '/', '/foo/bar'], '/foo/bar'],
        [['//'], '/'],
        # No UNC path expected (share name missing - questionable).
        [['//foo'], '/foo'],
        [['//foo/'], '/foo/'],
        [['//foo', '/'], '/foo/'],
        [['//foo', '', '/'], '/foo/'],
        # No UNC path expected (too many leading slashes - questionable)
        [['///foo/bar'], '/foo/bar'],
        [['////foo', 'bar'], '/foo/bar'],
        [['\\\\\\/foo/bar'], '/foo/bar'],
        # Drive-relative vs drive-absolute paths. This merely describes the
        # status quo, rather than being obviously right
        [['c:'], 'c:.'],
        [['c:.'], 'c:.'],
        [['c:', ''], 'c:.'],
        [['', 'c:'], 'c:.'],
        [['c:.', '/'], 'c:./'],
        [['c:.', 'file'], 'c:file'],
        [['c:', '/'], 'c:/'],
        [['c:', 'file'], 'c:/file']
    ];
    push @{$joinTests}, @{$joinTests2};
}

foreach my $test (@$joinTests){
    my $actual = $path->join(@{ $test->[0] });
    my $expected = $test->[1];
    $expected =~ s/\//\\/g if $isWindows;
    is ($actual,$expected, join ', ', @{ $test->[0] } );
}

done_testing();
