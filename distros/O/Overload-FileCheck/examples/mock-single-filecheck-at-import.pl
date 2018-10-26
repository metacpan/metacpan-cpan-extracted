#!perl

use strict;
use warnings;

use Test::More;
use Overload::FileCheck '-e' => \&my_dash_e, q{:check};

# Mock one or more check
#use Overload::FileCheck '-e' => \&my_dash_e, '-f' => sub { 1 }, 'x' => sub { 0 }, ':check';

my @exist     = qw{cherry banana apple};
my @not_there = qw{chocolate and peanuts};

sub my_dash_e {
    my $f = shift;

    note "mocked -e called for", $f;

    return CHECK_IS_TRUE  if grep { $_ eq $f } @exist;
    return CHECK_IS_FALSE if grep { $_ eq $f } @not_there;

    # we have no idea about these files
    return FALLBACK_TO_REAL_OP;
}

foreach my $f (@exist) {
    ok( -e $f, "file '$f' exists" );
}

foreach my $f (@not_there) {
    ok( !-e $f, "file '$f' exists" );
}

# this is using the fallback logic '-1'
ok -e $0,  q[$0 is there];
ok -e $^X, q[$^X is there];

done_testing;
