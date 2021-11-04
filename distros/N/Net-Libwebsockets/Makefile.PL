use strict;
use warnings;

use Config;

use ExtUtils::CChecker;
use ExtUtils::PkgConfig;
use ExtUtils::MakeMaker;

my $extra_dir = $ENV{'LWS_BUILD_DIR'};

if ($extra_dir) {
    print "You say your LWS build is at $extra_dir …$/";
    print "OK. I’ll prioritize that directory when seeking LWS.$/";
}
else {
    print "In case you need it, you can define environment variable$/";
    print "LWS_BUILD_DIR to give a specific path where your LWS lives.$/";
}

print $/;

my @extra_cflags = $extra_dir ? "-I$extra_dir/include" : ();

my @extra_lddlflags = $extra_dir
    ? ( "-Wl,-rpath,$extra_dir/lib", "-L$extra_dir/lib" )
    : ()
;

local $ENV{'PKG_CONFIG_PATH'} = $extra_dir if $extra_dir;

my $PKG = 'libwebsockets';

if (!ExtUtils::PkgConfig->exists($PKG)) {
    die "Your pkg-config can’t find $PKG; aborting …\n";
}

my @pc_cflags = split m< >, ExtUtils::PkgConfig->cflags($PKG);

my @libs = split m< >, ExtUtils::PkgConfig->libs($PKG);

my @pc_lddlflags = map { $_ ? (split m< >) : () } (
    ExtUtils::PkgConfig->libs_only_L($PKG),
    ExtUtils::PkgConfig->libs_only_other($PKG),
);

my @cflags = (
    @extra_cflags,
    @pc_cflags,
);

my @lddlflags = (
    @extra_lddlflags,
    @pc_lddlflags,
);

my $cc = ExtUtils::CChecker->new( quiet => 0 );
$cc->push_extra_compiler_flags(@cflags);
$cc->push_extra_linker_flags(@lddlflags, @libs);

{
    print "Verifying LWS custom event loop support ...\n";

    my $has_event_c = <<END;
    #include <libwebsockets.h>

    int main() {
        int foo = LWS_EV_READ;
        return 0;
    }
END

    $cc->assert_compile_run(
        source => $has_event_c,
        diag => "Custom event loop support verification failed; is your Libwebsockets recent enough?",
    );
}

my $lws_has_deflate = do {
    print "Does your LWS support permessage-deflate?\n";

    my $has_deflate_c = <<END;
    #include <libwebsockets.h>

    void * funcptr = lws_extension_callback_pm_deflate;

    int main() {
        return 0;
    }
END

    my $lws_has_deflate = $cc->try_compile_run($has_deflate_c);

    if ($lws_has_deflate) {
        print "... yes!\n";
    }
    else {
        print "... apparently not. :(\n";
    }

    $lws_has_deflate;
};

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Libwebsockets',
    VERSION_FROM      => 'lib/Net/Libwebsockets.pm', # finds $VERSION
    ABSTRACT_FROM  => 'lib/Net/Libwebsockets.pm', # retrieve abstract from module
    AUTHOR         => [
        'Felipe Gasper (FELIPE)',
    ],
    LIBS              => ["@libs"],
    DEFINE            => $lws_has_deflate ? '-DNLWS_LWS_HAS_PMD' : '',
    LICENSE           => "perl_5",

    INC => "-Wall -I. --std=c99 @cflags",

    # An awful hack to accommodate the fact that otherwise
    # the created Makefile expects xshelper.o to be in the base dir:
    CCFLAGS => "$Config{'ccflags'} -o \$@",

    LDDLFLAGS => "@extra_lddlflags $Config{'lddlflags'}",

    OBJECT => [
        '$(BASEEXT)$(OBJ_EXT)',
        'nlws_courier.o',
        'nlws_frame.o',
        'nlws_logger.o',
        'nlws_perl_loop.o',
        'xshelper/xshelper.o',
    ],

    CONFIGURE_REQUIRES => {

        # In order to specify OBJECT as an array.
        'ExtUtils::MakeMaker' => 6.84,
        'ExtUtils::CChecker' => 0,
        'ExtUtils::PkgConfig' => 0,
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-Net-Libwebsockets.git',
                web => 'https://github.com/FGasper/p5-Net-Libwebsockets',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-Net-Libwebsockets/issues',
            },
        },
    },

    PREREQ_PM => {
        'Promise::XS' => 0,
        'URI::Split' => 0,
    },

    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::Deep' => 0,
        'Test::FailWarnings' => 0,
    },
);
