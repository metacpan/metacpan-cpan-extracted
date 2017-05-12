use strict;
use warnings;

use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    ABSTRACT_FROM    => 'lib/Sweet/Home.pm',
    VERSION_FROM     => 'lib/Sweet/Home.pm',
    AUTHOR           => 'Gianluca Casati <fibo@cpan.org>',
    NAME             => 'Sweet::Home',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.12.0',
    META_MERGE       => {
        resources => {
            homepage   => 'https://metacpan.org/pod/Sweet::Home',
            license    => 'http://g14n.info/artistic-license',
            repository => 'https://github.com/fibo/Sweet-Home-pm',
            bugtracker => 'https://github.com/fibo/Sweet-Home-pm/issues',
        },
    },
    PREREQ_PM => {
        'File::Basename'              => '2.71',
        'File::Copy'                  => '2.05',
        'File::HomeDir'               => '1',
        'File::Path'                  => '1.05',
        'File::Remove'                => '1.52',
        'File::Spec'                  => '3.47',
        'latest'                      => '0.03',
        'Moose'                       => '2.1403',
        'MooseX::AttributeShortcuts', => '0.028',
        'MooseX::Types'               => '0.45',
        'MooseX::Types::Path::Class'  => '0.06',
        'namespace::autoclean'        => '0.24',
        'Net::SFTP::Foreign'          => '1.77',
        'Template'                    => '2.26',
        'Time::Piece'                 => '1.27',
        'UNIVERSAL::require'          => '0.18',
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    test          => { TESTS => 't/*.t' },
    TEST_REQUIRES => {
        'File::Temp'    => '0.2304',
        'Test::Compile' => '1.2.1',
        'Test::More'    => '1.001009',
        'Test::Pod'     => '1.48',
    }
);

