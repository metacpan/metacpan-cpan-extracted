#!/usr/bin/env perl
use Test2::V0;
use strictures 2;

use Test2::Require::Module 'Algorithm::Loops';

use Algorithm::Loops qw( NestedLoops );
use List::MoreUtils qw( zip );
use Object::Depot;
use Types::Standard qw( Object );

{ package Test::permutations; use Moo }

my %possibles = (
    class             => [undef, 'Test::permutations'],
    constructor       => [undef, sub{ my $d=shift; $d->class->new(@_) }],
    type              => [undef, Object],
    per_process       => [undef, 1],
    strict_keys       => [undef, 1],
    default_key       => [undef, 'random'],
    key_argument      => [undef, 'connection_key'],
    default_arguments => [undef, {foo=>1} ],
    add_key           => [0, 1],
    alias_key         => [0, 1],
);

my @keys = (sort keys %possibles);

my @permutations;
NestedLoops(
    [
        map { $possibles{$_} }
        @keys
    ],
    sub { push @permutations, [@_] },
);

my @tests = (
    map { { zip @keys, @$_ } }
    @permutations
);

my $class_iter = 0;

foreach my $test (@tests) {
    my $id = join(' ',
        map {
            "$_=" . (
                defined($test->{$_})
                ? (ref($test->{$_}) || $test->{$_})
                : 'UNDEF'
            )
        }
        sort keys %$test
    );

    subtest $id => sub{

    $class_iter++;
    my $class = "CC$class_iter";
    $test->{class} = $class;

    my $add_key = delete $test->{add_key};
    my $alias_key = delete $test->{alias_key};

    $test = {
        map { $_ => $test->{$_} }
        grep { defined( $test->{$_} ) ? $_ : () }
        keys %$test
    };

    my $depot = Object::Depot->new( $test );

    $depot->add_key(
        geo_ip => (
            driver => 'Memory',
            global => 0,
        ),
    ) if $add_key;

    $depot->alias_key(
        foo => 'geo_ip',
    ) if $alias_key and $add_key;

    ok( 1, 'made depot object' );

    foreach my $method (sort keys %possibles) {
        next if $method eq 'add_key';
        next if $method eq 'alias_key';

        is(
            dies{ $depot->$method() }, undef,
            "called $method()",
        );
    }

    };
}

done_testing;
