#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN { push(@INC, "lib", "t"); }
use TestHelper;

my $mturk = TestHelper->new;

plan tests => 3;
ok( $mturk, "Created Client" );

my $result = $mturk->GetAccountBalance();
print $result->toString, "\n";

# Using get prevents auto vivify.
my $balance = $result->getFirst("AvailableBalance.Amount");
print "Balance = $balance\n";

ok($balance =~ /^\d+\.\d+$/, "GetAccountBalance");


# Test with invalid SecretKey
my $broken_mturk = TestHelper->new( secretKey=>"bogus" );
my $broken = $broken_mturk->expectError( "AWS.NotAuthorized", sub { $broken_mturk->GetAccountBalance(); } );
ok($broken, "GetAccountBalance with invalid SecretKey");
