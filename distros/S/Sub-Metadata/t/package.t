use warnings;
use strict;

use Test::More tests => 26;

BEGIN { use_ok "Sub::Metadata", qw(sub_package mutate_sub_package); }

package AA;

sub s_aa_n { }
sub AA::s_aa_aa { }
sub BB::s_aa_bb { }

package BB;

sub s_bb_n { }
sub AA::s_bb_aa { }
sub BB::s_bb_bb { }

package main;

is sub_package(\&AA::s_aa_n), "AA";
is sub_package(\&AA::s_aa_aa), "AA";
is sub_package(\&BB::s_aa_bb), "AA";
is sub_package(\&BB::s_bb_n), "BB";
is sub_package(\&AA::s_bb_aa), "BB";
is sub_package(\&BB::s_bb_bb), "BB";
is sub_package(\&sub_package), undef;

mutate_sub_package(\&AA::s_aa_n, "BB");
is sub_package(\&AA::s_aa_n), "BB";
is sub_package(\&AA::s_aa_aa), "AA";
mutate_sub_package(\&AA::s_aa_n, "CC");
is sub_package(\&AA::s_aa_n), "CC";
is sub_package(\&AA::s_aa_aa), "AA";
mutate_sub_package(\&AA::s_aa_n, undef);
is sub_package(\&AA::s_aa_n), undef;
is sub_package(\&AA::s_aa_aa), "AA";
mutate_sub_package(\&AA::s_aa_n, "AA");
is sub_package(\&AA::s_aa_n), "AA";
is sub_package(\&AA::s_aa_aa), "AA";

mutate_sub_package(\&sub_package, "AA");
is sub_package(\&sub_package), "AA";
mutate_sub_package(\&sub_package, "BB");
is sub_package(\&sub_package), "BB";
mutate_sub_package(\&sub_package, "CC");
is sub_package(\&sub_package), "CC";
mutate_sub_package(\&sub_package, undef);
is sub_package(\&sub_package), undef;

sub t0 { }
my $t0 = "\xf1";
my $t1 = "\xf1\x{100}"; chop $t1;
mutate_sub_package(\&t0, $t0);
is sub_package(\&t0), "\xf1";
mutate_sub_package(\&t0, "main");
is sub_package(\&t0), "main";
mutate_sub_package(\&t0, $t1);
is sub_package(\&t0), "\xf1";
mutate_sub_package(\&t0, "main");
is sub_package(\&t0), "main";

sub t2 { }
eval { mutate_sub_package(\&t2, "Snow\x{2603}Man") };
if("$]" >= 5.015004) {
	is $@, "";
	is sub_package(\&t2), "Snow\x{2603}Man";
} else {
	like $@, qr/\AWide character/;
	is sub_package(\&t2), "main";
}

1;
