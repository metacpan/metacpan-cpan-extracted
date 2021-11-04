use v5.10;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => "Pod::Coverage::Careful",
    AUTHOR           => q{Tom Christiansen <tchrist@perl.com>},
    VERSION_FROM     => "lib/Pod/Coverage/Careful.pm",
    ABSTRACT_FROM    => "lib/Pod/Coverage/Careful.pm",
    LICENSE          => "perl_5",
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.005,
    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker" => 0,
    },
    BUILD_REQUIRES => {
        "Test::More"    => 0,
        "FindBin"       => 0,
    },
    PREREQ_PM => {
        "B"                     => 0,
        "Devel::Symdump"        => 0,
        "Pod::Coverage"         => 0,
        "Test::Pod"             => 0,
        "Test::Pod::Coverage"   => 1.08,
    },
    dist  => { COMPRESS => "gzip -9f", SUFFIX => "gz", },
    clean => { FILES => "Pod-Coverage-Careful-*" },
);

__END__

