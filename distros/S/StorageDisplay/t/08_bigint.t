#!/usr/bin/perl
#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2014-2023 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Test2::V0;
use Scalar::Util;
use Math::BigInt;
use Math::BigFloat;

my $s1;
my $s2;

my $v=1;
my @types = ('i', 's', 'bi', 'bf');

sub alloc_value_i {
    return 0+shift;
}

sub alloc_value_s {
    return ''.shift;
}

sub alloc_value_bi {
    my $v = shift;
    return Math::BigInt->new($v);
}

sub alloc_value_bf {
    my $v = shift;
    return Math::BigFloat->new($v);
}

sub alloc_value {
    my $v = shift;
    my $t = shift;
    my $sub = 'alloc_value_'.$t;
    return __PACKAGE__->can($sub)->($v);
}

# build hashes s1 and s2
# - do not put scalar in s1 with non scalar in s2
# - do not put different objects with the same key in s1 and s2
foreach my $t1 (@types) {
    $v += 100;
    my $v1 = alloc_value($v, $t1);
    my $v2 = alloc_value($v, $t1);
    my $sv = $v;
    $s1->{$t1} = $v1;
    $s2->{$t1} = $v2;
    foreach my $t2 (@types) {
	next if length($t1) < length($t2);
	next if ($t1 eq 'bi' && $t2 eq 'bf')
	    or  ($t1 eq 'bf' && $t2 eq 'bi');
	$v += 10;
	my $v1 = alloc_value($v, $t1);
	my $v2 = alloc_value($v, $t2);
	my $k = $t1.'2'.$t2;
	$s1->{$k} = $v1;
	$s2->{$k} = $v2;
    }
    $v = $sv;
}

sub check_struct($$) {
    my $s = shift;
    my $part = shift;

    foreach my $k (keys %$s) {
	my @t = split('2', $k);
	my $t = $t[$part] // $t[0];
	my $v = $s->{$k};
	if ($t =~ /^[is]$/) {
	    is(ref($v), "", "is a scalar value");
	} elsif ($t eq 'bi') {
	    isa_ok($v, 'Math::BigInt');
	} elsif ($t eq 'bf') {
	    isa_ok($v, 'Math::BigFloat');
	} else {
	    die "Should not be here";
	}
    }
}

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
diag(Dumper({ s1 => $s1, s2 => $s2 }));

check_struct($s1, 0);
check_struct($s2, 1);

is($s1, $s2, "integer types comparisons");

done_testing;   # reached the end safely

