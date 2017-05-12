#!perl

use warnings;
use strict;

use Test::More tests => 13;

BEGIN{ use_ok('Ruby', qw(:DEFAULT Integer Rational Complex), -module => qw(Math)) }

ok  eval{ rb_require('rational.rb'); },  q{rb_require 'rational.rb'};
ok  eval{ rb_require('complex.rb');  },  q{rb_require 'complex.rb'};
ok !eval{ rb_require('notfound.rb'); },  q{rb_require 'notfound.rb' -> fatal};

my $i = Integer(1);
my $r = Rational($i);
my $z = sqrt(-$i); # overloaded

ok $r, "make Rational";
isa_ok $r, "Ruby::Object", "isa VALUE";
ok($r->kind_of('Rational'), "kind_of Rational");
ok($r->kind_of('Numeric'),  "kind_of Numeric");
cmp_ok $r,"==", $i, "r == i";

ok $z, "make Complex";
isa_ok $z, "Ruby::Object", "isa VALUE";
ok($z->kind_of('Complex'), "kind_of Complex");
ok($z->kind_of('Numeric'),  "kind_of Numeric");

