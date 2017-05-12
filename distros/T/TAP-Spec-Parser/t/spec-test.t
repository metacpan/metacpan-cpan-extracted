#!/usr/bin/perl

use strict;
use warnings;

use TAP::Spec::Parser;
use YAML::XS qw(LoadFile);
use Path::Class;
use Carp;

use Test::More;

for my $file ( dir("t/spec-tests")->children ) {
    next unless $file =~ m{\.ya?ml};

    my @yaml = LoadFile($file);

    for my $num (0..$#yaml) {
        my $test = $yaml[$num];

        my $name = $test->{name} || sprintf "Test #%d from %s", $num, $file;
        note $name;

        my $tap = $test->{tap}   || croak "Test has no tap";
        my $want = $test->{want} || croak "Test has no want";

        my $result = TAP::Spec::Parser->parse_from_string($tap);
        ok $result, "Got a result" or next;

        my $have = result2have($result);
        is_deeply $have, $want, $name or diag explain $have;
    }
}

done_testing;


sub result2have {
    my $result = shift;
    my %have;

    $have{passed}  = $result->passed;
    $have{version} = $result->version;

    if( my $plan = $result->plan ) {
        $have{has_plan}         = 1;
        $have{planned_tests}    = $plan->number_of_tests;
    }

    for my $line ( @{ $result->body->lines } ) {
        push @{$have{tests}}, line2have($line);
    }

    return \%have;
}


sub line2have {
    my $line = shift;
    my %have;

    my %fields = (
        description => "description",
        number      => "number",
        status      => "status",
        passed      => "passed",
    );

    for my $field (keys %fields) {
        my $value = eval { $line->$field() };
        $have{$field} = $value if defined $value;
    }

    return \%have;
}
