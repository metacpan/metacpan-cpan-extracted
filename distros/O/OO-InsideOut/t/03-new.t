use strict;
use warnings;

use Test::More tests => 1;

use OO::InsideOut qw(id);

use t::Class::Simple;

# 1
my $object = t::Class::Simple->new();

is_deeply( 
    $t::Class::Simple::Register,
    { id( $object ) => $object },
    'wrapped' 
);
