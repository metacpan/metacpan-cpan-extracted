#!/usr/bin/perl

use Test::Simple qw(no_plan);

use Net::OpenID::JanRain::Consumer::LinkParser qw(parseLinkAttrs);
use strict;

my @failures = ();

my $fn = $ARGV[0] || "linkparse.txt";
my $fh;
open $fh, "< $fn" or open $fh, "< t/$fn" or open $fh, "< ../t/$fn" or die "couldn't open $fn";
my ($bytes, $data);
my $offset = 0;
do {
    my $foo;
    $bytes = read $fh, $foo, 16384, $offset;
    $offset += 16384;
    $data .= $foo;
} while($bytes == 16384);
close $fh;

my @cases = split /\n\n\n/, $data;

my $comment = shift @cases;

my $ncases = @cases;

TEST: for my $test (@cases) {
    my ($testname, @expected);

    my ($head, $body) = split /\n\n/, $test;
    my @headers = split /\n/, $head;
    for my $header (@headers) {
        my ($hk, $hv) = split /: /, $header;
        $testname = $hv if $hk eq 'Name';
        if ($hk eq 'Link') {
            my %link;
            my @attrs = split / /, $hv;
            for my $attr (@attrs) {
                my ($ak, $av) = split /=/, $attr;
                $link{$ak}=$av;
            }
            push @expected, \%link;
        }
        if ($hk eq 'Link*') {
            my %link;
            my @attrs = split / /, $hv;
            for my $attr (@attrs) {
                my ($ak, $av) = split /=/, $attr;
                $link{$ak}=$av;
            }
            $link{_optional_} = 1;
            push @expected, \%link;
        }
    }
    my @actual = parseLinkAttrs($body);
    my $f = @expected;
    my $b = @actual;
    my $i = 0;
    # Check that @actual is a subset of @expected (including optional)
    # they must also be in the correct order.
    my $link;
    for $link (@actual) {
        for (keys(%$link)) {
            unless ($link->{$_} eq $expected[$i]->{$_}
                 or $link->{$_} eq $expected[$i]->{"$_*"}) {
                if ($expected[$i]->{_optional_} and $i < $#expected) {
                    $i++;
                    ok(1);
                    redo;
                } else {
                    ok(0);
                    push @failures, [$testname, 
                        \@expected, \@actual, $test];
                    next TEST;
                }
            }
        }
        $i++;
    }
    # check that @expected not optional is a subset of @actual
    $i = 0;
    LINK: for $link (@expected) {
        next if $link->{_optional_};
        for (keys(%$link)) {
            next LINK if /\*^/;
            unless ($link->{$_} eq $actual[$i]->{$_}) {
                if ($i < $#actual) {
                    $i++;
                    ok(1);
                    redo;
                } else {
                    ok(0);
                    push @failures, [$testname, 
                        \@expected, \@actual, $test];
                    next TEST;
                }
            }
        }
    }
}

foreach my $failure (@failures) {
    print "\nFailure:\n";
    print $failure->[0]."\n";
    my $wanted = $failure->[1];
    my $got = $failure->[2];
    my $test = $failure->[3];
    print "Expected:\n";
    foreach my $link (@$wanted) {
        foreach my $key (keys(%$link)) {
            print $key.":".$link->{$key}."\n";
        }
        print "--\n";
    }
    print "Got:\n";
    foreach my $link (@$got) {
        foreach my $key (keys(%$link)) {
            print $key.":".$link->{$key}."\n";
        }
        print "--\n";
    } 
    print $test."\n";
}


