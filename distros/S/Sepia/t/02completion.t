#!/usr/bin/env perl

use Test::Simple tests => 14;
use Data::Dumper;
require Sepia;
# use warnings;
no warnings;

## Set up some symbols to complete on:
package Z::A;
sub a_function { }
sub a_nother_function { }
sub xx { }
$a_var = 0;
@a_var2 = ();
%a_var3 = ();
sub Zz::A::xx { }
sub Zz::Aa::xx { }
package Z::Another;
sub a_function { }
sub a_nother_function { }
$a_var = 0;
@a_var2 = ();
%a_var3 = ();
package Z::A::Nother;
sub a_function { }
sub a_nother_function { }
$a_var = 0;
@a_var2 = ();
%a_var3 = ();
package Z::Blah;
sub a_function { }
sub a_nother_function { }
$a_var = 0;
@a_var2 = ();
%a_var3 = ();
## Whew!
package main;

sub ok_comp
{
    my ($type, $str) = splice @_, 0, 2;
    my $res = Dumper([sort(Sepia::completions($type, $str))]);
    my $expect = Dumper([sort @_]);
    my $ok = $res eq $expect;
    ok($ok, $ok ? $str : "$type/$str\n$res\n$expect\n");
}

ok_comp(qw'CODE Z:A:x', qw'&Z::A::xx');
ok_comp(qw'CODE Z:Aa:x', qw'&Zz::Aa::xx');
ok_comp(qw'CODE Zz::A:x', qw'&Zz::A::xx');
ok_comp(qw'SCALAR Z:A:a_v', qw($Z::A::a_var));
ok_comp(qw'ARRAY Z:A:a_v', qw(@Z::A::a_var2));
ok_comp(qw'HASH Z:A:a_v', qw(%Z::A::a_var3));
ok_comp(qw'HASH z:a:a_v', qw(%Z::A::a_var3 %Z::Another::a_var3));
ok_comp(qw'HASH z:a:a_', qw(%Z::A::a_var3 %Z::Another::a_var3));
ok_comp(qw'HASH z:a:a', qw(%Z::A::a_var3 %Z::Another::a_var3));
ok_comp(qw'CODE Z:A:a_v');
ok_comp(qw'CODE Z:A:a', qw(&Z::A::a_nother_function &Z::A::a_function));
ok_comp(qw'CODE z:a:a', qw(&Z::A::a_nother_function &Z::Another::a_nother_function
                    &Z::A::a_function &Z::Another::a_function));
ok_comp(qw'CODE zaa', qw(&Z::A::a_nother_function &Z::Another::a_nother_function
                    &Z::A::a_function &Z::Another::a_function));
ok_comp('', 'za', qw(Z::A:: Z::Another:: Zz::A:: Zz::Aa::));

