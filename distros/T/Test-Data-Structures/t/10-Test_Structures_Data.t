use strict;
use warnings;
use Carp;
use English qw{-no_match_vars};
use Test::Builder::Tester tests => 2;
use Test::More;
use Test::Exception;

BEGIN {
  use_ok( q{Test::Structures::Data} );
}

my $hash_of_results = {
      row1  =>  qq{ATCACG\t1\n},
      row10 =>  qq{TAGCTT\t10\n},
      row9  =>  qq{GATCAG\t9\n},
      row8  =>  qq{ACTTGA\t8\n},
      row7  =>  qq{CAGATC\t7\n},
      row6  =>  qq{GCCAAT\t6\n},
      row5  =>  qq{ACAGTG\t5\n},
      row4  =>  qq{TGACCA\t4\n},
      row3  =>  qq{TTAGGC\t3\n},
      row2  =>  qq{CGATGT\t2\n},
      row11 =>  qq{GGCTAC\t11\n},
};

{
  test_out( qq{ok 1 - finds value} );
  is_value_found_in_hash_values( qq{ATCACG\t1\n}, $hash_of_results , q{finds value});
  test_test( q{is_value_found_in_hash_values} );
}
#{
#  test_out(  q{not ok 1 - finds value} );
#  test_diag( qr/Failed\ test\ 'finds\ value'/ );
#  test_fail(+1);
#  is_value_found_in_hash_values( qq{ATCAC\t1\n}, $hash_of_results , q{finds value});
#  test_test( q{is_value_found_in_hash_values} );
#}
1;