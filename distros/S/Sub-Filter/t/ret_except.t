use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok "Sub::Filter", qw(mutate_sub_filter_return); }

sub t0 { die "x<$_[0]>\n" }
sub f0 { "y<$_[0]>" }
mutate_sub_filter_return(\&t0, \&f0);
my $r = eval{t0("foo")};
is $@, "x<foo>\n";
is $r, undef;

sub t1 { "x<$_[0]>" }
sub f1 { die "y<$_[0]>\n" }
mutate_sub_filter_return(\&t1, \&f1);
$r = eval{t1("foo")};
is $@, "y<x<foo>>\n";
is $r, undef;

sub t2 { die "x<$_[0]>\n" }
sub f2 { die "y<$_[0]>\n" }
mutate_sub_filter_return(\&t2, \&f2);
$r = eval{t2("foo")};
is $@, "x<foo>\n";
is $r, undef;

1;
