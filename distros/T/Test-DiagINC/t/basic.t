use strict;
use warnings;
use Test::More;
use Capture::Tiny 0.21 qw/capture/;
use File::Spec;
use Config;

my @testfiles = qw/fails.t dies.t/;
push @testfiles, 'fails_in_end.t' unless $] < 5.008;

plan tests => @testfiles * ( $] < 5.010 ? 3 : 4 );

my $tainted_run = !eval { $ENV{PATH} . kill(0) and 1 }
  and diag( __FILE__ . ' running under taint mode' );

local $ENV{AUTOMATED_TESTING} = 1;

# untaint PATH but do not unset it so we test that $^X will
# run with it just fine;  Sadly, Travis CI runs with relative
# paths in PATH so we have to make them absolute, which also
# taints them, so we untaint only after we're all done cleaning
if ($tainted_run) {
    delete $ENV{$_} for qw(IFS CDPATH ENV BASH_ENV);
    my $new_path = join(
        $Config{path_sep},
        map    { File::Spec->rel2abs($_) }
          grep { length($_) }
          split /\Q$Config{path_sep}\E/,
        $ENV{PATH}
    );
    ( $ENV{PATH} ) = $new_path =~ /(.*)/;
}

for my $file (@testfiles) {
    my ( $stdout, $stderr ) = capture {
        system(
            ( $^X =~ /(.+)/ ), # $^X is internal how can it be tainted?!
            ( $tainted_run ? (qw( -I . -I lib -T )) : () ),
            "examples/$file"
        );
    };

    like( $stderr, qr/\QListing modules from %INC/,   "$file: Saw diagnostic header" );
    like( $stderr, qr/[0-9.]+\s+ExtUtils::MakeMaker/, "$file: Saw EUMM in module list" );
    unlike( $stderr, qr/Foo/, "$file: Did not see local module Foo in module list", );

    like(
        $stderr,
        qr/Found and failed to load\s+[\w\:]*SyntaxErr/,
        "$file: Saw failed load attempt of SyntaxErr"
    ) unless $] < 5.010;
}

#
# This file is part of Test-DiagINC
#
# This software is Copyright (c) 2014 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: ts=4 sts=4 sw=4 et:
