use strict;
use warnings;
use File::chdir;
use File::Spec;
use File::Copy;
use File::Temp;
use File::Remove 'remove';

use Test::More;

plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};

plan tests => 2;

if ( $ENV{TEST_AUTHOR} ) {
    local $CWD;
    my $olddir = $CWD;
    push( @CWD, 't' );
    mkdir('install');
    push( @CWD, 'install' );
    mkdir('t');
    copy( File::Spec->catfile( $olddir, 't', '10.makefile.t' ), 't' );
    ok( -f File::Spec->catfile( $olddir, 't', 'install', 't', '10.makefile.t' ),
        'Ready for test.' );

    eval <<EOF;
use inc::Module::Install;

name     'Module-Install-Debian-Tester';

dpkg_requires 'perl' => '(=> 0.1)';
test_requires 'File::Copy' => '0.1';

WriteAll;
EOF
    ok( -f 'inc/Module/Install/Debian.pm', 'Debian.pm copied ok.' );
}

if ( -d 't/install' ) {
    remove( \1, 't/install' );
}
