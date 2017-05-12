#
# $Id$
#

use strict;
use warnings;
use lib 'inc';

use Devel::PPPort;
use File::Copy;
use File::Spec;
use Getopt::Long;
use Module::Build;

# parse command line args
my %opts = ( prompt => 1 );
GetOptions( \%opts, 'prompt!' );

my $inc_dir;
my $lib_dir;

# possible prefixes where we might find libwrap.a
# if you know of other common ones please let me know
my @prefixes = (
    map { File::Spec->catdir($_) } @ARGV,
    File::Spec->catdir( File::Spec->rootdir, 'usr' ),
    File::Spec->catdir( File::Spec->rootdir, 'usr', 'local' ),
    File::Spec->catdir( File::Spec->rootdir, 'opt' ),
    File::Spec->catdir( File::Spec->rootdir, 'opt', 'local' ),
    File::Spec->catdir( File::Spec->rootdir, 'opt', 'libwrap' ),
    File::Spec->catdir( File::Spec->rootdir, 'opt', 'tcpwrappers' ),
);

# try to figure out where libwrap.a is
for my $prefix( @prefixes ) {
    for my $libname( qw|libwrap.so libwrap.a| ) {
        my $candidate = File::Spec->catfile( $prefix, 'lib', $libname );
        if( -e $candidate && -f _ && -r _ ) {
            if( $opts{prompt} ) {
                my $y_n = Module::Build->y_n(
                    "do you want to link against $candidate?", "y"
                );
                if( $y_n ) {
                    $lib_dir = File::Spec->catdir( $prefix, 'lib' );
                    last;
                }
            }
            else {
                print "prompting is off; linking against $candidate\n";
                $lib_dir = File::Spec->catdir( $prefix, 'lib' );
                last;
            }
        }
    }
}

# try to figure out where tcpd.h is
for my $prefix( @prefixes ) {
    my $candidate = File::Spec->catfile( $prefix, 'include', 'tcpd.h' );
    if( -e $candidate && -f _ && -r _ ) {
        if( $opts{prompt} ) {
            my $y_n = Module::Build->y_n(
                "do you want to use $candidate as your header?", "y"
            );
            if( $y_n ) {
                $inc_dir = File::Spec->catdir( $prefix, 'include' );
                last;
            }
        }
        else {
            print "prompting is off; using $candidate for header\n";
            $inc_dir = File::Spec->catdir( $prefix, 'include' );
            last;
        }
    }
}

# if we can't find it, prompt unless told not to
unless( $inc_dir ) {
    if( $opts{prompt} ) {
        $inc_dir = Module::Build->prompt(
            "enter include directory to use:",
            File::Spec->catdir($prefixes[0], 'include')
        );
    }
    else {
        die "cannot determine include directory and prompting is off!\n";
    }
}
unless( $lib_dir ) {
    if( $opts{prompt} ) {
        $lib_dir = Module::Build->prompt(
            "enter library directory to use:",
            File::Spec->catdir($prefixes[0], 'lib')
        );
    }
    else {
        die "cannot determine library directory and prompting is off!\n";
    }
}

# create ppport.h
my @fallback_files;
eval "use Devel::PPPort";
if( $@ ) {
    push @fallback_files, 'ppport.h';
}
else {
    Devel::PPPort::WriteFile('lib/Net/ppport.h');
}

# create constant include files
eval "use ExtUtils::Constant";
if( $@ ) {
    push @fallback_files, qw|const-c.inc const-xs.inc|;
}
else {
    # If you edit these definitions to change the constants used by this module,
    # you will need to use the generated const-c.inc and const-xs.inc
    # files to replace their "fallback" counterparts before distributing your
    # changes.
    my $names = [ qw|
        AC_DENY AC_ERROR AC_PERMIT RQ_CLIENT_ADDR RQ_CLIENT_NAME
        RQ_CLIENT_SIN RQ_DAEMON RQ_FILE RQ_SERVER_ADDR RQ_SERVER_NAME
        RQ_SERVER_SIN RQ_USER
    | ];
    ExtUtils::Constant::WriteConstants(
        NAME         => 'Net::TCPwrappers',
        NAMES        => $names,
        DEFAULT_TYPE => 'IV',
        C_FILE       => 'lib/Net/const-c.inc',
        XS_FILE      => 'lib/Net/const-xs.inc',
    );
}

for my $file( @fallback_files ) {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
}

# create the Buildfile
Module::Build->new(

    module_name          => 'Net::TCPwrappers',

    dist_version_from    => 'lib/Net/TCPwrappers.pm',

    license              => 'perl',

    build_requires       => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },

    add_to_cleanup       => [ qw|
        lib/Net/ppport.h
        lib/Net/const-xs.inc
        lib/Net/const-c.inc
    | ],

    create_makefile_pl   => 'passthrough',

    create_readme        => 1,

    extra_compiler_flags => "-I$inc_dir",

    extra_linker_flags   => [ "-L$lib_dir", "-lwrap" ]

)->create_build_script;

#
# EOF
