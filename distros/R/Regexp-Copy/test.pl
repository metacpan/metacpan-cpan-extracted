#!/usr/bin/perl

use blib;
use Storable qw( freeze thaw );
use Regexp::Copy qw(re_copy); 

use Test::More tests => 6;

ok(1,"we loaded fine...");

my $re  = qr/Hello!/;
my $re2 = qr/Goodbye!/;

re_copy( $re, $re2 );

ok( $re eq $re2, "stringified regexes are equal");

my $stored = freeze( $re );
my $relief = thaw( $stored );

ok($relief eq $re, "frozen/thawed are equal");

eval {
  re_copy( 'hello', 'goodbye' );
};
if ($@) {
  ok(1, "re_copy died on non-regexp objects");
} else {
  ok(0, "re_copy did not die on non-regexp object");
}

my $deep = { my => { your => { this => { that => bless({ this => qr/^\/(index\.html|value\.html)/ },'App') } } } };
my $clone = thaw( freeze( $deep ) );
is_deeply($clone,$deep,"deeper data structures");

my $nullre = qr//;
my $resul  = qr/I once was a fishermans son!/;
eval {
  re_copy($nullre, $resul);
};

ok($resul eq '(?-xism:)',"copied null regex");

