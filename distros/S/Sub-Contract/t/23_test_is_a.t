#-------------------------------------------------------------------
#
#   $Id: 23_test_is_a.t,v 1.1 2009/06/03 04:40:12 erwan_lemonnier Exp $
#

package Foo;

sub new { return bless({},__PACKAGE__) }

1;

package Foo::Bar;

use base qw(Foo);

sub new { return bless({},__PACKAGE__) }

1;

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Sub::Contract qw(contract undef_or is_a);
use Carp qw(croak);

BEGIN {
    use check_requirements;
    plan tests => 11;
};

# test is_a

my $t = is_a("boo");

is(ref $t, "CODE", "is_a returns a code ref");
is(&$t(""), 0, "'' is not a boo");
is(&$t(123), 0, "123 is not a boo");
is(&$t([]), 0, "[] is not a boo");
is(&$t(bless([],'boo')), 1, "boo is a boo");
is(&$t(bless({},'boo')), 1, "boo is a boo");

# simulate an object method using undef_or and def_and
contract('bleh')
    ->in( a => is_a("Foo"),
	  b => undef_or(is_a("Foo::Bar")),
	  )
    ->enable;

sub bleh {}

my $foo = new Foo;
my $foobar = new Foo::Bar;

my @tests = (
	     [ a => $foo ], undef,
	     [ a => $foo, b => undef ], undef,
	     [ a => $foo, b => 'boo' ], "key 'b' fails its constraint",
	     [ a => 'boo', b => undef ], "key 'a' fails its constraint",
	     [ b => undef ], "key 'a' fails its constraint",
	     );

# test sub
while (@tests) {
    my @args = @{ shift @tests };
    my $err = shift @tests;
    my $args = join(", ", map({ (defined $_) ? $_ : "undef" } @args));

    eval {
	bleh(@args);
    };

    if ($err) {
	ok( $@ =~ /$err/, "bleh($args) dies" );
    } else {
	ok( !defined $@ || $@ eq '', "bleh($args) does not die" );
    }
}
