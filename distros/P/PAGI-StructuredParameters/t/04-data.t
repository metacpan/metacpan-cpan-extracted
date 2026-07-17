use strict;
use warnings;
use Test2::V0;
use PAGI::StructuredParameters;
use PAGI::StructuredParameters::Exception::InvalidArrayPointer;

# 'data' is for already-nested body data (such as decoded JSON). The structure is
# walked directly rather than reconstructed from flat keys, and array values are
# left alone (no flattening).

subtest 'whitelists nested data, dropping unlisted keys' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'data',
        src_data => {
            username => 'jnap',
            secret   => 'drop me',
            name     => { first => 'John', last => 'N', evil => 'drop' },
        },
    );
    is $sp->permitted('username', name => ['first', 'last']),
        { username => 'jnap', name => { first => 'John', last => 'N' } },
        'nested hash is whitelisted in place';
};

subtest 'arrays are kept as-is, not flattened' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'data',
        src_data => { tags => ['a', 'b', 'c'] },
    );
    is $sp->permitted(+{ tags => [] }), { tags => ['a', 'b', 'c'] },
        'a bare-array rule returns the whole array unchanged';
};

subtest 'array of hashes is whitelisted per element' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'data',
        src_data => {
            cards => [
                { number => '4111', exp => '2030', cvv => 'drop' },
                { number => '5500', exp => '2031', cvv => 'drop' },
            ],
        },
    );
    is $sp->permitted(+{ cards => ['number', 'exp'] }),
        {
            cards => [
                { number => '4111', exp => '2030' },
                { number => '5500', exp => '2031' },
            ],
        },
        'each element keeps only the listed subkeys';
};

subtest 'a non-array where an array is expected is an error' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'data',
        src_data => { cards => { not => 'an array' } },
    );
    my $err = dies { $sp->permitted(+{ cards => ['number'] }) };
    isa_ok $err, ['PAGI::StructuredParameters::Exception::InvalidArrayPointer'],
        'wrong shape raises InvalidArrayPointer';
    is $err->status, 400, 'reported as a 400';
};

subtest 'required works against data too' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'data',
        src_data => { title => 'x' },
    );
    my $seen;
    my $cb = sub { my ($ctx, $missing) = @_; $seen = $missing; die "stop\n" };
    eval { $sp->required('title', 'body', $cb) };
    is $seen, ['body'], 'missing nested-data key is reported';
};

done_testing;
