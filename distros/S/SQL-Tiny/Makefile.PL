use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'SQL::Tiny',
    AUTHOR           => q{Andy Lester <andy@petdance.com>},
    VERSION_FROM     => 'lib/SQL/Tiny.pm',
    ABSTRACT_FROM    => 'lib/SQL/Tiny.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010001',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        # None
    },
    META_MERGE          => {
        resources => {
            bugtracker  => 'https://github.com/petdance/sql-tiny/issues',
            license     => 'http://www.perlfoundation.org/artistic_license_2_0',
            repository  => 'git://github.com/petdance/sql-tiny.git',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SQL-Tiny-*' },
);

sub MY::postamble {
    return <<'MAKE_FRAG';
critic:
	perlcritic -1 -q -profile perlcriticrc lib/SQL/Tiny.pm t/*.t
MAKE_FRAG
}
