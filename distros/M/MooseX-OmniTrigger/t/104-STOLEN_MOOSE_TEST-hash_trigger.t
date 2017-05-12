use strict; use warnings;

use Test::More;

{ package Foo;

    use Moose;
    use MooseX::OmniTrigger;

    our @TriggerArgs;

    has hash => (traits => ['Hash'], is => 'rw', isa => 'HashRef', clearer => 'clear_key',

        handles => {

            delete_key => 'delete',
               set_key => 'set',
        },

        omnitrigger => sub { @TriggerArgs = @_ },
    );
}

my $foo = Foo->new;

{
    $foo->hash({x => 1, y => 2});

    is_deeply(\@Foo::TriggerArgs, [$foo, 'hash', [{x => 1, y => 2}], []], 'omnitrigger was called for normal writer');

    $foo->set_key(z => 5);

    is_deeply(\@Foo::TriggerArgs, [$foo, 'hash', [{x => 1, y => 2, z => 5}], [{x => 1, y => 2}]], 'omnitrigger was called on set');

    $foo->delete_key('y');

    is_deeply(\@Foo::TriggerArgs, [$foo, 'hash', [{x => 1, z => 5}], [{x => 1, y => 2, z => 5}]], 'trigger was called on delete');
}

done_testing;
