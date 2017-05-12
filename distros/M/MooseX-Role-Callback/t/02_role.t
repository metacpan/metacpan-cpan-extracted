# Test what happens to a callback-enabled role

use strict;
use warnings;

use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";
use TestRole;

can_ok( 'TestRole',     'included' );
can_ok( TestRole->meta, 'include_callbacks' );

subtest included => sub {
    # Sanity check
    is( scalar( @{ TestRole->meta->include_callbacks } ),
        0, 'included_callbacks should start empty' );

    TestRole::included( sub { 'george the whale' } );
    is( scalar( @{ TestRole->meta->include_callbacks } ),
        1, 'should add the callback to included_callbacks list' );

    is(
        TestRole->meta->include_callbacks->[0]->(),
        'george the whale',
        'should add the right coderef to include_callbacks'
    );
};

done_testing();
