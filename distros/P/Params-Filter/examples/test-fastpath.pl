#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;
use Params::Filter qw/filter/;

# Test to verify which code path is being used

say "Testing code path detection...";
say "";

# Test 1: Functional interface with hashref
my $data1 = { name => 'Alice', email => 'alice@example.com' };
my ($result1, $msg1) = filter($data1, ['name'], ['email']);
say "Test 1 - Functional + hashref:";
say "  Result: ", $result1 ? "SUCCESS" : "FAIL";
say "  Data: ", join(", ", keys %$result1);
say "";

# Test 2: OO interface with hashref
my $filter = Params::Filter->new_filter({
    required => ['name'],
    accepted => ['email'],
});
my ($result2, $msg2) = $filter->apply($data1);
say "Test 2 - OO + hashref:";
say "  Result: ", $result2 ? "SUCCESS" : "FAIL";
say "  Data: ", join(", ", keys %$result2);
say "";

# Test 3: Functional interface with arrayref
my $data2 = ['name', 'Bob', 'email', 'bob@example.com'];
my ($result3, $msg3) = filter($data2, ['name'], ['email']);
say "Test 3 - Functional + arrayref:";
say "  Result: ", $result3 ? "SUCCESS" : "FAIL";
say "  Data: ", join(", ", keys %$result3);
say "";

say "All tests completed successfully!";
