# -*- Mode: CPerl -*-

use strict;
use warnings;

use Test::More tests => 791;

use Sort::Key::Top qw(nkeytop top rnkeytop topsort
                      nkeytopsort rnkeytopsort
                      ikeytopsort rikeytopsort
                      ukeytopsort rukeytopsort
                      nhead nkeyhead tail nkeytail
                      atpos rnkeyatpos
                      nkeypartref
                     );


my @top;

@top = nkeytop { abs $_ } 5 => 1, 2, 7, 5, 5, 1, 78, 0, -2, -8, 2;
is_deeply(\@top, [1, 2, 1, 0, -2], "nkeytop 1");


my @a = qw(cat fish bird leon penguin horse rat elephant squirrel dog);

is_deeply([top 5 => @a], [qw(cat fish bird elephant dog)], "top 1");

is_deeply([top 30 => @a], [@a], "top 1.1");

is_deeply([rnkeytop { length $_ } 3 => qw(a ab aa aac b t uu g h)], [qw(ab aa aac)], "rnkeytop 1");

is_deeply([top 5 => qw(a b ab t uu g h aa aac)], [qw(a b ab aa aac)], "top 2");

is_deeply([topsort 5 => qw(a b ab t uu g h aa aac)], [qw(a aa aac ab b)], "topsort 1");

is_deeply([rnkeytopsort { length $_ } 3 => qw(a ab aa aac b t uu g h)], [qw(aac ab aa)], "rnkeytopsort 1");

is(scalar(top 5 => @a), q(dog), "scalar top 1");

is(scalar(top 30 => @a), undef, "top 1.1");

is(scalar(rnkeytop { length $_ } 3 => qw(a ab aa aac b t uu g h)), q(aac), "scalar rnkeytop 1");

is(scalar(top 5 => qw(a b ab t uu g h aa aac)), q(aac), "scalar top 2");

is(scalar(topsort 5 => qw(a b ab t uu g h aa aac)), q(b), "scalar topsort 1");

is(scalar(rnkeytopsort { length $_ } 3 => qw(a ab aa aac b t uu g h)), q(aa), "scalar rnkeytopsort 1");

is_deeply([nkeypartref { $_ * $_ } 1 => (760, 617, -836)], [[617], [760, -836]], "nkeypartref");

my @data = map { join ('', map { ('a'..'f')[rand 6] } 0..(3 + rand  6)) } 0..1000;

for my $n (0, 1, 2, 3, 4, 10, 16, 20, 50, 100, 200, 500, 900, 990,
           996, 997, 998, 999, 1000, 1001, 1002, 1003, 1010, 1020, 2000, 4000,
           100000, 2000000, -1, -2, -3, -4, -10, -16, -20, -50, -100, -200, -500,
           -900, -990, -996, -997, -998, -999, -1000, -1001, -1002, -1003, -1010,
           -1020, -2000, -4000, -100000, -2000000 ) {

  my ($min, $max);



  if ($n >= 0) {
    $max = @data > $n ? $n - 1 : $#data;
    $min = 0;
  }
  else {
    if (@data > -$n) {
      $min = @data + $n;
      $max = $#data;
    }
    else {
      $min = 0;
      $max = $#data;
    }
  }


  # on 5.6.x perls, sort is not stable, so we have to stabilize it ourselves:
  my @ixs = sort { length($data[$a]) <=> length($data[$b]) or $a <=> $b } 0 .. $#data;
  my @sorted = @data[@ixs];

  my @rixs = sort { length($data[$b]) <=> length($data[$a]) or $a <=> $b } 0 .. $#data;
  my @rsorted = @data[@rixs];


  is_deeply([topsort $n => @data], [(sort @data)[$min..$max]], "topsort ($n)")
      or diag ("data: @data, min: $min, max: $max");

  is_deeply([nkeytopsort { length $_ } $n => @data],
            [ (@sorted)[$min..$max]], "nkeytopsort ($n)");
  is_deeply([rnkeytopsort { length $_ } $n => @data],
            [ (@rsorted)[$min..$max]], "rnkeytopsort ($n)");
  is_deeply([ikeytopsort { length $_ } $n => @data],
            [ (@sorted)[$min..$max]], "ikeytopsort ($n)");
  is_deeply([rikeytopsort { length $_ } $n => @data],
            [ (@rsorted)[$min..$max]], "rikeytopsort ($n)");
  is_deeply([ukeytopsort { length $_ } $n => @data],
            [ (@sorted)[$min..$max]], "ukeytopsort ($n)");
  is_deeply([rukeytopsort { length $_ } $n => @data],
            [ (@rsorted)[$min..$max]], "rukeytopsort ($n)");

  my $n1 = $n > 0 ? $n - 1 : $n < 0 ? $n : @data + 10;

  my $vn = (!$n || abs($n) > @data) ? undef : $sorted[$n > 0 ? $n - 1 : $n];
  my $rvn = (!$n || abs($n) > @data) ? undef : $rsorted[$n > 0 ? $n - 1 : $n];
    

  is(scalar(topsort $n => @data), (sort @data)[$n1], "scalar topsort ($n)");

  is(scalar(nkeytopsort { length $_ } $n => @data),
     $vn, "scalar nkeytopsort ($n)");

  is(scalar(rnkeytopsort { length $_ } $n => @data),
     $rvn, "scalar rnkeytopsort ($n)");

  is(scalar(ikeytopsort { length $_ } $n => @data),
     $vn, "scalar ikeytopsort ($n)");

  is(scalar(rikeytopsort { length $_ } $n => @data),
     $rvn, "scalar rikeytopsort ($n)");

  is(scalar(ukeytopsort { length $_ } $n => @data),
     $vn, "scalar ukeytopsort ($n)");

  is(scalar(rukeytopsort { length $_ } $n => @data),
     $rvn, "scalar rukeytopsort ($n)");
}

is(nhead(6, 7, 3, 8, 9, 9), 3, "nhead");
is((nkeyhead sub { length $_ }, qw(a ab aa aac b t uu uiyii)), 'a', 'nkeyhead');
is(tail(qw(a ab aa aac b t uu uiyii)), 'uu', 'tail');
is((nkeytail sub { length $_ }, qw(a ab aa aac b t uu uiyii)), 'uiyii', 'nkeytail');
is(atpos(3, qw(a ab aa aac b t uu uiyii)), 'ab', 'atpos');
is((rnkeyatpos sub { abs $_ }, 2 => -0.3, 1.1, 4, 0.1, 0.9, -2), 1.1, 'rnkeyatpos');
is((rnkeyatpos sub { abs $_ }, -2 => -0.3, 1.1, 4, 0.1, 0.9, -2), -0.3, 'rnkeyatpos neg');
