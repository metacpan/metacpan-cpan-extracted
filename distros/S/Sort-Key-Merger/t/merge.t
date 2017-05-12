#!/usr/bin/perl

use strict;
use warnings;

use constant sizes => 1, 4, 32, 128;

use Test::More tests => 1+3*4*4;

BEGIN { use_ok('Sort::Key::Merger') };

use Sort::Key qw(keysort nkeysort);
use Sort::Key::Merger qw(keymerger nkeymerger);

# use Scalar::Quote ':short';

sub make_key ($) { $_[0] }

sub key_value {
    if (@$_) {
	my $v=shift @$_;
	return (make_key($v), $v);
    }
    ()
}

for my $i (sizes) {
    for my $j (sizes) {
	my @srcs;
	for my $u (0..$i) {
	    my @src;
	    for my $v (1..rand($j)) {
		push @src, 1000-rand(2000);
	    }
	    push @srcs, \@src;
	}

	{
	    my $merger = keymerger \&key_value, (map { [keysort { make_key($_)} @$_] } @srcs);

	    my @ksm = &$merger;
	    my @ks = keysort { make_key($_) } (map { @$_ } @srcs);

	    # D("@ksm", "@ks") and print "$a is not the same as\n$b\n";

	    is_deeply([@ksm], [@ks], "keymerger $i-$j");
	}

	{
	    my $merger = nkeymerger \&key_value, (map { [nkeysort { make_key($_)} @$_] } @srcs);

	    my @ksm = &$merger;
	    my @ks = nkeysort { make_key($_) } (map { @$_ } @srcs);

	    # D("@ksm", "@ks") and print "$a is not the same as\n$b\n";

	    is_deeply([@ksm], [@ks], "nkeymerger $i-$j");
	}
    }
}

for my $i (sizes) {
    for my $j (sizes) {
	my @srcs;
	for my $u (0..$i) {
	    my @src;
	    for my $v (1..rand($j)) {
		push @src, int(1000-rand(2000));
	    }
	    push @srcs, \@src;
	}

	{
	    use integer;
	    my $merger = nkeymerger \&key_value, (map { [nkeysort { make_key($_)} @$_] } @srcs);

	    my @ksm = &$merger;
	    my @ks = nkeysort { make_key($_) } (map { @$_ } @srcs);

	    # D("@ksm", "@ks") and print "$a is not the same as\n$b\n";

	    is_deeply([@ksm], [@ks], "ikeymerger $i-$j");
	}
    }
}
