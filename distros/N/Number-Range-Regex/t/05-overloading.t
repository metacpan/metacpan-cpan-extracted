#!perl -w
$|++;

use strict;
use Test::More;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex qw ( range rangespec );
use Number::Range::Regex::Util;

if( has_regex_overloading() ) {
  plan tests => 493;
} else {
  plan tests => 493;
  my $yours = defined $overload::VERSION ? $overload::VERSION : '[unversioned]';
  diag "NOTE: overloading in regex context requires overload.pm version >= 1.10 (yours is $yours), will always overload as string";
}

my $er = Number::Range::Regex::Range->empty_set();
ok($er); #in boolean context, should return the object
ok($er->regex);
ok( !/^$er$/ ) for( 0,1,-1,"foo" ); #in regex context, a pattern that never matches
ok( !/$er/ ) for( 0,1,-1,"foo" ); #regex context (part 2)
if( has_regex_overloading() ) {
  ok("$er" eq $er->to_string()); #in string context, should return empty string
  ok($er->to_string() ne qr/$er/); #make sure we don't get the empty string as regex
} else {
  ok("$er" ne $er->to_string()); #in string context, we get a regex
  ok(strip_regex_bloat( "$er" ) eq strip_regex_bloat( qr/$er/ ) );
}

my $sr = Number::Range::Regex::SimpleRange->new( 2,44 );
ok($sr); #boolean context
ok( !/^$sr$/ ) for( 0,1,45 ); #regex context
ok( /^$sr$/ ) for( 2..44 ); #regex context (part 2)
ok( !$sr->contains($_) ) for( 0,1,45 ); #as an object
ok( $sr->contains($_) ) for( 2..44 ); #as an object (part 2)
if( has_regex_overloading() ) {
  ok("$sr" eq $sr->to_string()); #string context
  ok($sr->to_string() ne qr/$sr/); #make sure we don't get the rangestring as regex
} else {
  ok("$sr" ne $sr->to_string()); #in string context, we get a regex
  ok(strip_regex_bloat( "$sr" ) eq strip_regex_bloat( qr/$sr/ ) );
}

my $tr = Number::Range::Regex::TrivialRange->new( 130, 179 );
ok($tr); #boolean context
ok( !/^$tr$/ ) for( 129,180 ); #regex context
ok( /^$tr$/ ) for( 130..179 ); #regex context (part 2)
ok( !$tr->contains($_) ) for( 129,180 ); #as an object
ok( $tr->contains($_) ) for( 130..179 ); #as an object (part 2)
if( has_regex_overloading() ) {
  ok("$tr" eq $tr->to_string()); #string context
  ok($tr->to_string() ne qr/$tr/); #make sure we don't get the rangestring as regex
} else {
  ok("$tr" ne $tr->to_string()); #in string context, we get a regex
  ok(strip_regex_bloat( "$tr" ) eq strip_regex_bloat( qr/$tr/ ) );
}

my $cr = rangespec( "2..15,111..137" );
ok($cr); #boolean context
ok( !/^$cr$/ ) for( 1,16..110,138 ); #regex context
ok( /^$cr$/ ) for( 2..15,111..137 ); #regex context (part 2)
ok( !$cr->contains($_) ) for( 1,16..110,138 ); #as an object
ok( $cr->contains($_) ) for( 2..15,111..137 ); #as an object (part 2)
if( has_regex_overloading() ) {
  ok("$cr" eq $cr->to_string()); #string context
  ok($cr->to_string() ne qr/$cr/); #make sure we don't get the rangestring as regex
} else {
  ok("$cr" ne $cr->to_string()); #in string context, we get a regex
  ok(strip_regex_bloat( "$cr" ) eq strip_regex_bloat( qr/$cr/ ) );
}
