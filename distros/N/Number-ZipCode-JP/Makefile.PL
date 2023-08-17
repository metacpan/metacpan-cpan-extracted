use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use ExtUtils::MakeMaker;

my $eumm_version = $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME           => 'Number::ZipCode::JP',
    VERSION_FROM   => 'lib/Number/ZipCode/JP.pm',
    ABSTRACT_FROM  => 'lib/Number/ZipCode/JP.pm',
    PREREQ_PM      => +{
        'Test::More'         => 0,
        'UNIVERSAL::require' => 0,
    },
    ( $eumm_version >= 6.31 ? (LICENSE => 'perl_5') : () ),
    ( $eumm_version >= 6.46 ? (
            META_MERGE     => +{
                resources => {
                    repository => +{
                        type => 'git',
                        web  => 'https://github.com/nipotan/p5-Number-ZipCode-JP',
                        url  => 'git://github.com/nipotan/p5-Number-ZipCode-JP.git',
                    },
                    x_twitter  => 'https://twitter.com/nipotan',
                },
            }
        ) : ()
    ),
);
