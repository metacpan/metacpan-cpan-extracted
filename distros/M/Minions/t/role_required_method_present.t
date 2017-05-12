use strict;
use Test::Lib;
use Test::Most;
use Minions ();

{
    package SorterRole;

    use Minions::Role
        requires => { methods => ['cmp'] }
    ;

    sub sort {
        my ($self, $items) = @_;
        
        my $cmp = $self->{$__}->can('cmp');
        return [ sort $cmp @$items ];
    }
}

{
    package SorterImpl;

    our %__meta__ = (
        semiprivate => ['cmp'],
        roles => [qw( SorterRole )],
    );

    sub cmp ($$) {
        my ($x, $y) = @_;
        $y <=> $x;    
    }
}

{
    package Sorter;

    our %__meta__ = (
        interface => [qw( sort )],
        implementation => 'SorterImpl',
    );
    Minions->minionize;
}

package main;

my $sorter = Sorter->new;

is_deeply($sorter->sort([1 .. 4]), [4,3,2,1], 'required method present.');
ok(! $sorter->can('cmp'), "Can't call private sub");

done_testing();
