#!perl -T

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;
use Test::Warn;
use Scalar::Andand;

warnings_are {
    lives_and {
        my $existing_pkg = 'Tester';

        ok($existing_pkg->new->isa('Tester'));
    } "\$existing_pkg->new() calls the class method";
} [], "\$existing_pkg->new() does not warn";

warnings_are {
    lives_and {
        my $existing_pkg = 'Tester';

        ok($existing_pkg->andand->new->isa('Tester'));
    } "\$existing_pkg->andand->new() calls the class method";
} [], "\$existing_pkg->andand->new() does not warn";

warnings_are {
  throws_ok {
      my $nonexistent_pkg = 'Non::Existent::Package';

      $nonexistent_pkg->new;
  } qr/^Can't locate object method "new" via package "Non::Existent::Package"/,
      "\$nonexistent_pkg->new() throws the right exception";
} [], "\$nonexistent_pkg->new() does not warn";

warnings_are {
  throws_ok {
      my $nonexistent_pkg = 'Non::Existent::Package';

      $nonexistent_pkg->andand->new;
  } qr/^Can't locate object method "new" via package "Non::Existent::Package"/,
      "\$nonexistent_pkg->andand->new() throws the right exception";
} [], "\$nonexistent_pkg->andand->new() does not warn";


package Tester;

sub new {
	return bless {};
}
