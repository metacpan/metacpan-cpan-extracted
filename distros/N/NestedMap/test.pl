#!/usr/bin/perl -w

my $loaded;

use strict;

BEGIN { $| = 1; print "1..3\n"; }
END { print "not ok 1\n" unless $loaded; }

use NestedMap;

$loaded=1;
print "ok 1\n";

my $foo = join('',
           nestedmap sub {
             nestedmap sub {
               nestedmap sub {
                 join('',@NestedMap::stack[0..2])
               }, qw(A B C)
             }, qw(a b c)
           }, qw(1 2 3)
         );
print 'not ' unless($foo eq 'Aa1Ba1Ca1Ab1Bb1Cb1Ac1Bc1Cc1Aa2Ba2Ca2Ab2Bb2Cb2Ac2Bc2Cc2Aa3Ba3Ca3Ab3Bb3Cb3Ac3Bc3Cc3');
print "ok 2\n";

{ local $^W=0;
$foo = join('', @{ zipn( [1,2,3], [qw(a b c d)], [qw(cat dog)] )});
}
print 'not ' unless($foo eq '1acat2bdog3cd');
print "ok 3\n";

sub zipn {
           my @args = @_;
           [
             nestedmap sub {
               nestedmap sub {
                 $args[$_][$NestedMap::stack[1]]
               }, 0..$#args
             }, 0 .. max(map { $#{$_[$_]} } 0..$#args)
           ]
         }

sub max { foldl(sub { ($_[0] > $_[1]) ? $_[0] : $_[1]; }, @_); }
sub foldl {
  my($f, $z, @xs) = @_;
  $z = $f->($z, $_) foreach(@xs);
  return $z;
}
