use strict;
use warnings;

use Test::More tests => 2;

use OO::InsideOut qw(id);

use t::Class::Simple;

my $id;
{
    my $object = t::Class::Simple->new();
    $id = id $object;
    $object->name('test');
}

# 1
ok( 
    ! exists $t::Class::Simple::Register->{ $id },
    'object destroyed' 
);

# 2
ok( 
    ! exists $t::Class::Simple::Name->{ $id },
    'data destroyed' 
);
