use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Plugin::Gravatar',
    AUTHOR              => q{"koorchik" <"koorchik@cpan.org">},
    VERSION_FROM        => 'lib/Mojolicious/Plugin/Gravatar.pm',
    ABSTRACT_FROM       => 'lib/Mojolicious/Plugin/Gravatar.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'  => '0',
        'Mojolicious' => '3.97'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojolicious-Plugin-Gravatar-*' },
    
);
