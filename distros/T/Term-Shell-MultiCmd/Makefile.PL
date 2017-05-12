use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Term::Shell::MultiCmd',
    AUTHOR              => q{Josef Ezra <jezra@cpan.org>},
    VERSION_FROM        => 'lib/Term/Shell/MultiCmd.pm',
    ABSTRACT_FROM       => 'lib/Term/Shell/MultiCmd.pm',
    (eval ($ExtUtils::MakeMaker::VERSION ||0) >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'       => 0,
        'Text::ParseWords' => 0,
        'Term::ReadLine'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Term-Shell-MultiCmd-*' },
);
