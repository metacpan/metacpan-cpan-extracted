use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Component::IRC::Plugin::WubWubWub',
    AUTHOR              => q{Gary Warman <sirmxe@cpan.org>},
    VERSION_FROM        => 'lib/POE/Component/IRC/Plugin/WubWubWub.pm',
    ABSTRACT_FROM       => 'lib/POE/Component/IRC/Plugin/WubWubWub.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Component-IRC-Plugin-WubWubWub-*' },
);
