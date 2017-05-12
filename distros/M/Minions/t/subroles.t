use strict;
use Test::Lib;
use Test::Most;
use Minions ();

{
    package Alpha;

    our %__meta__ = (
        role => 1,
        roles => [qw( Bravo Charlie )]
    );

    sub alpha { 'alpha' }
}

{
    package Bravo;

    our %__meta__ = (
        role => 1,
        roles => [qw( Delta )]
    );

    sub bravo { 'bravo' }
}

{
    package Charlie;

    our %__meta__ = (
        role => 1,
    );

    sub charlie { 'charlie' }
}

{
    package Delta;

    our %__meta__ = (
        role => 1,
    );

    sub delta { 'delta' }
}

{
    package AlphabetImpl;

    our %__meta__ = (
        roles => [qw( Alpha )],
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

package main;

my $ab = Alphabet->new;
can_ok($ab, qw( alpha bravo charlie delta ));
is($ab->alpha,   'alpha');
is($ab->bravo,   'bravo');
is($ab->charlie, 'charlie');
is($ab->delta,   'delta');

ok($ab->DOES('UNIVERSAL'),  'does UNIVERSAL');
ok($ab->DOES('Alphabet'),   'does Alphabet');
ok($ab->DOES('Alpha'),   'does Alpha role');
ok($ab->DOES('Bravo'),   'does Bravo role');
ok($ab->DOES('Charlie'), 'does Charlie role');
ok($ab->DOES('Delta'),   'does Delta role');

is_deeply([ $ab->DOES ], [qw( Alphabet Alpha Bravo Charlie Delta )], 'DOES roles');

ok((ref $ab)->DOES('Alpha'),   'does Alpha role');
ok((ref $ab)->DOES('Bravo'),   'does Bravo role');
ok((ref $ab)->DOES('Charlie'), 'does Charlie role');
ok((ref $ab)->DOES('Delta'),   'does Delta role');

done_testing();
