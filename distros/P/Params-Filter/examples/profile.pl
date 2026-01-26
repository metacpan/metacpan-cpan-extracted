#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Params::Filter qw/filter/;

# Profiling Script for Params::Filter
# This script focuses on the most common use case to identify bottlenecks
# Run with: perl -d:NYTProf examples/profile.pl
# Then view: nytprofhtml

say "Profiling Params::Filter...";

# Test 1: Simple hashref filtering (most common case)
my @simple_data = map {
    {
        id     => $_,
        name   => "User_$_",
        email  => 'user' . $_ . '@example.com',
        phone  => "555-$_",
        city   => "City_$_",
        extra1 => "data1",
        extra2 => "data2",
        extra3 => "data3",
    }
} (1..10000);

my @required = qw/id name email/;
my @accepted = qw/phone city/;
my @excluded = qw/extra1 extra2 extra3/;

say "Test 1: Filtering 10,000 hashrefs (7 fields, keep 5, exclude 3)...";
for my $data (@simple_data) {
    my ($filtered, $msg) = filter($data, \@required, \@accepted, \@excluded);
}
say "Test 1 complete\n";

# Test 2: Wildcard acceptance (common pattern)
my @wildcard_data = map {
    {
        id        => $_,
        name      => "User_$_",
        email     => 'user' . $_ . '@example.com',
        password  => "secret$_",
        ssn       => "123-$_",
        field1    => "data1",
        field2    => "data2",
        field3    => "data3",
    }
} (1..10000);

say "Test 2: Filtering 10,000 hashrefs with wildcard (8 fields, exclude 2)...";
for my $data (@wildcard_data) {
    my ($filtered, $msg) = filter($data, ['id', 'name'], ['*'], ['password', 'ssn']);
}
say "Test 2 complete\n";

# Test 3: OO interface with filter reuse
say "Test 3: OO interface with 10,000 calls...";
my $filter = Params::Filter->new_filter({
    required => \@required,
    accepted => \@accepted,
    excluded => \@excluded,
});
for my $data (@simple_data) {
    my ($filtered, $msg) = $filter->apply($data);
}
say "Test 3 complete\n";

# Test 4: Minimal case (required only)
my @minimal_data = map {
    {
        id    => $_,
        name  => "User_$_",
        email => 'user' . $_ . '@example.com',
    }
} (1..10000);

say "Test 4: Minimal filtering 10,000 hashrefs (3 required, no accepted)...";
for my $data (@minimal_data) {
    my ($filtered, $msg) = filter($data, \@required);
}
say "Test 4 complete\n";

say "Profiling complete. Run 'nytprofhtml' to generate report.";
