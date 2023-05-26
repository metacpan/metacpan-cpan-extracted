#!/usr/bin/perl

use 5.014002;
use warnings;

use Test::More;
use Test::Warnings;

use Net::CVE;

my %expect = (
    en => { problem     => "Probleem 1\nProbleem 2",
            description => "en-US line 1\nen-US line 2\nen-US line 3",
            },
    es => { problem     => "Problema 1\nProblema 2",
            description => "Hola",
            },
    nl => { problem     => "Probleem 1\nProbleem 2",
            description => "NL regel 1\nNL regel 2",
            },
    xx => { problem     => "Probleem 1\nProbleem 2",
            description => "en-US line 1\nen-US line 2\nen-US line 3",
            },
    );

foreach my $lang (sort keys %expect) {
    ok (my $cr = Net::CVE->new (lang => $lang),		"$lang New reporter");
    ok ($cr->get ("Files/CVE-1970-1.json"),		"$lang Read stored report");
    ok (my $r = $cr->summary,				"$lang Generate summary");

    is ($r->{problem},     $expect{$lang}{problem},	"$lang Problem");
    is ($r->{description}, $expect{$lang}{description},	"$lang Description");
    }

done_testing;
