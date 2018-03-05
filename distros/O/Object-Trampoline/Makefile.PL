use v5.24;
use ExtUtils::MakeMaker;

WriteMakefile
(
    qw
    (
        NAME            Object::Trampoline
        VERSION         1.50.2
        ABSTRACT_FROM   ./lib/Object/Trampoline.pm
        LICENSE         perl
    ),

    AUTHOR      => 'Steven Lembark <lembark@wrkhors.com>',
    PREREQ_PM   =>
    {
        # take whatever versions are in the standard distro.

        qw
        (
            Carp                0
            Object::Trampoline  0
            Scalar::Util        0
            Symbol              0
            Test::More          0
        )
    },

);
