#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();

# pt_sine.h and the prototype's sine.js come from one generator,
# plan_crater/prototype/gen-sine.js, so the two cannot drift. This regenerates
# the C header and compares it with the shipped one byte for byte, and FAILS
# rather than skips when node or the generator is missing.

plan tests => 2;

my $proto = "$FindBin::Bin/../../plan_crater/prototype";
my $node = $ENV{NODE} || 'node';
ok -f "$proto/gen-sine.js", 'the generator is beside this checkout';

my $fresh = `$node "$proto/gen-sine.js" --c 2>/dev/null`;
open my $fh, '<', "$FindBin::Bin/../pt_sine.h" or die "pt_sine.h: $!";
my $shipped = do { local $/; <$fh> };
close $fh;
ok length($fresh) > 1000 && $fresh eq $shipped, 'pt_sine.h is what the generator emits today';
