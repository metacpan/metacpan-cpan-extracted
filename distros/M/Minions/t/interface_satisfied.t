use strict;
use Test::Lib;
use Test::Most;
use Minions ();

{
    package PersonImpl;

    our %__meta__ = (
        has => { 
            name => { 
                init_arg => 'name',
                reader => 1,
            }
        }
    );

    sub greet {
        my ($self) = @_;
        return "Hello $self->{-name}";
    }
}

{
    package Person;

    our %__meta__ = (
        interface => [qw( greet name )],
        construct_with => {
            name => { },
        },
        implementation => 'PersonImpl',
    );
    Minions->minionize;
}

package main;

my $person = Person->new(name => 'Bob');
is($person->name, 'Bob', 'required interface method present');

done_testing();
