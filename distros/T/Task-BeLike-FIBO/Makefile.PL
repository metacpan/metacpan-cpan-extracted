use strict;
use warnings;

use ExtUtils::MakeMaker 6.64;

my $meta = {
    ABSTRACT_FROM    => 'lib/Task/BeLike/FIBO.pm',
    VERSION_FROM     => 'lib/Task/BeLike/FIBO.pm',
    AUTHOR           => 'G. Casati <fibo@cpan.org>',
    NAME             => 'Task::BeLike::FIBO',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.8.0',
    META_MERGE       => {
        resources => {
            homepage   => 'https://metacpan.org/pod/Task::BeLike::FIBO',
            license    => 'http://g14n.info/artistic-license',
            repository => 'https://github.com/fibo/Task-BeLike-FIBO-pm',
            bugtracker => 'https://github.com/fibo/Task-BeLike-FIBO-pm/issues'
        },
    },
    PREREQ_PM => {
        'App::Ack'             => '2.14',
        'CPAN'                 => '2.10',
        'CPAN::Uploader'       => '0.103007',
        'ExtUtils::MakeMaker'  => '6.64',
        'Module::CoreList'     => '5',
        'Perl::Tidy'           => '20140711',
        'PPI::HTML'            => '1.08',
        'Term::ReadKey'        => '2.32',
        'Term::ReadLine::Perl' => '1.0303',
        'Test::Compile'        => '1.2.1',
        'Test::More'           => '1.001009',
        'Test::Pod'            => '1.48',
        'V'                    => '0.13'
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64'
    },
    test          => { TESTS => 't/*.t' },
    TEST_REQUIRES => {
        'Test::Compile'      => '1.2.1',
        'Test::More'         => '1.001009',
        'Test::Pod'          => '1.48'
    }
  };

if ( $^V lt 'v5.22.0' ) { $meta->{PREREQ_PM}->{'Devel::Cover'} = '1.18' };

WriteMakefile(%$meta);

