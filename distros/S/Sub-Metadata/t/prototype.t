use warnings;
no warnings "once";
use strict;

use Test::More tests => 55;

BEGIN { use_ok "Sub::Metadata", qw(sub_prototype mutate_sub_prototype); }

sub tpn_0;
sub tpb_0 { }
sub tpn_ ();
sub tpb_ () { }
sub tpn_d ($);
sub tpb_d ($) { }
sub tpn_da ($@);
sub tpb_da ($@) { }

is sub_prototype(\&tpn_0), undef;
is sub_prototype(\&tpb_0), undef;
is sub_prototype(\&tpn_), "";
is sub_prototype(\&tpb_), "";
is sub_prototype(\&tpn_d), "\$";
is sub_prototype(\&tpb_d), "\$";
is sub_prototype(\&tpn_da), "\$\@";
is sub_prototype(\&tpb_da), "\$\@";

sub t0 { scalar($_[0])."x".scalar(@_) }
our @t1 = (333);
our @t2 = (444, 555, 666);

is sub_prototype(\&t0), undef;
is eval("t0(\@t1)"), "333x1";
is eval("t0(\@t2)"), "444x3";
is eval("t0(\@t1,\@t2)"), "333x4";
mutate_sub_prototype(\&t0, "\$");
is sub_prototype(\&t0), "\$";
is eval("t0(\@t1)"), "1x1";
is eval("t0(\@t2)"), "3x1";
mutate_sub_prototype(\&t0, "\@");
is sub_prototype(\&t0), "\@";
is eval("t0(\@t1)"), "333x1";
is eval("t0(\@t2)"), "444x3";
is eval("t0(\@t1,\@t2)"), "333x4";
mutate_sub_prototype(\&t0, "\$\@");
is sub_prototype(\&t0), "\$\@";
is eval("t0(\@t1)"), "1x1";
is eval("t0(\@t2)"), "3x1";
is eval("t0(\@t1,\@t2)"), "1x4";
is eval("t0(\@t2,\@t1)"), "3x2";
mutate_sub_prototype(\&t0, undef);
is sub_prototype(\&t0), undef;
is eval("t0(\@t1)"), "333x1";
is eval("t0(\@t2)"), "444x3";
is eval("t0(\@t1,\@t2)"), "333x4";

is sub_prototype(\&sub_prototype), "\$";
mutate_sub_prototype(\&sub_prototype, "\$;\@");
is sub_prototype(\&sub_prototype), "\$;\@";

sub t3 { }
my $t4 = "\xf1";
my $t5 = "\xf1\x{100}"; chop $t5;
mutate_sub_prototype(\&t3, $t4);
is sub_prototype(\&t3), "\xf1";
mutate_sub_prototype(\&t3, undef);
is sub_prototype(\&t3), undef;
mutate_sub_prototype(\&t3, $t5);
is sub_prototype(\&t3), "\xf1";
mutate_sub_prototype(\&t3, undef);
is sub_prototype(\&t3), undef;

sub t6 { }
eval { mutate_sub_prototype(\&t6, "snow\x{2603}man") };
if("$]" >= 5.015004) {
	is $@, "";
	is sub_prototype(\&t6), "snow\x{2603}man";
} else {
	like $@, qr/\AWide character/;
	is sub_prototype(\&t6), undef;
}

SKIP: {
	skip "prototypes don't work on autoload xsubs", 18
		unless "$]" >= 5.015004;
	my $almeth = \&{"utf8::is_utf8"};
	*AA::AUTOLOAD = $almeth;
	foreach my $methname ("Foo", "Snow\x{2603}Man") {
		AA->${\$methname};
		is sub_prototype($almeth), undef;
		mutate_sub_prototype($almeth, "\$");
		is sub_prototype($almeth), "\$";
		mutate_sub_prototype($almeth, $t4);
		is sub_prototype($almeth), "\xf1";
		mutate_sub_prototype($almeth, undef);
		is sub_prototype($almeth), undef;
		mutate_sub_prototype($almeth, $t5);
		is sub_prototype($almeth), "\xf1";
		mutate_sub_prototype($almeth, undef);
		is sub_prototype($almeth), undef;
		eval { mutate_sub_prototype($almeth, "snow\x{2603}man") };
		if("$]" >= 5.015004) {
			is $@, "";
			is sub_prototype($almeth), "snow\x{2603}man";
		} else {
			like $@, qr/\AWide character/;
			is sub_prototype($almeth), undef;
		}
		mutate_sub_prototype($almeth, undef);
		is sub_prototype($almeth), undef;
	}
}

1;
