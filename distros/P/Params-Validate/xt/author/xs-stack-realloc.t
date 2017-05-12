use strict;
use warnings;

use Test::More;

BEGIN {
    $ENV{PARAMS_VALIDATE_IMPLEMENTATION} = 'XS';
    $ENV{PV_WARN_FAILED_IMPLEMENTATION}  = 1;
}

use Params::Validate qw( validate_with );

my $alloc_size;
for my $i ( 0 .. 15 ) {
    $alloc_size = 2**$i;
    test_array_spec(undef);
}

ok( 1, 'array validation succeeded with stack realloc' );

for my $i ( 0 .. 15 ) {
    $alloc_size = 2**$i;
    test_hash_spec( a => undef );
}

ok( 1, 'hash validation succeeded with stack realloc' );

done_testing();

sub grow_stack {
    my @stuff = (1) x $alloc_size;

    # "validation" always succeeds - we just need the stack to grow inside a
    # callback to trigger the bug.
    return 1;
}

sub test_array_spec {
    my @args = validate_with(
        params => \@_,
        spec   => [ { callbacks => { grow_stack => \&grow_stack } } ],
    );
}

sub test_hash_spec {
    my %args = validate_with(
        params => \@_,
        spec   => {
            a => { callbacks => { grow_stack => \&grow_stack } },
        },
    );
}
