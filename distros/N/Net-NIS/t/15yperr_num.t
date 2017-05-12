# -*- perl -*-
#
# Test that we have access to the YPERR_xxx constants, and their values
# are what we expect.
#
# NOTE: This uses an unpublished interface to Net::NIS
#
use strict;
use Test;

my $loaded = 0;

# NOTE: this depends heavily on the fact that @Net::NIS::YPERRS
# currently (2002-02-14) consists of exactly 17 values.  If you
# ever add or remove any from that array, you must change the "34"
# below to (2 * @YPERRS), and also change this comment.
BEGIN { plan tests => 34; }
END   { $loaded or print "not ok 1\n" }

use Net::NIS qw(:all);

$loaded = 1;

# For each constant 'YPERR_XXX' defined in @YPERRS, make sure the
# function returns the value we expect to see.
for (my $i=0; $i < @Net::NIS::YPERRS; $i++) {
  my $const = $Net::NIS::YPERRS[$i];
  my $val = eval "$const()";
  ok $@, "", "Evaluation of $const";
  ok eval $val, $i, $const;
}
