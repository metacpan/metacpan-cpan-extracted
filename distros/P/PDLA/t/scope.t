# Test if we can still do scopes ok - multiple uses etc..
# Also see that PDLA loaders get the correct symbols.
use strict;
use warnings;
use Test::More tests => 10;

package A;
our $pa;
# note "A: ",%A::,"\n";
use PDLA;

# $pa = zeroes 5,5;

# note "A: ",%A::,"\n";

$pa = zeroes 5,5;

# note "A: %A::\n";

# note "AC: ",(bless {},A)->can("zeroes"),"\n";
::ok((bless {},'A')->can("zeroes"));

package B;
use PDLA;

#note "B: ",%B::,"\n";
#note "B: ",%B::,"\n";
# $pb = zeroes 5,5;
# note "BC: ",(bless {},B)->can("zeroes"),"\n";
::ok((bless {},'B')->can("zeroes"));

package C;
use PDLA::Lite;
::ok(!((bless {},'C')->can("zeroes")));

package D;
use PDLA::Lite;
::ok(!((bless {},'D')->can("zeroes")));

package E;
use PDLA::LiteF;
::ok((bless {},'E')->can("zeroes"));

package F;
use PDLA::LiteF;
::ok((bless {},'F')->can("zeroes"));

::ok(!((bless {},'C')->can("imag")));
::ok(!((bless {},'D')->can("imag")));
::ok(!((bless {},'E')->can("imag")));
::ok(!((bless {},'F')->can("imag")));
