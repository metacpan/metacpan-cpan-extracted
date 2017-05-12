use strict;
use warnings;

use Test::More 'tests' => 9;

package Foo; {
    use Object::InsideOut;
    my @data :Field('Standard' => 'data', 'Permission' => 'private');
    my @info :Field('Accessor' => 'info', 'Permission' => 'restricted');
    my @also :Field
             :Acc('Name' => 'also', 'Perm' => 'rest ( Bork , ) ');
}

package Bar; {
    use Object::InsideOut 'Foo';

    sub bar_data
    {
        my $self = shift;
        return ($self->get_data());
    }

    sub bar_info
    {
        my $self = shift;
        if (! @_) {
            return ($self->info());
        }
        $self->info(@_);
    }
}

package Bork; {
    sub exempt
    {
        my $self = shift;
        my $obj = shift;
        if (! @_) {
            return ($obj->also());
        }
        $obj->also(@_);
    }

    sub cant
    {
        my ($self, $obj) = @_;
        $obj->info();
    }
}

package main;

my $foo = Foo->new();
my $bar = Bar->new();

eval { $foo->set_data(42); };
is($@->error, q/Can't call private method 'Foo->set_data' from class 'main'/
                                    , 'Private set method');
eval { $foo->get_data(); };
is($@->error, q/Can't call private method 'Foo->get_data' from class 'main'/
                                    , 'Private get method');
eval { $foo->info(); };
is($@->error, q/Can't call restricted method 'Foo->info' from class 'main'/
                                    , 'Restricted method');

eval { $bar->bar_data(); };
is($@->error, q/Can't call private method 'Foo->get_data' from class 'Bar'/
                                    , 'Private get method');

ok($bar->bar_info(10)               => 'Restricted set');
is($bar->bar_info(), 10             => 'Restricted get');

eval { Bork->cant($bar); };
is($@->error, q/Can't call restricted method 'Foo->info' from class 'Bork'/
                                    , 'Restricted method');

ok(Bork->exempt($bar, 99)           => 'Exempt restricted set');
is(Bork->exempt($bar), 99           => 'Exempt restricted get');

exit(0);

# EOF
