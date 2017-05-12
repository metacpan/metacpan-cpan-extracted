use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojolicious::Command::generate::upstart',
    AUTHOR              => q{Anatoliy Lapitskiy <nuclon@cpan.org>},
    VERSION_FROM        => 'lib/Mojolicious/Command/generate/upstart.pm',
    ABSTRACT_FROM       => 'lib/Mojolicious/Command/generate/upstart.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojolicious-Command-generate-upstart-*' },
);
