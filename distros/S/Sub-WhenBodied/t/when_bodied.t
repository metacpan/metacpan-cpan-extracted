use warnings;
use strict;

use Test::More tests => 10;

BEGIN { use_ok "Sub::WhenBodied", qw(when_sub_bodied); }

our @acted;
sub action($;$) {
	my($id, $extra) = @_;
	return sub {
		push @acted, [ $_[0], $id ];
		if($extra) {
			$extra->($_[0]);
			push @acted, [ $_[0], $id."x" ];
		}
	};
}
sub match_acted($$) {
	my($expected, $desc) = @_;
	ok(@acted == @$expected && !(grep {
		my $got = $acted[$_];
		my $exp = $expected->[$_];
		!($got->[0] == $exp->[0] && $got->[1] eq $exp->[1]);
	} 0..$#acted), $desc);
}

@acted = ();
when_sub_bodied(\&when_sub_bodied, action("0"));
match_acted [ [ \&when_sub_bodied, "0" ] ], "xsub immediate 0";

@acted = ();
sub t0 { }
when_sub_bodied(\&t0, action("1"));
match_acted [ [ \&t0, "1" ] ], "perl immediate 1";

@acted = ();
when_sub_bodied(\&when_sub_bodied,
	action("2", sub { when_sub_bodied($_[0], action("3")) }));
match_acted [
	[ \&when_sub_bodied, "2" ],
	[ \&when_sub_bodied, "2x" ],
	[ \&when_sub_bodied, "3" ],
], "xsub immediate 2/3";

@acted = ();
sub t1 { }
when_sub_bodied(\&t1,
	action("4", sub { when_sub_bodied($_[0], action("5")) }));
match_acted [
	[ \&t1, "4" ],
	[ \&t1, "4x" ],
	[ \&t1, "5" ],
], "perl immediate 4/5";

sub MODIFY_CODE_ATTRIBUTES {
	shift(@_);
	my $subject = shift(@_);
	foreach my $attr (@_) {
		when_sub_bodied($subject,
			action($attr, sub {
				when_sub_bodied($_[0], action($attr."e"))
			}));
	}
	return ();
}

@acted = ();
eval q{ sub t2 :a0 :a1 { } 1 } or die $@;
match_acted "$]" >= 5.015004 ? [
	[ \&t2, "a0" ],
	[ \&t2, "a0x" ],
	[ \&t2, "a0e" ],
	[ \&t2, "a1" ],
	[ \&t2, "a1x" ],
	[ \&t2, "a1e" ],
] : [
	[ \&t2, "a0" ],
	[ \&t2, "a0x" ],
	[ \&t2, "a1" ],
	[ \&t2, "a1x" ],
	[ \&t2, "a0e" ],
	[ \&t2, "a1e" ],
], "perl attrib a0/a1";

@acted = ();
eval q{ sub t3 :a2 :a3; 1 } or die $@;
match_acted [], "undef attrib a2/a3";
@acted = ();
eval q{ sub t3 :a4 :a5 { } 1 } or die $@;
SKIP: {
	skip "predeclarations cause attribute lossage on pre-5.10 perl", 1
		unless "$]" >= 5.010;
	match_acted "$]" >= 5.015004 ? [
		[ \&t3, "a4" ],
		[ \&t3, "a4x" ],
		[ \&t3, "a4e" ],
		[ \&t3, "a5" ],
		[ \&t3, "a5x" ],
		[ \&t3, "a5e" ],
	] : [
		[ \&t3, "a4" ],
		[ \&t3, "a4x" ],
		[ \&t3, "a5" ],
		[ \&t3, "a5x" ],
		[ \&t3, "a4e" ],
		[ \&t3, "a5e" ],
	], "perl attrib a4/a5";
}
@acted = ();
eval q{ sub t3 :a6 :a7; 1 } or die $@;
match_acted [
	[ \&t3, "a6" ],
	[ \&t3, "a6x" ],
	[ \&t3, "a6e" ],
	[ \&t3, "a7" ],
	[ \&t3, "a7x" ],
	[ \&t3, "a7e" ],
], "perl immediate a6/a7";

@acted = ();
sub t4 { }
sub t5 { }
when_sub_bodied(\&t4, action("6", sub {
	when_sub_bodied(\&t5, action("7", sub {
		when_sub_bodied(\&t4, action("8"));
		when_sub_bodied(\&t5, action("9"));
	}));
}));
match_acted [
	[ \&t4, "6" ],
	[ \&t5, "7" ],
	[ \&t5, "7x" ],
	[ \&t5, "9" ],
	[ \&t4, "6x" ],
	[ \&t4, "8" ],
], "perl immediate 6/7/8/9";

1;
