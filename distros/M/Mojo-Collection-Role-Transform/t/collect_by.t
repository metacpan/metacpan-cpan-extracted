use Mojo::Base -strict;
use Test::More;
use Mojo::Collection 'c';
use Mojo::Util 'dumper';

my $c = c(1, 2, 3)->with_roles('+Transform');

my $bob = {
    name           => 'Bob',
    age            => 23,
    favorite_color => 'blue',
};
my $alice = {
    name           => 'Alice',
    age            => 23,
    favorite_color => 'blue',
};
my $eve = {
    name           => 'Eve',
    age            => 23,
    favorite_color => 'green',
};
my $people_c = c($bob, $alice, $eve)->with_roles('+Transform');

my @options_to_test = (undef, {}, {flatten => 1}, {flatten => 0});
note 'Test with return values where flatten has no effect';
for my $option_to_test (@options_to_test) {
    my @options = $option_to_test ? ($option_to_test) : ();
    note 'Testing with options ' . dumper \@options;

    note 'Test get_keys';
    my $collections = $c->collect_by(@options, sub { $_ });
    is_deeply
        $collections,
        [ map { [$_] } @$c ],
        'default value sub uses value in collection'
        ;
    isa_ok $collections, 'Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collections->each;

    $collections = $c->collect_by(@options, sub { $_[0] });
    is_deeply
        $collections,
        [ map { [$_] } @$c ],
        'collection value avaliable in get_keys as first argument'
        ;
    isa_ok $collections, 'Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collections->each;

    $collections = $c->collect_by(@options, sub { $_ % 2 });
    is_deeply
        $collections,
        [[1, 3], [2]],
        'get_keys sub returned value is used and values are grouped by key'
        ;
    isa_ok $collections, 'Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collections->each;

    $collections = $people_c->collect_by(@options, sub { @{$_}{qw(age favorite_color)} });
    is_deeply
        $collections,
        [[$bob, $alice], [$eve]],
        'multiple keys (2) can be returned'
        ;
    isa_ok $collections, 'Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collections->each;

    my %bob1 = (%$bob, favorite_color => 'turquoise');
    my %bob2 = (%$bob, favorite_color => 'aqua');
    my %bob3 = (%$bob, favorit_color  => 'cyan');
    $collections =
        c(\%bob1, \%bob2, \%bob3)->with_roles('+Transform')
                                 ->collect_by(@options, sub { @{$_}{qw(age name favorite_color)} })
                                 ;
    is_deeply
        $collections,
        [[\%bob1], [\%bob2], [\%bob3]],
        'multiple keys (3) can be returned'
        ;
    isa_ok $collections, 'Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collections->each;

    note 'Test get_value';
    $collections = $c->collect_by(@options, sub { $_ }, sub { $_ * $_ });
    is_deeply
        $collections,
        [ map { [$_ * $_ ] } @$c ],
        'get_value sub used if provided'
        ;
    isa_ok $collections, 'Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collections->each;

    $collections = $c->collect_by(@options, sub { $_ }, sub { $_[0] * $_[0] });
    is_deeply
        $collections,
        [ map { [$_ * $_ ] } @$c ],
        'collection value avaliable in get_value as first argument'
        ;
    isa_ok $collections, 'Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collections->each;

    $collections = $c->collect_by(@options, sub { $_ }, sub { $_, $_ + 1, $_ + 2 });
    is_deeply
        $collections,
        [ map { [$_, $_ + 1, $_ + 2] } @$c ],
        'get_value may return multiple values'
        ;
    isa_ok $collections, 'Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collections->each;
}

note 'Test flatten';
my $collections = $c->collect_by(sub { 'key' }, sub { [$_] });
is_deeply
    $collections,
    [ [map { [$_] } @$c] ],
    'values not flattened by default'
    ;
isa_ok $_, 'Mojo::Collection' for @$collections;

$collections = $c->collect_by({flatten => 0}, sub { 'key' }, sub { [$_] });
is_deeply
    $collections,
    [ [map { [$_] } @$c] ],
    'values not flattened when flatten is 0'
    ;
isa_ok $_, 'Mojo::Collection' for @$collections;

$collections = $c->collect_by({flatten => undef}, sub { 'key' }, sub { [$_] });
is_deeply
    $collections,
    [ [map { [$_] } @$c] ],
    'values not flattened when flatten is undef'
    ;
isa_ok $_, 'Mojo::Collection' for @$collections;

$collections = $c->collect_by({flatten => ''}, sub { 'key' }, sub { [$_] });
is_deeply
    $collections,
    [ [map { [$_] } @$c] ],
    'values not flattened when flatten is empty string'
    ;
isa_ok $_, 'Mojo::Collection' for @$collections;

$collections = $c->collect_by({flatten => 1}, sub { 'key' }, sub { [$_] });
is_deeply
    $collections,
    [$c],
    'returned values are flattened'
    ;
isa_ok $collections, 'Mojo::Collection';
isa_ok $_, 'Mojo::Collection' for $collections->each;

$collections = $c->collect_by({flatten => 1}, sub { 'key' }, sub { $_ % 2 ? [$_] : $_ });
is_deeply
    $collections,
    [$c],
    'values that are already flattened work'
    ;
isa_ok $collections, 'Mojo::Collection';
isa_ok $_, 'Mojo::Collection' for $collections->each;

$collections = $c->collect_by({flatten => 1}, sub { 'key' }, sub { $_ % 2 ? [$_] : ($_, $_) });
is_deeply
    $collections,
    [[1, 2, 2, 3]],
    'multiple values that are already flattened work'
    ;
isa_ok $collections, 'Mojo::Collection';
isa_ok $_, 'Mojo::Collection' for $collections->each;

$collections = $c->collect_by({flatten => 1}, sub { $_ % 2 }, sub { [$_] });
is_deeply
    $collections,
    [[1, 3], [2]],
    'flatten works with multiple keys'
    ;
isa_ok $collections, 'Mojo::Collection';
isa_ok $_, 'Mojo::Collection' for $collections->each;

$collections = $c->collect_by({flatten => 1}, sub { $_ }, sub { [[], [$_], [[[$_]]]] });
is_deeply
    $collections,
    [ map { [$_, $_] } @$c ],
    'flatten handles nested arrays',
    ;
isa_ok $collections, 'Mojo::Collection';
isa_ok $_, 'Mojo::Collection' for $collections->each;

done_testing;
