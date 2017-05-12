package t::Net::ACME::RetryAfter;

use strict;
use warnings;
use autodie;

our @ISA;

use FindBin;
use lib "$FindBin::Bin";

BEGIN {
    require "Net-ACME-Certificate-Pending.t";
    unshift @ISA, 't::Net::ACME::Certificate::Pending';
}

use Test::More;

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

1;
