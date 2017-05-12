use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Mojo::Command::Generate::InitScript',
    AUTHOR              => q{Anatoliy Lapitskiy <nuclon@cpan.org>},
    VERSION_FROM        => 'lib/Mojo/Command/Generate/InitScript.pm',
    ABSTRACT_FROM       => 'lib/Mojo/Command/Generate/InitScript.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojo-Command-Generate-InitScript-*' },
);
