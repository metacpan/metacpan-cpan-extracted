use 5.008;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Copy;

my $is_win = $^O =~ /MSWin/ ? 1 : 0;
my $brew = $is_win ? 'berrybrew.exe' : 'perlbrew';
my $brew_link = $is_win 
    ? 'https://github.com/stevieb9/berrybrew'
    : 'http://perlbrew.pl';
my $sep = $is_win ? ';' : ':';

if (! grep { -x "$_/$brew" } split /$sep/, $ENV{PATH}){
        warn "\n$brew can't be found; we'll install this module, but " .
             "the 'brewbuild' command won't work\n\n" .
             "You can fetch and install '$brew' here: $brew_link\n\n";
    sleep 3;
}

my $work_dir;

if ($is_win){
    $work_dir = "$ENV{USERPROFILE}/brewbuild";
}
else {
    $work_dir = "$ENV{HOME}/brewbuild";
}
if (! -d $work_dir){
    mkdir $work_dir or die $!;
}
copy "conf/brewbuild.conf-dist", $work_dir or die $!;

WriteMakefile(
    NAME             => 'Test::BrewBuild',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Test/BrewBuild.pm',
    ABSTRACT_FROM    => 'lib/Test/BrewBuild.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    EXE_FILES        => [ map "bin/$_", qw(brewbuild bbtester bbdispatch) ],
    test             => {TESTS => 't/*.t t/*/*.t'},
    MIN_PERL_VERSION => 5.010,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/p5-test-brewbuild/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/p5-test-brewbuild.git',
                web => 'https://github.com/stevieb9/p5-test-brewbuild',
            },
        },
    },
    BUILD_REQUIRES => {
        'Archive::Zip' => 0,
        'Mock::Sub' => '1.07',
    },
    PREREQ_PM => {
        'App::cpanminus' => 0,
        'Archive::Extract' => 0,
        'Capture::Tiny' => 0,
        'Config::Tiny' => 0,
        'File::Copy::Recursive' => 0,
        # 'Git::Repository' => '1.318', # doesn't work on windows
        'Logging::Simple' => '1.04',
        'LWP::Simple'   => 0,
        'MetaCPAN::Client' => 2.017000,
        'Module::Load' => 0,   # corelist since 5.9.4
        'Parallel::ForkManager' => 0,
        'Plugin::Simple' => '1.01',
        'POSIX' => 0,
        'Proc::Background' => 0,
        'Test::BrewBuild::Plugin::Author' => '0.02',
        'Test::BrewBuild::Plugin::TestAgainst' => '0.06',
        'version' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-BrewBuild-*' },
);

