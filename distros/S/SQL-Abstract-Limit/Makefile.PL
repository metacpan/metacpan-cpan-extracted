use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile
(
    'NAME' => 'SQL::Abstract::Limit',
    'VERSION_FROM' => 'lib/SQL/Abstract/Limit.pm',
    'PREREQ_PM' => {
        'ExtUtils::MakeMaker' => '6.64',
        'DBI' => '0',
        'Data::Dumper' => '0',
        'SQL::Abstract' => '1.2',
        'Scalar::Util' => '0',
        'Test::Builder' => '0',
        'Test::Deep' => '0',
        'Test::Exception' => '0',
        'Test::More' => '0',
    },
    'AUTHOR'      => 'Alexander Becker, C<asb@cpan.org>',
    'LICENSE'     => 'perl_5',
    'INSTALLDIRS' => 'site',
    'PL_FILES' => {},
    'META_MERGE' => {
        'resources' => {
            'repository' => 'https://github.com/asb-capfan/SQL-Abstract-Limit',
        },
    },
    'MIN_PERL_VERSION' => 5.006,
);
