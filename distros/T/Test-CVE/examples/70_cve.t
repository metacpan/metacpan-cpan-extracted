#!/usr/bin/perl

use 5.014000;
use warnings;

use Test::More;
use Test::CVE;

if (my @cve = Test::CVE->new->test->cve) {
    foreach my $r (@cve) {
	my ($m, $v) = ($r->{release}, $r->{vsn});
	foreach my $c (@{$r->{cve}}) {
	    my $cve = join ", "  => @{$c->{cve}};
	    my $av  = join " & " => @{$c->{av}};
	    ok (0, "$m-$v : $cve for $av");
	    }
	}
    }
else {
    ok (1, "No CVE's reported!");
    }

done_testing;
