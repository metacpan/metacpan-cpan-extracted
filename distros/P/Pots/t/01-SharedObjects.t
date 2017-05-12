use Test::More tests => 16;

use strict;
use warnings;

use threads;
use threads::shared;

package SharedObj;

use base qw(Pots::SharedObject Pots::SharedAccessor);

SharedObj->mk_shared_accessors(qw(a b));

sub new {
    my $class = shift;

    my $self = $class->SUPER::new();

    $self->a(1);
    $self->b('foo');

    return $self;
}

1;

package main;

use_ok('Pots::SharedObject');
can_ok('Pots::SharedObject',
    qw(new destroy)
);

use_ok('Pots::SharedAccessor');
can_ok('Pots::SharedAccessor',
    qw(mk_shared_accessors)
);

use_ok('Pots::Semaphore');
can_ok('Pots::Semaphore',
    qw(new up down)
);

my $sem = Pots::Semaphore->new(0);
isa_ok($sem, 'Pots::Semaphore');

my $so = SharedObj->new();
isa_ok($so, 'Pots::SharedObject');
isa_ok($so, 'Pots::SharedAccessor');
isa_ok($so, 'SharedObj');
is($so->a(), 1, "Accessor value (num)");
is($so->b(), 'foo', "Accessor value (string)");

my $th = async {
    is($so->a(), 1, "Accessor value from thread (num)");
    is($so->b(), 'foo', "Accessor value from thread (string)");
    $sem->up();
    sleep(1);
    $sem->down();
    is($so->a(), 42, "Accessor changed value from thread (num)");
    is($so->b(), 'bar', "Accessor changed value from thread (string)");
};

$sem->down();
$so->a(42);
$so->b('bar');
$sem->up();
$th->join();
