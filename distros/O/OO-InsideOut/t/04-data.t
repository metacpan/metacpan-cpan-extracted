use strict;
use warnings;

use Test::More tests => 3;

use OO::InsideOut qw(id);

use t::Class::Simple;

my $object = t::Class::Simple->new();

# 1
is( $object->name, undef, 'undefined' );

# 2
$object->name('test');
is( $object->name, 'test', 'defined' );

# 3
is_deeply(
    $t::Class::Simple::Name,
    { id( $object ) => 'test' },
    'data', 
);
