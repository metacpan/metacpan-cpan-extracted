use strict;
use warnings;

use threads;

use Test::More tests => 6;

use OO::InsideOut qw(id);

use t::Class::Simple;

my $object = t::Class::Simple->new();
my $id     = id $object;

threads->new( 
    sub { 
        # 1
        my $thread_id = id $object;
        isnt( $thread_id, $id, 'id (thread)' );

        # 2
        is_deeply( 
            $t::Class::Simple::Register,
            { $thread_id => $object },
            'register (thread)' 
        );

        # 3
        $object->name('test');
        is_deeply(
            $t::Class::Simple::Name,
            { $thread_id => 'test' },
            'data (thread)', 
        );
    },
)->join();


# 4
is( id( $object), $id, 'id' );

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
