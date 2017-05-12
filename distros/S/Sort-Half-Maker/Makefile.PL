
use 5.006;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME => 'Sort::Half::Maker',
    VERSION_FROM => 'lib/Sort/Half/Maker.pm',
    PREREQ_PM => {
        'Exporter'     => 0,
        'Test::More'   => 0,
    },
    ($] >= 5.005 ? (
       ABSTRACT_FROM  => 'lib/Sort/Half/Maker.pm', # retrieve abstract from module
       AUTHOR         => 'Adriano R. Ferreira <ferreira@cpan.org>',
    ) : ()),
    ($EUMM_VERSION > 6.31 ? (
       LICENSE        => 'perl',
    ) : ()),
    ($EUMM_VERSION > 6.4501 ? (
       META_MERGE => {
           resources => {
               repository => 'http://github.com/aferreira/cpan-Sort-Half-Maker',
           }
       },
    ) : ()),

);

