use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MojoX::Renderer::HTP',
    AUTHOR              => 'Sergey Lobin <ifitwasi@gmail.com>',
    VERSION_FROM        => 'lib/MojoX/Renderer/HTP.pm',
    ABSTRACT_FROM       => 'lib/MojoX/Renderer/HTP.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MojoX-Renderer-HTP-*' },
);
