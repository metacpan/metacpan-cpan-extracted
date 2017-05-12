#!perl -wT

use strict;
use Test::More;
use Net::FireEagle;

my @fields = qw(access_token access_token_secret 
                request_token request_token_secret);

plan tests => scalar(@fields)*5;

my $fe = Net::FireEagle->new( consumer_key => 'foo', consumer_secret => 'bar' );

foreach my $field (@fields) {
    is($fe->{tokens}->{$field}, undef, "Inititally got undef from $field hash ref");
    is($fe->$field,   undef, "Inititally got undef from $field sub");
    my $tmp =  rand().$$.time();
    ok($fe->$field($tmp),    "Set the field $field");
    is($fe->{tokens}->{$field}, $tmp,  "Got value from $field hash ref");
    is($fe->$field,   $tmp,  "Got value from $field sub");
}
