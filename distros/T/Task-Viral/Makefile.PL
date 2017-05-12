use strict;
use warnings;

use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    ABSTRACT_FROM    => 'lib/Task/Viral.pm',
    VERSION_FROM     => 'lib/Task/Viral.pm',
    AUTHOR           => 'G. Casati <fibo@cpan.org>',
    NAME             => 'Task::Viral',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.8.0',
    META_MERGE       => {
        resources => {
            homepage   => 'https://metacpan.org/pod/Task::Viral',
            license    => 'http://g14n.info/artistic-license',
            repository => 'https://github.com/fibo/Task-Viral-pm',
            bugtracker => 'https://github.com/fibo/Task-Viral-pm/issues'
        },
    },
    PREREQ_PM => {
        'CPAN'                       => '2.10',
        'CPAN::Mini::Inject'         => '0.33',
        'CPAN::Mirror::Server::HTTP' => '0.04',
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64'
    },
    test          => {TESTS => 't/*.t'},
    TEST_REQUIRES => {
        'Test::Compile' => '1.2.1',
        'Test::More'    => '1.001009',
        'Test::Pod'     => '1.48'
    }
);

