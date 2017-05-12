use strict;
use warnings;
use ExtUtils::MakeMaker;

my %args = (
    NAME                => 'TAP::Parser::SourceHandler::PHP',
    AUTHOR              => q{Andy Lester <andy@petdance.com>},
    VERSION_FROM        => 'lib/TAP/Parser/SourceHandler/PHP.pm',
    ABSTRACT_FROM       => 'lib/TAP/Parser/SourceHandler/PHP.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Test::Harness' => 3.22,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'TAP-Parser-SourceHandler-PHP-*' },
);

$args{LICENSE} = 'artistic2' if $ExtUtils::MakeMaker::VERSION >= 6.3002;

WriteMakefile( %args );
