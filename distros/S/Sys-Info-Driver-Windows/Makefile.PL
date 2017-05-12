#!/usr/bin/env perl
use strict;
use ExtUtils::MakeMaker;
use lib qw( builder );
use Build::Spec qw( mm_spec );

my %spec = mm_spec;


my $eok = eval <<'THIS_IS_SOME_IDENTIFIER';
    require My::Util;
    My::Util::write_detect_h();

THIS_IS_SOME_IDENTIFIER

die "Error compiling initialization_hook: $@\n" if $@;



WriteMakefile(
    NAME         => $spec{module_name},
    VERSION_FROM => $spec{VERSION_FROM},
    PREREQ_PM    => $spec{PREREQ_PM},
    PL_FILES     => {},
    ($] >= 5.005 ? (
    AUTHOR       => $spec{dist_author},
    ABSTRACT     => $spec{ABSTRACT},
    EXE_FILES    => $spec{EXE_FILES},
    ) : ()),
);
