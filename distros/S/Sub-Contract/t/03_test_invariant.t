#-------------------------------------------------------------------
#
#   $Id: 03_test_invariant.t,v 1.6 2008/06/17 11:31:42 erwan_lemonnier Exp $
#

package My::Test;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Sub::Contract qw(contract);

my $zoulou = 3;

sub foo {
    $zoulou = $_[0];
}

sub test_invariant {
    return $zoulou == 3;
}

sub set_zoulou { $zoulou = shift }

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;

BEGIN {

    use check_requirements;
    plan tests => 10;

    use_ok("Sub::Contract",'contract');
};

contract('My::Test::foo')
    ->invariant(\&My::Test::test_invariant)
    ->enable;

# void context
eval { My::Test::foo(3) };
ok(!defined $@ || $@ eq "", "invariant passes");

eval { My::Test::foo(2) };
ok( $@ =~ /invariant fails after calling My::Test::foo/, "invariant fails after");

eval { My::Test::foo(3) };
ok( $@ =~ /invariant fails before calling My::Test::foo/, "invariant fails before");

# scalar context
My::Test::set_zoulou(3);
eval { my $s = My::Test::foo(3) };
ok(!defined $@ || $@ eq "", "invariant passes");

eval { my $s = My::Test::foo(2) };
ok( $@ =~ /invariant fails after calling My::Test::foo/, "invariant fails after");

eval { my $s = My::Test::foo(3) };
ok( $@ =~ /invariant fails before calling My::Test::foo/, "invariant fails before");

# array context
My::Test::set_zoulou(3);
eval { my @s = My::Test::foo(3) };
ok(!defined $@ || $@ eq "", "invariant passes");

eval { my @s = My::Test::foo(2) };
ok( $@ =~ /invariant fails after calling My::Test::foo/, "invariant fails after");

eval { my @s = My::Test::foo(3) };
ok( $@ =~ /invariant fails before calling My::Test::foo/, "invariant fails before");



