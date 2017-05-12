use strict;
use Test::Lib;
use Test::Most;
use AlphabetRole;
use Minions ();

{
    package AlphabetImpl;

    our %__meta__ = (
        roles => [qw( AlphabetRole )],
    );
}

{
    package Alphabet;

    our %__meta__ = (
        interface => [qw( alpha bravo charlie delta )],
        implementation => 'AlphabetImpl',
    );
    Minions->minionize;
}

{
    package KeyboardImpl;
    our %__meta__ = (
        has => { 
            alphabet => {
                handles => [qw( alpha bravo charlie delta )],
                init_arg => 'alphabet' 
            }
        }
    );
}

{
    package Keyboard;

    our %__meta__ = (
        interface => [qw( alpha bravo charlie delta )],
        construct_with => {
            alphabet => {
                assert => { 'isa Alphabet' => sub { $_[0]->isa('Alphabet::__Minions') } },
            },
        },
        implementation => 'KeyboardImpl',
    );
    Minions->minionize();
}

package main;

my $kb = Keyboard->new(alphabet => Alphabet->new);
can_ok($kb, qw( alpha bravo charlie delta ));
is($kb->alpha,   'alpha');
is($kb->bravo,   'bravo');
is($kb->charlie, 'charlie');
is($kb->delta,   'delta');

done_testing();
