use 5.008001;  # from Devel::Declare
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Syntax::Feature::Qn',
    VERSION_FROM => 'lib/Syntax/Feature/Qn.pm',

    NO_MYMETA => 1,

    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },

    PREREQ_PM => {
        'Devel::Declare'            => 0,
        'Syntax::Feature::Function' => 0,
    },

    TEST_REQUIRES => {
        'Test::More' => 0,
    },

    realclean => {
        FILES => [ qw(
            MANIFEST.bak
            Syntax-Feature-Qn-*.tar.gz
        ) ]
    },

    dist => {
        PREOP => 'pod2text lib/Syntax/Feature/Qn.pm > README',
    },

    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Syntax/Feature/Qn.pm',
       AUTHOR         => 'Rick Myers <jrm@cpan.org>') : ()),
);

