use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MooseX::Callbacks',
    AUTHOR              => q{Mischa Spiegelmock <revmischa@cpan.org>},
    VERSION_FROM        => 'lib/MooseX/Callbacks.pm',
    ABSTRACT_FROM       => 'lib/MooseX/Callbacks.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Moose' => 0,
        'Try::Tiny' => 0,
        'namespace::autoclean' => 0,
    },
    META_ADD => { resources => { repository => 'git://github.com/revmischa/moosex-callbacks.git' } },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MooseX-Callbacks-*' },
);
