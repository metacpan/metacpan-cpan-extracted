# TEST THE MORE UNUSUAL REF vs REF SMARTMATCHES...
use v5.36;
use warnings;


use Test2::V0;

plan tests => 13;


use Switch::Right;

my $scalar       = 42;
my $other_scalar = 42;
ok   smartmatch(\$scalar, \$scalar)       => 'SCALAR vs same SCALAR';
ok ! smartmatch(\$scalar, \$other_scalar) => 'SCALAR vs other SCALAR';


format FORM =
.
format OTHER =
.

ok   smartmatch(*FORM{FORMAT}, *FORM{FORMAT})  => 'FORMAT vs same FORMAT';
ok ! smartmatch(*FORM{FORMAT}, *OTHER{FORMAT}) => 'FORMAT vs other FORMAT';


my $vstr      = v1.2.3;
my $other_vstr = v1.2.3;

ok   smartmatch(\$vstr, \$vstr)      => 'VSTRING vs same VSTRING';
ok ! smartmatch(\$vstr, \$other_vstr) => 'VSTRING vs other VSTRING';

my $var;
my $ref      = \\$var;
my $other_ref = \\$var;
my @otherref;

ok   smartmatch($ref, $ref)        => 'REF vs same REF';
ok ! smartmatch($ref, $other_ref)   => 'REF vs other REF';
ok ! smartmatch($ref, \\@otherref) => 'REF vs other other REF';


no warnings 'once';
ok   smartmatch(\*FOO, \*FOO) => 'GLOB vs same GLOB';
ok ! smartmatch(\*FOO, \*BAR) => 'GLOB vs other GLOB';


my $lvalue      = \substr($vstr,0,1);
my $other_lvalue = \substr($vstr,0,1);

ok   smartmatch($lvalue, $lvalue) => 'LVALUE vs same LVALUE';
ok ! smartmatch($lvalue, $other_lvalue) => 'LVALUE vs other LVALUE';

done_testing();

