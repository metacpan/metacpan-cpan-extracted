use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME             => 'Role::Declare',
    VERSION_FROM     => 'lib/Role/Declare.pm',
    LICENSE          => 'artistic2',
    MIN_PERL_VERSION => '5.014',
    test             => {
        TESTS => 't/*.t',
    },
);
