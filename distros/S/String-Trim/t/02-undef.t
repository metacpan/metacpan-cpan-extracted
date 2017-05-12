use strict;
use warnings;
use Test::More 0.94 tests => 2;
use Test::Builder 0.94 qw();
use String::Trim;

subtest 'return' => sub {
    plan tests => 1;
    my $trimmed = trim(undef);
    is($trimmed, undef, 'trim(undef) returns undef');
};

subtest 'in-place' => sub {
    plan tests => 1;
    my $to_trim = undef;
    trim($to_trim);
    is($to_trim, undef, 'undef trims to undef in-place');
};
