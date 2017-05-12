#$Id: Makefile.PL 1214 2008-02-09 23:41:58Z jimk $
use ExtUtils::MakeMaker;
require 5.008;

WriteMakefile(
    NAME            => q[Perl6::Say],
    VERSION_FROM    => q[lib/Perl6/Say.pm],
    ABSTRACT        => q['print' -- but no newline needed],
    AUTHOR          => q[Alexandr Ciornii (alexchorny@gmail.com)],
    PREREQ_PM    => {
        Test::More      => 0.44,
        IO::Handle      => 0,       # in the Perl core
        Scalar::Util    => 1.07,    # in the Perl core since 5.007003
        Carp            => 0,       # in the Perl core
    },
    PL_FILES=> {},
);
