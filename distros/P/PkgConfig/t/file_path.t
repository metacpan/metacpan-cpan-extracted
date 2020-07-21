use strict;
use warnings;
use PkgConfig;
use File::Temp qw( tempdir );
use Test::More tests => 2;
use File::Spec;

my $dir = tempdir( CLEANUP => 1);

note "dir = $dir";

my $fn = File::Spec->catfile($dir, "libfoo.pc");
open my $fh, '>', $fn;
while(<DATA>) { print $fh $_ }
close $fh;

subtest 'no such file' => sub {

    plan tests => 2;
    my $pkg = PkgConfig->find( 'rubbish', file_path => File::Spec->catfile($dir, "rubbifsh.pc") );
    isa_ok $pkg, 'PkgConfig';
    like $pkg->errmsg, qr{^No such file}, "error";

};

subtest 'real file' => sub {

    plan tests => 3;
    my $pkg = PkgConfig->find( 'rubbish', file_path => File::Spec->catfile($dir, "libfoo.pc") );
    isa_ok $pkg, 'PkgConfig';

    is join(' ', $pkg->get_cflags),  '-I/opt/stuff/include -DFOO=1', 'cflags';
    is join(' ', $pkg->get_ldflags), '-L/opt/stuff/lib -lfoo',       'ldflags';
};

__DATA__
prefix=/opt/stuff
exec_prefix=${prefix}
libdir=${prefix}/lib
includedir=${prefix}/include

Name: libfoo
Description: Foo
Version: 1.2.3
URL: http://foo.bar/
Libs: -L${libdir} -lfoo
Cflags: -I${includedir} -DFOO=1
