use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

my %make_params = (
    NAME             => 'System::InitD',
    AUTHOR           => 'Shamatrin Dmitriy',
    ABSTRACT         => 'Little framework for init.d scripts creation and manipulation.',
    VERSION_FROM     => 'lib/System/InitD.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    EXE_FILES        => ['script/geninitd'],
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES  => {
        'File::ShareDir'            =>  0,
        'File::ShareDir::Install'   =>  0,
        'System::Process'           =>  0.19,
    },
    BUILD_REQUIRES => {
        'Test::More'                =>  0,
        'ExtUtils::MakeMaker'       =>  0,
        'File::ShareDir'            =>  0,
        'File::ShareDir::Install'   =>  0,
        'System::Process'           =>  0.19,
        'POSIX'                     =>  0,
        'Time::HiRes'               =>  0,
    },  
    PREREQ_PM => {
        'ExtUtils::MakeMaker'       =>  0,
        'File::ShareDir'            =>  0,
        'File::ShareDir::Install'   =>  0,
        'System::Process'           =>  0.19,
        'POSIX'                     =>  0,
        'Time::HiRes'               =>  0,
    },
    TEST_REQUIRES   => {
        'ExtUtils::MakeMaker'       =>  0,
        'File::ShareDir'            =>  0,
        'File::ShareDir::Install'   =>  0,
        'System::Process'           =>  0.19,
        'POSIX'                     =>  0,
        'Time::HiRes'               =>  0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Dir-*' },
    "test" => {
        "TESTS" => "t/*.t"
    }
);

# if so, ExtUtils::MakeMaker supports META_MERGE tag
if ($ExtUtils::MakeMaker::VERSION >= 6.46) {
    $make_params{META_MERGE} = {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type    => 'git',
                web     => 'https://github.com/justnoxx/system-initd',
                url     => 'https://github.com/justnoxx/system-initd.git',
            },
        },
    };
}

WriteMakefile(%make_params);

package MY;
use File::ShareDir::Install 'postamble';
