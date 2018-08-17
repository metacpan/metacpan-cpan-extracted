# © 2017-2018 GoodData Corporation

use Test::More tests => 1 + 6;
use Test::Warnings;
use Test::Deep;

use Hash::Util qw[];
use Ref::Util qw[ is_arrayref is_hashref ];

use Sub::Params;

sub it_behaves_like_named_or_positional_arguments {
    my ($title, %params) = @_;
    Hash::Util::lock_keys %params, qw[ with_args with_names expected ];

    my @got = Sub::Params::named_or_positional_arguments(
        args => $params{with_args},
        names => $params{with_names},
    );

    return cmp_bag \@got, [ %{ $params{expected} } ], $title
        if is_hashref( $params{expected} );
    return cmp_deeply \@got, $params{expected}, $title
        if is_arrayref( $params{expected} );
    return fail "invalid arguments ($title)";
}

it_behaves_like_named_or_positional_arguments 'without arguments returns empty array' => (
    with_args => [],
    with_names => [qw[ foo bar ]],
    expected => [],
);

it_behaves_like_named_or_positional_arguments 'without names returns arguments' => (
    with_args => [qw[ 1 2 3 ]],
    with_names => [],
    expected => [qw[ 1 2 3 ]],
);

it_behaves_like_named_or_positional_arguments 'with positional arguments' => (
    with_args => [qw[ 1 2 3 ]],
    with_names => [qw[ foo bar baz ]],
    expected => { foo => 1, bar => 2, baz => 3 },
);

it_behaves_like_named_or_positional_arguments 'with unspecified positional arguments' => (
    with_args => [qw[ 1 2 ]],
    with_names => [qw[ foo bar baz ]],
    expected => { foo => 1, bar => 2, baz => undef },
);

it_behaves_like_named_or_positional_arguments 'with named arguments' => (
    with_args => [ foo => 1, bar => 2 ],
    with_names => [qw[ foo bar baz ]],
    expected => { foo => 1, bar => 2 },
);

it_behaves_like_named_or_positional_arguments 'with named arguments via hashref' => (
    with_args => [ { foo => 1, bar => 2 } ],
    with_names => [qw[ foo bar baz ]],
    expected => { foo => 1, bar => 2 },
);

