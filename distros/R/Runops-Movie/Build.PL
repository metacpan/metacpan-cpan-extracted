#!perl
use 5.010_000;
use strict;
use warnings;
use Module::Build 0.26;
use Cwd ();
use File::Spec ();
use File::Temp ();

{
    my ( $fh, $name ) = File::Temp::tempfile(
        SUFFIX => '.mp4',
        UNLINK => 1,
    );

    my $cwd = Cwd::cwd();
    my $frames = File::Spec->catfile(
        $cwd,
        'data',
        'frame-%06d.png',
    );
    my $cmd = "ffmpeg -y -v 0 -qscale 5 -r 20 -b 9600 -i $frames $name";
    say "Testing: $cmd";
    system $cmd;

    if ( $?
         || ( $^O eq 'MSWin32'
              && $^E ) ) {
        say "Runops::Movie ffmpeg is required to use this module, please install it manually.";
        exit 0;
    }
}

my $build = Module::Build->new(
    module_name => 'Runops::Movie',
    dist_abstract => 'Make movies of perl guts',
    license  => 'perl',
    configure_requires => {
        'Module::Build' => '0.26',
    },
    requires => {
        perl                    => '5.10.0',

        'ExtUtils::CBuilder'    => 0,

        'Carp::Always'          => 0,
        'Runops::Trace'         => 0,
        'Internals::DumpArenas' => '0.08',
        'autodie'               => 0,
        'IPC::Run'              => 0,
        'IPC::System::Simple'   => 0,
        'Judy'                  => '0.13',
        'Inline::C'             => 0,
        'Imager'                => 0,

        # while Judy depends on Alien::Judy, I also use Judy.h directly from
        # Inline::C so I want to ensure that Judy.h is specifically available.
        'Alien::Judy'           => 0,

        # Also depend on ffmpeg, and whatever ffmpeg wants
    },
    script_files => [
        # Captures a frame stream from a program and renders it to movie
        'scripts/perl-movie',

        # Captures a frame stream from a program
        'scripts/pm-stream',

        # Renders a frame to a png
        qw[
            scripts/pm-frame-render
            scripts/pm-frame-read
            scripts/pm-frame-make-graph
            scripts/pm-frame-deparent
            scripts/pm-frame-redge
            scripts/pm-frame-sum-size
            scripts/pm-frame-names
            scripts/pm-frame-png
          ],

        # Renders a frame stream to movie
        qw[
            scripts/pm-frame-runner
            scripts/pm-frames-mp4
        ],
    ],
    ttf_files => {
        'fonts/ImUgly.ttf', 'lib/Runops/Movie/ImUgly.ttf',
    },
);
$build->add_build_element('ttf');
$build->create_build_script;
