use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Perlbal::Plugin::Addheader',
    AUTHOR              => 'Bruno Martins <bruno.martins@co.sapo.pt>',
    VERSION_FROM        => 'lib/Perlbal/Plugin/Addheader.pm',
    ABSTRACT_FROM       => 'lib/Perlbal/Plugin/Addheader.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Perlbal'     => 1.72,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Perlbal-Plugin-Addheader-*' },
);
