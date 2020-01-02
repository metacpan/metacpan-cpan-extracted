use Mojo::Base -strict;
use Test::More;
use Mojo::Collection 'c';
use Mojo::Util 'dumper';

my $c = c(1, 2, 3)->with_roles('+Transform');
my @options_to_test = (undef, {}, {flatten => 1}, {flatten => 0});
note 'Test with return values where flatten has no effect';
for my $option_to_test (@options_to_test) {
    my @options = $option_to_test ? ($option_to_test) : ();
    note 'Testing with options ' . dumper \@options;

    note 'Test get_keys';
    my $hash = $c->hashify_collect(@options, sub { $_ });
    is_deeply
        $hash,
        { map { $_ => [$_] } @$c },
        'default value sub uses value in collection'
        ;
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $c->hashify_collect(@options, sub { $_[0] });
    is_deeply
        $hash,
        { map { $_ => [$_] } @$c },
        'collection value avaliable in get_keys as first argument'
        ;
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $c->hashify_collect(@options, sub { $_ * $_ });
    is_deeply
        $hash,
        { map { $_ * $_ => [$_] } @$c },
        'get_keys sub uses returned value'
        ;
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $c->hashify_collect(@options, sub { $_, $_ * $_ });
    is_deeply
        $hash,
        { map { $_ => { $_ * $_ => [$_]} } @$c },
        'multiple keys can be returned'
        ;
    isa_ok $_, 'Mojo::Collection' for map { values %$_ } values %$hash;

    note 'Test get_value';
    $hash = $c->hashify_collect(@options, sub { $_, $_ * $_ }, sub { $_ * $_ * $_ });
    is_deeply
        $hash,
        { map { $_ => { $_ * $_ => [$_ * $_ * $_]} } @$c },
        'get_value sub used if provided'
        ;
    isa_ok $_, 'Mojo::Collection' for map { values %$_ } values %$hash;

    $hash = $c->hashify_collect(@options, sub { $_, $_ * $_ }, sub { $_[0] * $_[0] * $_[0] });
    is_deeply
        $hash,
        { map { $_ => { $_ * $_ => [$_ * $_ * $_]} } @$c },
        'collection value avaliable in get_value as first argument'
        ;
    isa_ok $_, 'Mojo::Collection' for map { values %$_ } values %$hash;

    $hash = $c->hashify_collect(@options, sub { $_, $_ * $_ }, sub { $_, $_ + 1, $_ + 2 });
    is_deeply
        $hash,
        { map { $_ => { $_ * $_ => [$_, $_ + 1, $_ + 2]} } @$c },
        'get_value may return multiple values'
        ;
    isa_ok $_, 'Mojo::Collection' for map { values %$_ } values %$hash;
}

note 'Test flatten';
my $hash = $c->hashify_collect(sub { 'key' }, sub { [$_] });
is_deeply
    $hash,
    {key => [map { [$_] } @$c]},
    'values not flattened by default'
    ;
isa_ok $_, 'Mojo::Collection' for values %$hash;

$hash = $c->hashify_collect({flatten => 0}, sub { 'key' }, sub { [$_] });
is_deeply
    $hash,
    {key => [map { [$_] } @$c]},
    'values not flattened when flatten is 0'
    ;
isa_ok $_, 'Mojo::Collection' for values %$hash;

$hash = $c->hashify_collect({flatten => undef}, sub { 'key' }, sub { [$_] });
is_deeply
    $hash,
    {key => [map { [$_] } @$c]},
    'values not flattened when flatten is undef'
    ;
isa_ok $_, 'Mojo::Collection' for values %$hash;

$hash = $c->hashify_collect({flatten => ''}, sub { 'key' }, sub { [$_] });
is_deeply
    $hash,
    {key => [map { [$_] } @$c]},
    'values not flattened when flatten is empty string'
    ;
isa_ok $_, 'Mojo::Collection' for values %$hash;

$hash = $c->hashify_collect({flatten => 1}, sub { 'key' }, sub { [$_] });
is_deeply
    $hash,
    {key => $c},
    'returned values are flattened'
    ;
isa_ok $_, 'Mojo::Collection' for values %$hash;

$hash = $c->hashify_collect({flatten => 1}, sub { 'key' }, sub { $_ % 2 ? [$_] : $_ });
is_deeply
    $hash,
    {key => $c},
    'values that are already flattened work'
    ;
isa_ok $_, 'Mojo::Collection' for values %$hash;

$hash = $c->hashify_collect({flatten => 1}, sub { 'key' }, sub { $_ % 2 ? [$_] : ($_, $_) });
is_deeply
    $hash,
    {key => [1, 2, 2, 3]},
    'multiple values that are already flattened work'
    ;
isa_ok $_, 'Mojo::Collection' for values %$hash;

$hash = $c->hashify_collect({flatten => 1}, sub { $_ % 2 }, sub { [$_] });
is_deeply
    $hash,
    {0 => [2], 1 => [1, 3]},
    'flatten works with multiple keys'
    ;
isa_ok $_, 'Mojo::Collection' for values %$hash;

$hash = $c->hashify_collect({flatten => 1}, sub { $_ }, sub { [[], [$_], [[[$_]]]] });
is_deeply
    $hash,
    { map { $_ => [$_, $_] } @$c },
    'flatten handles nested arrays',
    ;
isa_ok $_, 'Mojo::Collection' for values %$hash;

done_testing;
