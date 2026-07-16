use v5.40;
use experimental 'signatures';
use Test2::V0;
use PAGI::StructuredParameters;

# A note on the source: 'body'/'query' parameters arrive as a flat hash whose
# keys encode nesting (name.first, email[0], children[0].age). 'permitted' is a
# lenient whitelist: only the named, present keys survive, and the flat keys are
# reconstructed into the nested shape the rule describes.

subtest 'scalar keys: whitelist drops unlisted and absent keys' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => { username => 'jnap', password => 'secret', evil => 'haxor' },
    );
    is $sp->permitted('username', 'password'),
        { username => 'jnap', password => 'secret' },
        'only permitted, present keys survive';
};

subtest 'absent permitted key is simply omitted (lenient)' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => { username => 'jnap' },
    );
    is $sp->permitted('username', 'password'),
        { username => 'jnap' },
        'missing key is dropped, not an error';
};

subtest 'nested hash rule: name => [first, last] from name.first/name.last' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => {
            'name.first' => 'John',
            'name.last'  => 'Napiorkowski',
            'name.evil'  => 'drop me',
        },
    );
    is $sp->permitted('name' => ['first', 'last']),
        { name => { first => 'John', last => 'Napiorkowski' } },
        'subkeys reconstructed into a nested hash; unlisted subkey dropped';
};

subtest 'array rule: +{ email => [] } from email[0]/email[1]' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => {
            'email[0]' => 'a@example.com',
            'email[1]' => 'b@example.com',
        },
    );
    is $sp->permitted(+{ email => [] }),
        { email => ['a@example.com', 'b@example.com'] },
        'indexed keys reconstructed into an ordered array';
};

# Array-of-hashes uses a single bracket with scalar subkeys, matching the
# original Catalyst grammar (+{ key => ['subkey', ...] }). The design doc's
# double-bracketed +{ children => [['name','age']] } is a notational slip.
subtest 'array-of-hashes: +{ children => [name, age] }' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => {
            'children[0].name' => 'Alice',
            'children[0].age'  => '7',
            'children[1].name' => 'Bob',
            'children[1].age'  => '9',
        },
    );
    is $sp->permitted(+{ children => ['name', 'age'] }),
        {
            children => [
                { name => 'Alice', age => '7' },
                { name => 'Bob',   age => '9' },
            ],
        },
        'indexed dotted keys reconstructed into an array of hashes';
};

# "Full nesting": a subkey that is itself a nested hash, via key => [\@subkeys].
subtest 'array-of-hashes with a nested-hash subkey' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => {
            'cards[0].number'    => '4111',
            'cards[0].exp'       => '2030-01',
            'cards[1].number'    => '5500',
            'cards[1].exp.year'  => '2031',
            'cards[1].exp.month' => '02',
        },
    );
    is $sp->permitted(+{ cards => ['number', 'exp', exp => ['year', 'month']] }),
        {
            cards => [
                { number => '4111', exp => '2030-01' },
                { number => '5500', exp => { year => '2031', month => '02' } },
            ],
        },
        'each row independently reconstructs scalar or nested-hash subkeys';
};

done_testing;
