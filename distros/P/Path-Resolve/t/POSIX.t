use strict;
use warnings;
use lib './lib';
use Path::Resolve;
my $isWindows = $^O eq 'MSWin32';
if ($isWindows) {
    eval "use Test::More skip_all => 'posix tests'";
} else {
    eval "use Test::More";
}

use Cwd;
my $cwd = Cwd::cwd();
my $path = Path::Resolve->new();

is($path->basename('\\dir\\basename.ext'), '\\dir\\basename.ext');
is($path->basename('\\basename.ext'), '\\basename.ext');
is($path->basename('basename.ext'), 'basename.ext');
is($path->basename('basename.ext\\'), 'basename.ext\\');
is($path->basename('basename.ext\\\\'), 'basename.ext\\\\');

my $controlCharFilename = 'Icon' . chr(13);
is($path->basename('/a/b/' . $controlCharFilename),$controlCharFilename);
is($path->resolve('/aaaa/bbbb'), '/aaaa/bbbb');

my $resolveTests = [
    #arguments                                    result
    [['/var/lib', '../', 'file/'], '/var/file'],
    [['/var/lib', '/../', 'file/'], '/file'],
    [['a/b/c/', '../../..'], $cwd],
    [['.'], $cwd],
    [['/some/dir', '.', '/absolute/'], '/absolute']
];

foreach my $test (@$resolveTests) {
    my $actual = $path->resolve( @{$test->[0]} );
    my $expected = $test->[1];
    is ($actual,$expected, join ' ', @{$test->[0]});
};

#normalize tests
is($path->normalize('./fixtures///b/../b/c.js'),'fixtures/b/c.js');
is($path->normalize('/foo/../../../bar'), '/bar');
is($path->normalize('a//b//../b'), 'a/b');
is($path->normalize('a//b//./c'), 'a/b/c');
is($path->normalize('a//b//.'), 'a/b');

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

foreach my $test (@$joinTests){
    my $actual = $path->join(@{ $test->[0] });
    my $expected = $test->[1];
    is ($actual,$expected, join ', ', @{ $test->[0] } );
}

##relative tests
my $relativeTests =[
    #arguments                    result
    ['/var/lib', '/var', '..'],
    ['/var/lib', '/bin', '../../bin'],
    ['/var/lib', '/var/lib', ''],
    ['/var/lib', '/var/apache', '../apache'],
    ['/var/', '/var/lib', 'lib'],
    ['/', '/var/lib', 'var/lib']
];

foreach my $test (@$relativeTests) {
    my $actual = $path->relative($test->[0], $test->[1]);
    my $expected = $test->[2];
    is($actual,$expected);
}

#delimiter
is($path->delimiter,':');
#seperators
is($path->sep,'/');

ok($path->isAbsolute('/foo/'));
ok($path->isAbsolute('/foo'));
ok(!$path->isAbsolute('./foo/'));
ok(!$path->isAbsolute('foo/'));

done_testing(75);
