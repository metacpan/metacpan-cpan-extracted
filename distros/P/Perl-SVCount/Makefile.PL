use 5.014;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR => 'Rafael Garcia-Suarez <rgs@consttype.org>',
    NAME => 'Perl::SVCount',
    VERSION_FROM => 'SVCount.pm',
    LICENSE => 'perl',
    ABSTRACT => "Get global count of allocated SVs",
);
