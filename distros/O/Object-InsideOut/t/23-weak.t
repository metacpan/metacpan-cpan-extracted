use strict;
use warnings;

use Test::More 'tests' => 10;

package Foo; {
    use Object::InsideOut;
    my @foo :Field('Acc' => 'foo')
            :Weak;

    my %init_args :InitArgs = (
        'foo' => {
            'Field' => \@foo,
        },
    );

    sub direct
    {
        my ($self, $data) = @_;
        $self->set(\@foo, $data);
    }
}


package Bar; {
    use Object::InsideOut;
}


package main;

my $obj = Foo->new();

my ($clone, $pump, $initargs, $set);

{
    my $dat = Bar->new();

    $obj->foo($dat);
    is($obj->foo(), $dat        => 'Stored object');

    $clone = $obj->clone();
    is($clone->foo(), $dat      => 'Object in clone');

    $pump = Object::InsideOut::pump($clone->dump());
    is($pump->foo(), $dat       => 'Object in pump');

    $initargs = Foo->new('foo' => $dat);
    is($initargs->foo(), $dat   => 'Object in initargs');

    $set = Foo->new();
    $set->direct($dat);
    is($set->foo(), $dat        => 'Object in set');

    # $dat now goes out of scope and is destroyed
}

ok(! $obj->foo()                => 'Data gone');
ok(! $clone->foo()              => 'Data gone in clone');
ok(! $pump->foo()               => 'Data gone in pump');
ok(! $initargs->foo()           => 'Data gone in initargs');
ok(! $set->foo()                => 'Data gone in set');

exit(0);

# EOF
