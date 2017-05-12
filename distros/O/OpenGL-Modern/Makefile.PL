#!perl -w
use strict;
use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;
use Config '%Config';
use Devel::CheckOS 'os_is';
use lib 'lib';
use OpenGL::Modern::NameLists::MakefileAll;
use Capture::Tiny 'capture';
use ExtUtils::Constant ();
use Devel::CheckLib 'assert_lib';

my $include = "-I. -Iinclude -Isrc";
my $libs;
my $define;
my $DYNS;

if ( os_is( 'MSWin32' ) ) {
    $libs   = '-lopengl32 -lgdi32 -lmsimg32';
    $define = "-D_WIN32",                       # XXX Platform specific
}
elsif ( os_is( 'Cygwin' ) ) {
    $libs = '-lGL -lX11';
}
elsif ( os_is( 'MacOSX' ) ) {
    $DYNS = { 'OTHERLDFLAGS' => '-framework OpenGL' };
}
else {
    $libs = '-lGL -lX11';
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile1(
    NAME          => 'OpenGL::Modern',
    VERSION_FROM  => 'lib/OpenGL/Modern.pm',
    ABSTRACT_FROM => 'lib/OpenGL/Modern.pm',            # retrieve abstract from module
    AUTHOR        => 'Chris Marshall <chm@cpan.org>',
    LICENSE       => 'perl',
    META_MERGE    => {
        "meta-spec" => { version => 2 },
        resources   => {
            repository => {
                web  => 'https://github.com/devel-chm/OpenGL-Modern',
                url  => 'https://github.com/devel-chm/OpenGL-Modern.git',
                type => 'git',
            }
        },
    },
    MIN_PERL_VERSION => '5.006',
    LIBS             => $libs,           # e.g., '-lm'
    DEFINE           => $define,
    INC              => $include,
    XSPROTOARG       => '-prototypes',
    depend           => {
        'Modern.c' => 'Modern.xs auto-xs.inc src/glew.c include/GL/glew.h include/GL/wglew.h',
    },
    $DYNS ? ( dynamic_lib => $DYNS ) : (),
);

# If you edit these definitions to change the constants used by this module,
# you will need to use the generated const-c.inc and const-xs.inc
# files to replace their "fallback" counterparts before distributing your
# changes.
my @names = OpenGL::Modern::NameLists::MakefileAll::makefile_all();

ExtUtils::Constant::WriteConstants(
    NAME         => 'OpenGL::Modern',
    NAMES        => \@names,
    DEFAULT_TYPE => 'UV',
    C_FILE       => 'const-c.inc',
    XS_FILE      => 'const-xs.inc',
);

generate_auto_xs();

sub generate_auto_xs {
    my ( $out, $err, $res ) = capture { system "perl utils/generate-XS.pl" };
    die "auto xs generation failed:\n$err" if $err;
    die "auto xs generation failed:\n$out" if $res;
    print $out;
    return;
}

sub WriteMakefile1 {    #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ( $params{BUILD_REQUIRES} and $eumm_version < 6.5503 ) {

        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM} = { %{ $params{PREREQ_PM} || {} }, %{ $params{BUILD_REQUIRES} } };
        delete $params{BUILD_REQUIRES};
    }
    if ( $params{TEST_REQUIRES} and $eumm_version < 6.64 ) {
        $params{PREREQ_PM} = { %{ $params{PREREQ_PM} || {} }, %{ $params{TEST_REQUIRES} } };
        delete $params{TEST_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION}   if $eumm_version < 6.48;
    delete $params{META_MERGE}         if $eumm_version < 6.46;
    delete $params{META_ADD}           if $eumm_version < 6.46;
    delete $params{LICENSE}            if $eumm_version < 6.31;
    delete $params{AUTHOR}             if $] < 5.005;
    delete $params{ABSTRACT_FROM}      if $] < 5.005;
    delete $params{BINARY_LOCATION}    if $] < 5.005;

    die "$@\nOS unsupported\n" if not eval { assert_lib %params; 1 };

    WriteMakefile( %params );
}
