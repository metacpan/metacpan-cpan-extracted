#!perl

use 5.010;
use strict;
use warnings;

use Package::MoreUtil qw(
                            package_exists
                            list_package_contents
                            list_subpackages
                    );
use Test::More 0.98;

BEGIN { ok(!package_exists("cps61kDkaNlLTrdXC91"), "package_exists 1"); }

package cps61kDkaNlLTrdXC91;

our $A = 1;
our @A = ();
our %A = ();
our $B = undef;
sub A  {}
#our *C;

package main;

ok( package_exists("cps61kDkaNlLTrdXC91"), "package_exists 1b");

package cps61kDkaNlLTrdXC92::cps61kDkaNlLTrdXC93;
package cps61kDkaNlLTrdXC92::cps61kDkaNlLTrdXC93::cps61kDkaNlLTrdXC94;
package main;

ok( package_exists("cps61kDkaNlLTrdXC92"), "package_exists 2");
ok( package_exists("cps61kDkaNlLTrdXC92::cps61kDkaNlLTrdXC93"),
    "package_exists 3");

my %res = list_package_contents("cps61kDkaNlLTrdXC91");
%res = map {$_ => ref($res{$_})} keys %res;
#diag explain \%res;
is_deeply(\%res,
          {
              '$A' => 'SCALAR',
              '%A' => 'HASH',
              '*B' => '',
              '@A' => 'ARRAY',
              'A' => 'CODE'
          },
          "list_package_contents 1"
      );

is_deeply([list_subpackages("cps61kDkaNlLTrdXC92")],
           ["cps61kDkaNlLTrdXC92::cps61kDkaNlLTrdXC93"],
           "list_subpackages 1");

is_deeply([list_subpackages("cps61kDkaNlLTrdXC92")],
           ["cps61kDkaNlLTrdXC92::cps61kDkaNlLTrdXC93"],
           "list_subpackages 1");
is_deeply([list_subpackages("cps61kDkaNlLTrdXC92", 1)],
           [
               "cps61kDkaNlLTrdXC92::cps61kDkaNlLTrdXC93",
               "cps61kDkaNlLTrdXC92::cps61kDkaNlLTrdXC93::cps61kDkaNlLTrdXC94",
           ],
           "list_subpackages 2");

DONE_TESTING:
done_testing();
