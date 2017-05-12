#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN { push(@INC, "lib", "t"); }
use TestHelper;

my $mturk = TestHelper->new;

plan tests => 3;
ok($mturk, "Created client");

$mturk->addRetry(
    operations => qr/./i,
    errorCodes => qr/ServiceUnavailable/i,
    maxTries   => 5,
    delay      => 10
);

ok($mturk, "Added Retry");

my $result = $mturk->GetAccountBalance();
my $balance = $result->getFirst("AvailableBalance.Amount");
ok($balance =~ /^\d+\.\d+$/, "GetAccountBalance (with Retry)");
