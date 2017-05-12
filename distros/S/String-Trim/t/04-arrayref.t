use strict;
use warnings;
use Test::More 0.94 tests => 2;
use Test::Builder 0.94 qw();
use String::Trim;

my $tests = {
    one => {
        before => ['one',  ' two ', "three\n", undef],
        after  => ['one',  'two',   'three', undef],
    },
    two => {
        before => [' test '],
        after  => ['test'],
    },
};

subtest 'return' => sub {
    plan tests => scalar keys %$tests;
    foreach my $key (keys %$tests) {
        my $to_trim = $tests->{$key}->{before};
        my $ought   = $tests->{$key}->{after};
        
        my $trimmed = trim($to_trim);
        is_deeply($trimmed, $ought, 'trim($arrayref) returns a trimmed arrayref OK');
    }
};

subtest 'in-place' => sub {
    plan tests => scalar keys %$tests;
    foreach my $key (keys %$tests) {
        my $to_trim = $tests->{$key}->{before};
        my $ought   = $tests->{$key}->{after};
        
        trim($to_trim);
        is_deeply($to_trim, $ought, 'trims an arrayref in-place OK');
    }
};
