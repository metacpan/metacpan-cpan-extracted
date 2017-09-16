use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Fatal;

use boolean;
use IO::Handle;
use Set::Object;

BEGIN { use_ok('Net::Amazon::DynamoDB::Marshaler'); }

# If the value is undef, use Null ('NULL')
sub test_undef() {
    my $item = {
        user_id => undef,
    };
    my $item_dynamodb = {
        user_id => { NULL => '1' },
    };
    cmp_deeply(
        dynamodb_marshal($item),
        $item_dynamodb,
        'undef marshalled to NULL',
    );
    cmp_deeply(
        dynamodb_unmarshal($item_dynamodb),
        $item,
        'NULL unmarshalled to undef',
    );
}

# If the value is an empty string, use Null ('NULL')
sub test_empty_string() {
    my $item = {
        user_id => '',
    };
    my $item_dynamodb = {
        user_id => { NULL => '1' },
    };
    cmp_deeply(
        dynamodb_marshal($item),
        $item_dynamodb,
        'empty string marshalled to NULL',
    );
}

# If the value is a number, use Number ('N').
sub test_number() {
    my $item = {
        user_id => '1234',
        pct_complete => 0.33,
    };
    my $item_dynamodb = {
        user_id => { N => '1234' },
        pct_complete => { N => '0.33' },
    };
    cmp_deeply(
        dynamodb_marshal($item),
        $item_dynamodb,
        'numbers marshalled to N',
    );
    cmp_deeply(
        dynamodb_unmarshal($item_dynamodb),
        $item,
        q|N's unmarshalled to numbers|,
    );
}

# If it's a number, but is too large/precise for DynamoDB, use String('S').
sub test_out_of_range_number() {
    my $item = {
        ok_large            => '1E+125',
        ok_small            => '1E-129',
        ok_small_negative   => '-1E-129',
        ok_large_negative   => '-1E+125',
        ok_precise          => 1x38,
        too_large           => '1E+126',
        too_small           => '1E-130',
        too_small_negative  => '-1E-130',
        too_large_negative  => '-1E+126',
        too_precise         => 1x39,
        too_precise2        => '1.'.(1x38),
        super_large         => '6e3341866116', # this evaluates to 0
    };
    cmp_deeply(
        dynamodb_marshal($item),
        {
            ok_large => {
                N => '1E+125',
            },
            ok_small => {
                N => '1E-129',
            },
            ok_small_negative => {
                N => '-1E-129',
            },
            ok_large_negative => {
                N => '-1E+125',
            },
            ok_precise => {
                N => 1x38,
            },
            too_large => {
                S => '1E+126',
            },
            too_small => {
                S => '1E-130',
            },
            too_small_negative => {
                S => '-1E-130',
            },
            too_large_negative => {
                S => '-1E+126',
            },
            too_precise => {
                S => 1x39,
            },
            too_precise2 => {
                S => '1.'.(1x38),
            },
            super_large => {
                S => '6e3341866116',
            }
        },
        'out-of-bounds numbers marshalled to S',
    );
}

# For any other non-reference, use String ('S').
sub test_scalar() {
    my $item = {
        first_name => 'John',
        description => 'John is a very good boy',
    };
    my $item_dynamodb = {
        first_name => { S => 'John' },
        description => { S => 'John is a very good boy' },
    };
    cmp_deeply(
        dynamodb_marshal($item),
        $item_dynamodb,
        'strings marshalled to S',
    );
    cmp_deeply(
        dynamodb_unmarshal($item_dynamodb),
        $item,
        q|S's unmarshalled to strings|,
    );
}

# If the value is an arrayref, use List ('L').
sub test_list() {
    my $item = {
        tags => [
            'complete',
            'development',
            1234,
        ],
    };
    my $item_dynamodb = {
        tags => {
            L => [
                { S => 'complete' },
                { S => 'development' },
                { N => '1234' },
            ],
        },
    };
    cmp_deeply(
        dynamodb_marshal($item),
        $item_dynamodb,
        'arrayrefs marshalled to L',
    );
    cmp_deeply(
        dynamodb_unmarshal($item_dynamodb),
        $item,
        'L unmarshalled to arrayref',
    );
}

# If the value is a hashref, use Map ('M').
sub test_map() {
    my $item = {
        scores => {
            math => 95,
            english => 80,
        },
    };
    my $item_dynamodb = {
        scores => {
            M => {
                math => { N => '95'},
                english => { N => '80'},
            },
        },
    };
    cmp_deeply(
        dynamodb_marshal($item),
        $item_dynamodb,
        'hashref marshalled to M',
    );
    cmp_deeply(
        dynamodb_unmarshal($item_dynamodb),
        $item,
        'M unmarshalled to hashref',
    );
}

# If the value isa boolean, use Boolean ('BOOL').
sub test_boolean() {
    my $item = {
        active => true,
        disabled => false,
    };
    my $item_dynamodb = {
        active => { BOOL => '1' },
        disabled => { BOOL => '0' },
    };
    cmp_deeply(
        dynamodb_marshal($item),
        $item_dynamodb,
        'booleans marshalled to BOOL',
    );
    cmp_deeply(
        dynamodb_unmarshal($item_dynamodb),
        $item,
        'BOOL unmarshalled to boolean',
    );
}

# If the value isa Set::Object, use Number Set ('NS') if all members are
# numbers.
sub test_number_set() {
    my $item = {
        scores => Set::Object->new(5, 7, 25, 32.4),
    };
    my $item_dynamodb = {
        scores => {
            NS => [5, 7, 25, 32.4],
        },
    };
    cmp_deeply(
        dynamodb_marshal($item),
        {
            scores => {
                NS => set(5, 7, 25, 32.4),
            },
        },
        'Set::Object with numbers marshalled to NS',
    );

    my $unmarshalled = dynamodb_unmarshal($item_dynamodb);
    cmp_deeply(
        $unmarshalled,
        {
            scores => isa('Set::Object'),
        },
        'NS unmarshalled to Set::Object',
    ) or return;

    cmp_deeply(
        [ $unmarshalled->{scores}->elements ],
        set(5, 7, 25, 32.4),
        'unmarshalled NS has correct elements',
    );
}

# If the value isa Set::Object, use String Set ('SS') if one member is not
# a number.
sub test_string_set() {
    my $item = {
        tags => Set::Object->new(54, 'clothing', 'female'),
    };
    my $item_dynamodb = {
        tags => {
            SS => ['54', 'clothing', 'female'],
        },
    };
    cmp_deeply(
        dynamodb_marshal($item),
        {
            tags => {
                SS => set('54', 'clothing', 'female'),
            },
        },
        'Set::Object with non-number marshalled to SS',
    );

    my $unmarshalled = dynamodb_unmarshal($item_dynamodb);
    cmp_deeply(
        $unmarshalled,
        {
            tags => isa('Set::Object'),
        },
        'SS unmarshalled to Set::Object',
    ) or return;

    cmp_deeply(
        [ $unmarshalled->{tags}->elements ],
        set('54', 'clothing', 'female'),
        'unmarshalled SS has correct elements',
    );
}

# If the value isa Set::Object, and a member is a reference, throw an error.
sub test_set_error() {
    like(
        exception {
            dynamodb_marshal({
                tags => Set::Object->new('large', { foo => 'bar' }),
            });
        },
        qr/Sets can only contain strings and numbers/,
        'Error thrown trying to marshall a set with a reference',
    );
}

# An un-convertable value value should throw an error.
sub test_other() {
    like(
        exception {
            dynamodb_marshal({
                filehandle => IO::Handle->new(),
            });
        },
        qr/unable to marshal value: IO::Handle/,
        'Error thrown trying to marshall an unknown value',
    );
}

# Test nested data structure
sub test_complex() {
    my @codes = (1234, 5678);
    my @roles = ('user', 'student');
    my $item = {
        id => 25,
        first_name => 'John',
        last_name => 'Doe',
        active => true,
        admin => false,
        codes => Set::Object->new(@codes),
        roles => Set::Object->new(@roles),
        delete_date => undef,
        favorites => ['math', 'physics', 'chemistry'],
        relationships => {
            teachers => [12, 25],
            employees => [],
            students => {
                past => [11, 45],
                current => [6, 32],
            }
        },
        events => [
            {
                type => 'login',
                date => '2017-07-01',
            },
            {
                type => 'purchase',
                date => '2017-07-02',
            },
        ],
    };
    my $item_dynamodb = {
        id => { N => '25' },
        first_name => { S => 'John' },
        last_name => { S => 'Doe' },
        active => { BOOL => 1 },
        admin => { BOOL => 0 },
        codes => { NS => \@codes },
        roles => { SS => \@roles },
        delete_date => { NULL => 1 },
        favorites => {
            L => [
                { S => 'math' },
                { S => 'physics' },
                { S => 'chemistry' },
            ],
        },
        relationships => {
            M => {
                students => {
                    M => {
                        past => {
                            L => [
                                { N => '11' },
                                { N => '45' },
                            ]
                        },
                        current => {
                            L => [
                                { N => '6' },
                                { N => '32' },
                            ],
                        },
                    },
                },
                teachers => {
                    L => [
                        { N => '12' },
                        { N => '25' },
                    ],
                },
                employees => {
                    L => [],
                },
            },
        },
        events => {
            L => [
                {
                    M => {
                        type => { S => 'login' },
                        date => { S => '2017-07-01' },
                    },
                },
                {
                    M => {
                        type => { S => 'purchase' },
                        date => { S => '2017-07-02' },
                    },
                },
            ],
        },
    };
    cmp_deeply(
        dynamodb_marshal($item),
        {
            %$item_dynamodb,
            codes => { NS => set(@codes) },
            roles => { SS => set(@roles) },
        },
        'nested data structure marshalled correctly',
    );
    cmp_deeply(
        dynamodb_unmarshal($item_dynamodb),
        {
            %$item,
            codes => isa('Set::Object'),
            roles => isa('Set::Object'),
        },
        'nested data structure unmarshalled correctly',
    );
}

sub test_force_type_string() {
    my $item = {
        username => '1234',
        email_address => 'john@example.com',
        age => 24,
        family => undef,
        nickname => '',
        active => true,
        disabled => false,
    };
    cmp_deeply(
        dynamodb_marshal($item),
        {
            username      => { N => '1234' },
            email_address => { S => 'john@example.com' },
            age           => { N => 24 },
            family        => { NULL => 1 },
            nickname      => { NULL => 1 },
            active        => { BOOL => 1 },
            disabled      => { BOOL => 0 },
        },
        'attribute marshalled to derived types with no force_type',
    );
    my $force_type = {
        username => 'S',
        family   => 'S',
        nickname => 'S',
        active   => 'S',
        disabled => 'S',
    };
    cmp_deeply(
        dynamodb_marshal($item, force_type => $force_type),
        {
            username      => { S => '1234' },
            email_address => { S => 'john@example.com' },
            age           => { N => 24 },
            active        => { S => '1' },
            disabled      => { S => '0' },
        },
        'attributes marshalled to S via force_type, undefs dropped',
    );
}

sub test_force_type_number() {
    my $item = {
        user_id  => '1234',
        rank     => undef,
        age      => 'twenty-five',
        active   => true,
        disabled => false,
    };
    cmp_deeply(
        dynamodb_marshal($item),
        {
            user_id  => { N => '1234' },
            rank     => { NULL => 1 },
            age      => { S => 'twenty-five' },
            active   => { BOOL => 1 },
            disabled => { BOOL => 0 },
        },
        'attribute marshalled to derived types with no force_type',
    );
    my $force_type = {
        user_id  => 'N',
        rank     => 'N',
        age      => 'N',
        active   => 'N',
        disabled => 'N',
    };
    cmp_deeply(
        dynamodb_marshal($item, force_type => $force_type),
        {
            user_id  => { N => '1234' },
            active   => { N => '1' },
            disabled => { N => '0' },
        },
        'attributes marshalled to N via force_type, undefs dropped',
    );
}

sub test_force_type_errors() {
    my $item = {
        zip_code => '01453',
        colors   => Set::Object->new(qw(red yellow green)),
        ages     => Set::Object->new(qw(23 54 42)),
    };

    cmp_deeply(
        dynamodb_marshal($item, force_type => {}),
        {
            zip_code => { N => '01453' },
            colors   => { SS => set(qw(red yellow green)) },
            ages     => { NS => set(qw(23 54 42)) },
        },
        'attributes look OK without force_type',
    );

    like(
        exception {
            dynamodb_marshal($item, force_type => { colors => 'S' });
        },
        qr/force_type not supported for sets yet/,
        'Error thrown trying to apply force_type to string set',
    );

    like(
        exception {
            dynamodb_marshal($item, force_type => { ages => 'S' });
        },
        qr/force_type not supported for sets yet/,
        'Error thrown trying to apply force_type to number set',
    );

    cmp_deeply(
        dynamodb_marshal($item, force_type => { zip_code => 'S' }),
        {
            zip_code => { S => '01453' },
            colors   => { SS => set(qw(red yellow green)) },
            ages     => { NS => set(qw(23 54 42)) },
        },
        'applying force_type to non-set values in item with sets works',
    );

    like(
        exception {
            dynamodb_marshal($item, force_type => { ages => 'L' });
        },
        qr/invalid force_type value for "ages"/,
        'Error thrown trying to force_type to an L',
    );
}

sub test_force_type_list() {
    my $zip_vals = [
        '11510',
        undef,
        '60185',
        '01902',
        'one-three-six-five-two',
    ];
    my $item = {
        zip_codes => $zip_vals,
        zip_code_strings => $zip_vals,
        zip_code_numbers => $zip_vals,
    };
    my $force_type = {
        zip_code_strings => 'S',
        zip_code_numbers => 'N',
    };

    cmp_deeply(
        dynamodb_marshal($item, force_type => $force_type),
        {
            zip_codes => {
                L => [
                    { N => '11510' },
                    { NULL => 1 },
                    { N => '60185' },
                    { N => '01902' },
                    { S => 'one-three-six-five-two' },
                ],
            },
            zip_code_strings => {
                L => [
                    { S => '11510' },
                    { S => '60185' },
                    { S => '01902' },
                    { S => 'one-three-six-five-two' },
                ],
            },
            zip_code_numbers => {
                L => [
                    { N => '11510' },
                    { N => '60185' },
                    { N => '01902' },
                ],
            },
        },
        'force_type applied correctly to list',
    );
}

sub test_force_type_map() {
    my $item = {
        address => {
            street => '1234 Main',
            apt => '',
            zip => '01234',
        },
        external_ids => {
            database1 => '5246',
            database2 => {
                person_id => 165034,
                person_code => 'a23cds5',
            }
        },
    };
    my $force_type = {
        address => 'S',
        external_ids => 'N',
    };
    cmp_deeply(
        dynamodb_marshal($item, force_type => $force_type),
        {
            address => {
                M => {
                    street => { S => '1234 Main' },
                    zip => { S => '01234' },
                },
            },
            external_ids => {
                M => {
                    database1 => { N => '5246' },
                    database2 => {
                        M => {
                            person_id => { N => 165034 },
                        },
                    },
                },
            },
        },
        'force_type applied correctly to map',
    );
}

sub test_force_type_complex() {
    my $item = {
        username => 'jsmith',
        details => {
            first_name => 'John',
            age => 34,
            suffix => undef,
            roles => [qw(author editor)],
            address => {
                number => 1234,
                street => 'Main St.',
                city => 'Los Angeles',
                state => 'CA',
            },
            favorites => [
                {
                    name => '1984',
                    author => 'George Orwell',
                },
                {
                    name => 'Our Mutual Friend',
                    author => 'Charles Dickens',
                },
            ],
        },
    };
    my $force_type = {
        details => 'S',
    };
    cmp_deeply(
        dynamodb_marshal($item, force_type => $force_type),
        {
            username => { S => 'jsmith' },
            details => {
                M => {
                    first_name => { S => 'John' },
                    age => { S => '34' },
                    roles => {
                        L => [
                            { S => 'author' },
                            { S => 'editor' },
                        ],
                    },
                    address => {
                        M => {
                            number => { S => '1234' },
                            street => { S => 'Main St.' },
                            city => { S => => 'Los Angeles' },
                            state => { S => 'CA' },
                        },
                    },
                    favorites => {
                        L => [
                            {
                                M => {
                                    name => { S => '1984' },
                                    author => { S => 'George Orwell' },
                                },
                            },
                            {
                                M => {
                                    name => { S => 'Our Mutual Friend' },
                                    author => { S => 'Charles Dickens' },
                                },
                            },
                        ],
                    },
                },
            },
        },
        'force_type applied correctly to map',
    );
}

test_undef();
test_empty_string();
test_number();
test_out_of_range_number();
test_scalar();
test_list();
test_map();
test_boolean();
test_number_set();
test_string_set();
test_set_error();
test_other();
test_complex();
test_force_type_string();
test_force_type_number();
test_force_type_errors();
test_force_type_list();
test_force_type_map();
test_force_type_complex();

done_testing;
