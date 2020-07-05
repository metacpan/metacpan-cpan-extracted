use ExtUtils::MakeMaker;

use Config;

use File::Temp;
use File::Spec;

my $d_pipe = $Config{'d_pipe'};

if (!$d_pipe) {
    die "OS unsupported (\$Config{d_pipe} == $d_pipe)";
}

my $has_pipe2 = _has_pipe2();

WriteMakefile(
    NAME           => 'Sys::Pipe',
    VERSION_FROM   => 'lib/Sys/Pipe.pm',
    ABSTRACT_FROM  => 'lib/Sys/Pipe.pm',
    AUTHOR         => 'Felipe Gasper (FELIPE)',
    LICENSE        => 'perl',

    INC => join(
        q< >,
        '-Wall',
        '-I.',
        ( $has_pipe2 ? '-DSP_HAS_PIPE2' : () ),
    ),

    PREREQ_PM => {
        'XSLoader' => 0.14,
    },

    MIN_PERL_VERSION => '5.8.9',

    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::FailWarnings' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/FGasper/p5-Sys-Pipe/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/FGasper/p5-Sys-Pipe.git',
                web  => 'https://github.com/FGasper/p5-Sys-Pipe',
            },
        },

        recommends => {
        },
    },
);

sub _has_pipe2 {
    my $ccpath = $ENV{'CC'} || $Config::Config{'cc'};
    print "Your C compiler appears to be: $ccpath\n";

    my $test_c = <<END;
#define _GNU_SOURCE
#include <fcntl.h>
#include <unistd.h>

int main() {
    int fds[2];
    pipe2( fds, 0 );

    return 0;
}
END

    my $tdir = File::Temp::tempdir( CLEANUP => 1 );
    my $cpath = File::Spec->catdir( $tdir, 'check.c' );
    my $progpath = File::Spec->catdir( $tdir, 'check' );

    open my $wfh, '>', $cpath;
    print {$wfh} $test_c;
    close $wfh;

    my $cmd = "$ccpath -Wall $cpath -o $progpath";

    print "Checking to see if your system has pipe2 …$/";
    system($cmd);

    if ( -s $progpath ) {
        print "Looks like your system has pipe2. Cool!$/";
        return 1;
    }

    print "Looks like your system lacks pipe2 … :($/";
    return 0;
}
