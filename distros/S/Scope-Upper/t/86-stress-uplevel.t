#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner;

use Scope::Upper qw<uplevel HERE UP SUB CALLER>;

my $n = 1_000;

plan tests => 3 + $n * (6 + 3);

my $period1 = 100;
my $period2 = 10;
my $shift   = 10;
my $amp     = 10;

sub PI () { CORE::atan2(0, -1) }

sub depth {
 my $depth = 0;
 while (1) {
  my @c = caller($depth);
  last unless @c;
  ++$depth;
 }
 return $depth - 1;
}

sub cap {
 my ($depth, $top) = @_;

 $depth <= 0 ? 1
             : $depth >= $top ? $top - 1
                              : $depth;
}

sub base_depth {
 cap($shift + int($amp * sin(2 * PI * $_[0] / $period1)), 2 * $shift + 1);
}

sub uplevel_depth {
 my ($base_depth, $i) = @_;

 my $h = int($base_depth / 2);

 cap($h + int($h * sin(2 * PI * $i / $period2)), $base_depth);
}

sub rec_basic {
 my ($base_depth, $uplevel_depth, $desc, $i) = @_;
 if ($i < $base_depth) {
  $i, rec_basic($base_depth, $uplevel_depth, $desc, $i + 1);
 } else {
  is depth(), $base_depth+1, "$desc: depth before uplevel";
  my $ret = uplevel {
   is depth(), $base_depth+1-$uplevel_depth, "$desc: depth inside uplevel";
   is "@_", "$base_depth $uplevel_depth",  "$desc: arguments";
   -$uplevel_depth;
  } @_[0, 1], CALLER($uplevel_depth);
  is depth(), $base_depth+1, "$desc: depth after uplevel";
  $ret;
 }
}

sub rec_die {
 my ($base_depth, $uplevel_depth, $desc, $i) = @_;
 if ($i < $base_depth) {
  local $@;
  my $ret;
  if ($i % 2) {
   $ret = eval q<
    rec_die($base_depth, $uplevel_depth, $desc, $i + 1)
   >
  } else {
   $ret = eval {
    rec_die($base_depth, $uplevel_depth, $desc, $i + 1)
   }
  }
  return $@ ? $@
            : $ret ? $ret
                   : undef;
 } else {
  my $cxt = SUB;
  {
   my $n = $uplevel_depth;
   while ($n) {
    $cxt = SUB UP $cxt;
    $n--;
   }
  }
  my $ret = uplevel {
   is HERE, $cxt, "$desc: context inside uplevel";
   die "XXX @_";
  } @_[0, 1], $cxt;
  $ret;
 }
}

my $die_line = __LINE__-6;

is depth(),                           0, 'check top depth';
is sub { depth() }->(),               1, 'check subroutine call depth';
is do { local $@; eval { depth() } }, 1, 'check eval block depth';

for my $i (1 .. $n) {
 my $base_depth    = base_depth($i);
 my $uplevel_depth = uplevel_depth($base_depth, $i);

 {
  my $desc = "basic $base_depth $uplevel_depth";

  my @ret = rec_basic($base_depth, $uplevel_depth, $desc, 0);
  is depth(), 0, "$desc: depth outside";
  is_deeply \@ret, [ 0 .. $base_depth-1, -$uplevel_depth ],
                                                       "$desc: returned values";
 }

 {
  ++$base_depth;
  my $desc = "die $base_depth $uplevel_depth";

  my $err = rec_die($base_depth, $uplevel_depth, $desc, 0);
  is depth(), 0, "$desc: depth outside";
  like $err, qr/^XXX $base_depth $uplevel_depth at \Q$0\E line $die_line/,
                                                         "$desc: correct error";
 }
}
