use warnings;
use strict;

use Test::More tests => 12;

use Sub::Filter qw(filter_return);

sub f0 { "f0".$_[0] }
sub t0 :filter_return(f0) { "t0" }
is t0(), "f0t0";

sub f1 { "f1".$_[0] }
sub t1 :filter_return(main::f1) { "t1" }
is t1(), "f1t1";

sub p2::f2 { "f2".$_[0] }
sub f2 { die }
sub t2 :filter_return(p2::f2) { "t2" }
is t2(), "f2t2";

sub f3 { "f3".$_[0] }
sub p3::f3 { die }
sub p3::t3 :filter_return(f3) { "t3" }
is p3::t3(), "f3t3";

sub p4::f4 { "f4".$_[0] }
sub f4 { die }
{
	package p4;
	sub t4 :filter_return(f4) { "t4" }
}
is p4::t4(), "f4t4";

sub f5 { "f5".$_[0] }
sub p5::f5 { die }
{
	package p5;
	sub t5 :filter_return(main::f5) { "t5" }
}
is p5::t5(), "f5t5";

eval q{
	use Sub::Filter qw(filter_return);
	sub t6 :filter_return { "t6" }
};
like $@, qr/\Aattribute :filter_return needs a function name argument/;
eval q{
	use Sub::Filter qw(filter_return);
	sub t7 :filter_return(::foo) { "t7" }
};
like $@, qr/\Aattribute :filter_return needs a function name argument/;
eval q{
	use Sub::Filter qw(filter_return);
	sub t8 :filter_return(1foo) { "t8" }
};
like $@, qr/\Aattribute :filter_return needs a function name argument/;
eval q{
	use Sub::Filter qw(filter_return);
	sub t9 :filter_return(foo bar) { "t9" }
};
like $@, qr/\Aattribute :filter_return needs a function name argument/;

sub f10a { "f10a".$_[0] }
sub f10b { "f10b".$_[0] }
sub t10 :filter_return(f10a) :filter_return(f10b) { "t10" }
is t10(), "f10bf10at10";

sub f11 { "f11".$_[0] }
sub t11 { "t11" }
sub t11 :filter_return(f11);
is t11(), "f11t11";

1;
