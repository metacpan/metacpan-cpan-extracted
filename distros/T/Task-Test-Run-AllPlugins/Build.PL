use strict;
use warnings;
use Module::Build ();

my $builder = Module::Build->new(
    module_name        => 'Task::Test::Run::AllPlugins',
    license            => 'mit',
    dist_author        => q{Shlomi Fish <shlomif@shlomifish.org>},
    dist_version_from  => 'lib/Task/Test/Run/AllPlugins.pm',
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires => {
        'perl'                                               => '5.008',
        'Test::Run::Core'                                    => 0,
        'Test::Run::CmdLine'                                 => 0,
        'Test::Run::CmdLine::Plugin::AlternateInterpreters'  => 0,
        'Test::Run::CmdLine::Plugin::BreakOnFailure'         => 0,
        'Test::Run::CmdLine::Plugin::ColorFileVerdicts'      => 0,
        'Test::Run::CmdLine::Plugin::ColorSummary'           => 0,
        'Test::Run::CmdLine::Plugin::TrimDisplayedFilenames' => 0,
        'Test::Run::Plugin::AlternateInterpreters'           => 0,
        'Test::Run::Plugin::BreakOnFailure'                  => 0,
        'Test::Run::Plugin::ColorFileVerdicts'               => 0,
        'Test::Run::Plugin::ColorSummary'                    => 0,
        'Test::Run::Plugin::TrimDisplayedFilenames'          => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup     => ['Task-Test-Run-AllPlugins-*'],
    create_makefile_pl => 'traditional',
    meta_merge         => {
        resources => {
            repository => "http://bitbucket.org/shlomif/perl-test-run",
            homepage   => "http://web-cpan.shlomifish.org/modules/Test-Run/",
        },
        keywords => [
            "back-end",     "harness",
            "prove",        "qa",
            "QA",           "quality assurance",
            "run",          "runprove",
            "tap",          "TAP",
            "TAP::Harness", "test",
            "testing",
        ],
    },
);

$builder->create_build_script();
