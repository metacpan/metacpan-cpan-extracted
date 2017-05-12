use strict;
use Test::Lib;
use Test::Most;
use Minions ();

{
    package SetImpl;

    our %__meta__ = (
        role => 1,
        has => { set => { default => sub { {} } } }
    );

    sub BUILD {
        my (undef, $self, $arg) = @_;

        $self->{-set} = { map { $_ => 1 } @{ $arg->{elements} } };
    }
    
    sub has {
        my ($self, $e) = @_;
        exists $self->{-set}{$e};
    }
}

{
    package Set;

    our %__meta__ = (
        interface => [qw( has )],
        construct_with => {
            elements => {},
        },
        implementation => 'SetImpl',
    );
    Minions->minionize;
}

package main;

my $set = Set->new(elements => [1 .. 3]);
ok($set->has(1));
ok($set->has(2));
ok($set->has(3));
ok(! $set->has(4));

done_testing();
