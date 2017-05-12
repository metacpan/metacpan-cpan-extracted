use warnings;
use strict;

use Data::Integer 0.003 qw(min_sint max_uint hex_natint);
use Test::More tests => 1 + 3 + 4*22 + 5*8 + 6*2;

do "t/num_forms.pl" or die $@ || $!;

BEGIN { use_ok "Scalar::Number", qw(scalar_num_part sclnum_id_cmp); }

foreach my $nzero (0, +0.0, -0.0) {
	my $tzero = $nzero;
	scalar_num_part($tzero);
	is zpat($tzero), zpat($nzero);
}

sub match($$) {
	my $nwarn = 0;
	local $SIG{__WARN__} = sub { $nwarn++; };
	my $num_part = scalar_num_part($_[0]);
	ok sclnum_id_cmp($num_part, $_[1]) == 0;
	ok +(my $tn = $num_part) == (my $tc = $_[1]);
	if((my $t = $_[1]) == 0) {
		my $tn = $num_part;
		my $tc = $_[1];
		is zpat($tn), zpat($tc);
	} else {
		ok 1;
	}
	is $nwarn, 0;
}

match 0, 0;
match +0.0, +0.0;
match -0.0, -0.0;
match 1, 1;
match 1.5, 1.5;
match -3, -3;
match -3.25, -3.25;
match "123abc", 123;
match "1.25", 1.25;

match "00", "0";
match "0 but true", "0";
match *match, +0.0;
match undef, +0.0;

match "0.0", "0.0";
match "+0.0", "+0.0";
match "-0.0", "-0.0";
match "0", "0";
match "+0", "+0";
match "-0", "-0";

SKIP: {
	eval { require Scalar::Util };
	skip "dualvar() not available", 4*2 if $@ ne "";
	match Scalar::Util::dualvar(123, "xyz"), 123;
	match Scalar::Util::dualvar(123, "456"), 123;
}

sub refaddr($) {
	overload::StrVal($_[0]) =~ /0x([0-9a-f]+)\)\z/
		or die "don't understand StrVal output";
	return hex_natint($1);
}

my $rt = {};
match $rt, refaddr($rt);

{
	package Ovtest;
	sub new { bless([ $_[1], 0 ]) }
	use overload "0+" => sub { my($self) = @_; $self->[1]++; $self->[0]; };
	use overload fallback => 1;
}

my $ot = Ovtest->new(3);
match $ot, 3; is $ot->[1], 1;
$ot = Ovtest->new(0.5);
match $ot, 0.5; is $ot->[1], 1;
$ot = Ovtest->new(0);
match $ot, 0; is $ot->[1], 1;
$ot = Ovtest->new(+0.0);
match $ot, +0.0; is $ot->[1], 1;
$ot = Ovtest->new(-0.0);
match $ot, -0.0; is $ot->[1], 1;
$ot = Ovtest->new(do { use integer; min_sint|1 });
match $ot, do { use integer; min_sint|1 }; is $ot->[1], 1;
$ot = Ovtest->new(max_uint);
match $ot, max_uint; is $ot->[1], 1;
$ot = Ovtest->new(0); $ot->[0] = $ot;
match $ot, refaddr($ot); is $ot->[1], 1;

my $ot1 = Ovtest->new(max_uint);
$ot = Ovtest->new($ot1);
match $ot, max_uint; is $ot->[1], 1; is $ot1->[1], 1;
$ot1 = Ovtest->new(0); $ot1->[0] = $ot1;
$ot = Ovtest->new($ot1);
match $ot, refaddr($ot1); is $ot->[1], 1; is $ot1->[1], 1;

1;
