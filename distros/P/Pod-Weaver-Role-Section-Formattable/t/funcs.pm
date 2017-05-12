#
# This file is part of Pod-Weaver-Role-Section-Formattable
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

# The basic framework and methodology of this test was lifted from t/basic.t
# in the Pod-Weaver distribution.

use Test::More;
use Test::Differences;
use Moose::Autobox 0.10;

use PPI;

use Pod::Elemental;
use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::Nester;

use Pod::Weaver;

my %TESTS = (
    basic => 1,
    multi => 2,
);

my $perl_document = do { local $/; <DATA> };

subtest $_ => sub {

    my $test   = $_;
    my $pcount = $TESTS{$test};

    my $in_pod   = do { local $/; open my $fh, '<', "t/$test/in.pod"; <$fh> };
    my $expected = do { local $/; open my $fh, '<', "t/$test/out.pod"; <$fh> };
    my $document = Pod::Elemental->read_string($in_pod);

    my $ppi_document  = PPI::Document->new(\$perl_document);

    my $weaver = Pod::Weaver->new_from_config({ root => "t/$test" });

    my $woven = $weaver->weave_document({
        pod_document => $document,
        ppi_document => $ppi_document,
        name         => 'Super Baby',
        version      => '3.1415',
    });

    eq_or_diff(
        $woven->as_pod_string,
        $expected,
        "exactly the pod string we wanted after weaving!",
    );

} for sort keys %TESTS;

done_testing;

__DATA__
package TestClass;
# ABSTRACT: abstract text

my $this = 'a test';
