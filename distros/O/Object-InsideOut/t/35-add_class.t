use strict;
use warnings;

use Test::More 'tests' => 7;

package Trait::Selected; {
    use Object::InsideOut;

    my %is_selected :Field;

    sub is_selected
    {
        my $self = shift;
        $is_selected{$$self} ||= 0;
        return $is_selected{$$self} unless @_;
        $is_selected{$$self} = shift;
        return $self;
    }
}

package Foo; {
    use Object::InsideOut;

    my %data :Field :All(data);
}

package Bar; {
    use Object::InsideOut qw(Foo);

    my %info :Field :All(info);
}

package main;

my $obj = Bar->new('data' => 'zip', 'info' => 2);

is($obj->data(), 'zip', 'Get data');
is($obj->info(), 2,     'Get info');

Foo->add_class('Trait::Selected');
can_ok('Bar', 'is_selected');

is($obj->is_selected(1), $obj, 'Returns self');
is($obj->is_selected(), 1,     'Selected');

is($obj->data(), 'zip', 'Get data');
is($obj->info(), 2,     'Get info');

exit(0);

# EOF
