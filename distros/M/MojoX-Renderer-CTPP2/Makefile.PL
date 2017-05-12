use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MojoX::Renderer::CTPP2',
    AUTHOR              => 'Victor M Elfimov <victor@sols.ru>',
    VERSION_FROM        => 'lib/MojoX/Renderer/CTPP2.pm',
    ABSTRACT_FROM       => 'lib/MojoX/Renderer/CTPP2.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Mojo'          => 0.9,
        'HTML::CTPP2'   => 2.5.12,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MojoX-Renderer-CTPP2-*' },
);
