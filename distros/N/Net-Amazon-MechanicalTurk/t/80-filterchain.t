#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 10;
BEGIN { push(@INC, "lib", "t"); }
use Net::Amazon::MechanicalTurk::FilterChain;

sub endcall {
    return [@_];
}

sub multiplyingFilter {
    my ($chain, $targetParams, $multiplier) = @_;
    for (my $i=0; $i<=$#{$targetParams}; $i++) {
        $targetParams->[$i] = $targetParams->[$i] * $multiplier;
    }
    return $chain->();
}

sub retryFilter {
    my ($chain, $targetParams, $maxTries, $retryDelay) = @_;
    for (my $count = 1; $count <= $maxTries; $count++) {
        my $result = eval { $chain->() };
        if ($@) {
            if ($count >= $maxTries) {
                die $@;
            }
            warn "Will retry again after delay of $retryDelay.\n";
            if ($retryDelay) {
                sleep($retryDelay);
            }
        }
        else {
            return $result;
        }
    }
}

my $chain = Net::Amazon::MechanicalTurk::FilterChain->new;
my $result;

# Test a simple call
$result = $chain->execute(\&endcall, 7, 9, 9);
is_deeply($result, [7,9,9], "Straight call");

# Add a filter which multiplies the parameters
$chain->addFilter(\&multiplyingFilter, 2);
$result = $chain->execute(\&endcall, 7, 9, 9);
is_deeply($result, [14,18,18], "Multiplying filter");

my $expected = [7,9,9];

# Add an extra printing filter with save
$chain->addFilter(sub {
    my ($chain, $params) = @_;
    is_deeply($params, $expected, "Print filter expected");
    print "Starting call with params: " . join(",", @$params) . "\n";
    my $result = $chain->();
    print "Ended call.\n";
    return $result;
});
$result = $chain->execute(\&endcall, 7, 9, 9);
is_deeply($result, [14,18,18], "With printer");


# Get rid of the filter
$chain->removeFilter(\&multiplyingFilter);
$result = $chain->execute(\&endcall, 7, 9, 9);
is_deeply($result, [7,9,9], "Removed Multiplier");


$expected = [21,27,27];

# Add it back (now before printer)
$chain->addFilter(\&multiplyingFilter, 3);
$result = $chain->execute(\&endcall, 7, 9, 9);
is_deeply($result, [21,27,27], "Added multiplier back");


$chain->removeAllFilters();
$chain->addFilter(\&retryFilter, 100, 2);
my $value = $chain->execute(sub {
    my $value = rand();
    if ($value < 0.1) {
        return $value;
    }
    else {
        die "Doh! wrong value $value";
    }
});
#print "End value $value\n";

$chain->removeAllFilters();
$chain->addFilter(\&retryFilter, 3, 2);
my $executions = 0;
eval {
    $chain->execute(sub {
        $executions++;
        die "Doh! wrong value $value";
    });
};
ok($@, "Expected failure.");
is(3, $executions, "Retry Filter");

