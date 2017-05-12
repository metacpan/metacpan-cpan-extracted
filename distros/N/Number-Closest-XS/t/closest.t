use Test::Most 0.22;
use Number::Closest::XS ':all';
use Config;

subtest find_closest_numbers => sub {
    eq_or_diff find_closest_numbers( 50, [ 10, 20, 30 ] ), [30], "30 is closest to 50";
    eq_or_diff find_closest_numbers( 50, [ 10, 20, 30, 40, 52, ] ), [52], "now 52 is closest to 50";
    eq_or_diff(
        find_closest_numbers( 50, [ 10, 20, 30, 49, 52, ], 3, ),
        [ 49, 52, 30 ],
        "got three closest numbers sorted by distance"
    );
    eq_or_diff(
        find_closest_numbers( 50, [ 52, 49, 21, 35 ], 5, ),
        [ 49, 52, 35, 21 ],
        "got four closest numbers sorted by distance"
    );
    eq_or_diff(
        find_closest_numbers( 50, [ 52, 49, 50, 21, 35 ], 3, ),
        [ 50, 49, 52 ],
        "got three closest numbers including center point"
    );
    eq_or_diff(
        find_closest_numbers( 50, [ 49, 48, 52, 36, 48, 40 ], 4 ),
        [ 49, 48, 52, 48 ],
        "duplicate numbers are duplicated in result"
    );
    eq_or_diff(
        find_closest_numbers('1.3', [ qw(1.7 1.54 1.11 0.21 Infinity NaN) ], 2),
        [qw(1.11 1.54)],
        "strings are coersed to numbers"
    );
    eq_or_diff(
        find_closest_numbers(10, [8, 11, 7, 9, 12], 5),
        [11, 9, 8, 12, 7],
        "sort is stable"
    );
    eq_or_diff(
        find_closest_numbers(10, [9, 11, 7, 12, 8], 5),
        [9, 11, 12, 8, 7],
        "sort is stable"
    );
};

subtest find_closest_numbers_around => sub {
    eq_or_diff find_closest_numbers_around( 50, [ 10, 20, 30, 40, ] ), [ 30, 40 ],
      "30 and 40 are closest around 50";
    eq_or_diff find_closest_numbers_around( 50, [ 20, 30, 40, 52, 55, ] ), [ 40, 52 ],
      "40 and 52 are closest around 50";
    eq_or_diff find_closest_numbers_around( 50, [ 20, 30, 40, 52, 55, 57, 59, ], 3, ),
      [ 40, 52, 55 ], "40, 52 and 55 are closest three around 50";
    eq_or_diff find_closest_numbers_around( 50, [ 20, 30, 40, 52, 55, 57, 59, 60, ], 4, ),
      [ 30, 40, 52, 55 ], "30, 40, 52, and 55 are closest four around 50";
    eq_or_diff find_closest_numbers_around( 50, [ 20, 30, 40, 42, 47, 49, 52, 55, 57, 59, 60, ], 5,
    ), [ 47, 49, 52, 55, 57 ], "47, 49, 52, 55 and 57 are closest five around 50";
    eq_or_diff find_closest_numbers_around( 50, [ 10, 20, 30, 40, ], 10 ), [ 10, 20, 30, 40 ],
      "returned all closest points when amount is bigger than number of points";
};

subtest precision => sub {
  SKIP: {
        skip "Test requires perl with 64bit integers", 1 unless $Config{use64bitint};
        eq_or_diff find_closest_numbers( 50,
            [ 37834034037159587, 37834034037159589, 37834034037159585 ], 2 ),
          [ 37834034037159585, 37834034037159587 ], "correct result with 64 bit integers";
        eq_or_diff find_closest_numbers_around( 37834034037159581,
            [ 37834034037159587, 37834034037159589, 37834034037159585, 37834034037159578 ], 2 ),
          [ 37834034037159578, 37834034037159585 ], "correct result with 64 bit integers";
        eq_or_diff find_closest_numbers( 18446744073709551610,
            [ 18446744073709551615, 18446744073709551612, 18446744073709551609 ], 2 ),
          [ 18446744073709551609, 18446744073709551612 ],
          "correct result with unsigned 64 bit integers";
    };
  SKIP: {
        skip "Test requires perl with long double", 1 unless $Config{uselongdouble};
        eq_or_diff [ map { sprintf "%.18Lf", $_ }
              @{ find_closest_numbers( 10 + 6e-18, [ 10 + 1e-18, 10 + 7e-18 ] ) } ],
          ["10.000000000000000007"], "correct result with long double";
        eq_or_diff [
            map { sprintf "%.18Lf", $_ } @{
                find_closest_numbers_around(
                    10 + 6e-18, [ 10 + 1e-18, 10 + 7e-18, 10 + 3e-18 ], 2
                )
            }
          ],
          [ "10.000000000000000003", "10.000000000000000007" ], "correct result with long double";
    };
    unless(Test::More->builder->is_passing) {
        diag <<EOT
#############################################################
Failure of the precision test indicates the problem described
in CAVEATS section of the module documentation. You still can
install and use module by forcing install or skipping tests,
but check documentation to find out what limitations this
module has on this platform.
#############################################################
EOT
    }
};

done_testing;
