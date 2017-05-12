use strict;
use warnings;

use Test::More tests => 6;

use POSIX ":sys_wait_h";
use OO::InsideOut qw(id);

use t::Class::Simple;

my $object = t::Class::Simple->new();
my $id     = id $object;

my $child = fork;

if ( $child ) {
    Test::More->builder->no_ending( 1 );
}
else {
    # 1
    my $fork_id = id $object;
    is( $fork_id, $id, 'id (fork)' );

    # 2
    is_deeply( 
        $t::Class::Simple::Register,
        { $fork_id => $object },
        'register (fork)' 
    );
    $object->name('test');

    # 3
    is_deeply(
        $t::Class::Simple::Name,
        { $fork_id => 'test' },
        'data (fork)', 
    );

    exit;
}

waitpid $child, 0;

Test::More->builder->current_test( 3 );

# 4

is( id( $object ), $id, 'id' );

# 5
is_deeply( 
    $t::Class::Simple::Register,
    { $id => $object },
    'register' 
);

# 6
is_deeply(
    $t::Class::Simple::Name,
    {},
    'data', 
);

Test::More->builder->current_test( 6 );
