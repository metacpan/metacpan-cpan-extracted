#!/usr/bin/perl -T

use Test::More tests => 8;

BEGIN {
    use_ok( 'String::FriendlyID' ) || print "Bail out!
";
}

my $class = 'String::FriendlyID';
my $fid = $class->new();

my $x = $fid->friendly_number('639178680102'); 
is( 
    $fid->friendly_number('639178680102'), 
    $x,    
    'generate friendly number',
);

my $y = $fid->encode('639178680102'); 
is( 
    $fid->encode('639178680102'), 
    $y,
    'encode numerical string',
);

is( 
    $fid->encode(639178680102), 
    $y,
    'encode number',
);

is(
    $fid->encode('639178680102'), 
    $fid->encode(639178680102),
    'same value, one numberic one string',
);

isnt(
    $fid->encode('639178680102'), 
    $fid->encode('639177654321'),
    'unique per string - different strings',
);

is(
    $fid->encode('abcdefg'), 
    '', 
    'non-numeric empty'
);

is(
    $fid->encode('1A2B3C'),
    '', 
    'with non-numeric'
);
