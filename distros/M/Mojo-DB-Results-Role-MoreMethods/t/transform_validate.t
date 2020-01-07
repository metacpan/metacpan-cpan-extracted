use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::Warn;
use Mojo::Util 'dumper';

plan skip_all => q{TEST_MYSQL=mysql://root@/test or TEST_POSTGRESQL=postgresql://root@/test}
    unless $ENV{TEST_MYSQL} or $ENV{TEST_POSTGRESQL};

my @mojo_dbs_config = (
    $ENV{TEST_MYSQL} ? do {
        require Mojo::mysql;

        {
            creator => sub { Mojo::mysql->new($ENV{TEST_MYSQL}) },
            drop_table_sql => 'DROP TABLE IF EXISTS people',
            create_table_sql => q{
                CREATE TABLE `people` (
                    `id` INT(11) NOT NULL AUTO_INCREMENT,
                    `name` VARCHAR(255) NOT NULL,
                    `age` INT(11) NOT NULL,
                    `favorite_food` VARCHAR(255) NOT NULL,
                    PRIMARY KEY (`id`)
                )
                AUTO_INCREMENT=1
            },
        }
    } : (),
    $ENV{TEST_POSTGRESQL} ? do {
        require Mojo::Pg;

        {
            creator => sub { Mojo::Pg->new($ENV{TEST_POSTGRESQL}) },
            drop_table_sql => 'DROP TABLE IF EXISTS people',
            create_table_sql => q{
                CREATE TABLE people (
                    id serial NOT NULL primary key,
                    name VARCHAR(255) NOT NULL,
                    age integer NOT NULL,
                    favorite_food VARCHAR(255) NOT NULL
                )
            },
        }
    } : (),
);

my @methods = qw(hashify hashify_collect collect_by);
my @options = (undef, {}, map { {$_ => 1} } qw(array c struct hash));

for my $mojo_db_config (@mojo_dbs_config) {
    for my $role (qw(Mojo::DB::Results::Role::MoreMethods +MoreMethods)) {
        my $mojo_db = $mojo_db_config->{creator}->();
        note "Testing @{[ ref $mojo_db ]} with role $role";

        my $db = $mojo_db->db;
        ok $db->ping, 'connected';

        test_methods($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role, \@methods, \@options);
    }
}

done_testing;

sub test_methods {
    my ($db, $drop_table_sql, $create_table_sql, $role, $methods, $options) = @_;

    for my $method (@$methods) {
        note "Testing method $method";

        $db->query($drop_table_sql);
        $db->query($create_table_sql);
        $db->insert(people => {name => 'Bob', age => 23, favorite_food => 'Pizza'});

        test_useless_options_warning($db, $role, $method);
        test_validate_transform_options($db, $role, $method);

        for my $option (@$options) {
            note "Testing method $method and option " . dumper $option;
            test_method($db, $role, $method, $option ? $option : ());
        }
    }
}

sub test_useless_options_warning {
    my ($db, $role, $method) = @_;

    note 'Test useless options warning occurs when key and value are not subroutines';
    for my $test_values (
        ['column key and column value', 'name', 'age'],
        ['array key and column value', ['name', 'age'], 'age'],
    ) {
        my ($prefix, $key, $value) = @$test_values;

        for my $option (qw(c hash struct)) {
            my $results = get_results($db, $role);
            warning_like
                { $results->$method({$option => 1}, $key, $value) }
                qr/Useless type option provided. array will be used for performance./,
                "$prefix with $option option warns";

            if ($method ne 'hashify') {
                my $results = get_results($db, $role);
                warning_like
                    { $results->$method({$option => 1, flatten => 1}, $key, $value) }
                    qr/Useless type option provided. array will be used for performance./,
                    "$prefix with $option option and flatten option warns";
            }
        }

        my $results = get_results($db, $role);
        warning_is
            { $results->$method({array => 1}, $key, $value) }
            undef,
            qq{$prefix with array option doesn't warn};

        if ($method ne 'hashify') {
            my $results = get_results($db, $role);
            warning_is
                { $results->$method({array => 1, flatten => 1}, $key, $value) }
                undef,
                qq{$prefix with array and flatten options doesn't warn};
        }
    }

    note 'Test useless options warning does not occur when key and value are subroutines';
    for my $test_values (
        ['sub key and column value', sub { 'name' }, 'age'],
        ['column key and sub value', 'name', sub { 'age' } ],
        ['array key and sub value', ['name', 'age'], sub { 'age' } ],
        ['sub key and sub value', sub { 'name' }, sub { 'age' }],
    ) {
        my ($prefix, $key, $value) = @$test_values;

        for my $option (qw(array c hash struct), $method eq 'hashify' ? () : ('flatten')) {
            my $results = get_results($db, $role);
            warning_is
                { $results->$method({$option => 1}, $key, $value) }
                undef,
                qq{$prefix with $option option doesn't warn};

            if ($method ne 'hashify') {
                my $results = get_results($db, $role);
                warning_is
                    { $results->$method({$option => 1, flatten => 1}, $key, $value) }
                    undef,
                    qq{$prefix with $option option and flatten option doesn't warn};
            }
        }
    }

    note 'Test useless options warning does not occur with unspecified/empty options';
    for my $option (undef, {}) {
        my @options            = defined $option ? ($option) : ();
        my $option_description = defined $option ? 'empty hash option' : 'no options';

        my $results = get_results($db, $role);
        warning_is
            { $results->$method(@options, 'name', 'age') }
            undef,
            qq{$method with $option_description doesn't warn};
    }

    note 'Test no warnings when value is not specified and flatten is not provided';
    for my $option (qw(array c hash struct)) {
        my $results = get_results($db, $role);
        warning_is
            { $results->$method({$option => 1}, 'name') }
            undef,
            qq{$option option with no value doesn't warn};
    }

    if ($method ne 'hashify') {
        for my $test_values (
            ['single key', 'name'],
            ['array key', ['name', 'age']],
        ) {
            my ($prefix, $key) = @$test_values;

            note "Test warning occurs with $prefix when flatten option is specified with type option and no value";
            for my $option (qw(c hash struct)) {
                my $results = get_results($db, $role);
                warning_like
                    { $results->$method({$option => 1, flatten => 1}, $key) }
                    qr/Useless type option provided. array will be used for performance./,
                    "$prefix with flatten option with $option option warns when no value is provided";
            }

            my $results = get_results($db, $role);
            warning_like
                { $results->$method({array => 1, flatten => 1}, $key) }
                undef,
                qq{$prefix with flatten option with array option doesn't warn when no value is provided};
        }
    }
}

sub test_validate_transform_options {
    my ($db, $role, $method) = @_;

    if ($method eq 'hashify') {
        my $results = get_results($db, $role);
        throws_ok
            { $results->$method({flatten => 1}, 'name') }
            qr/flatten not allowed/,
            'flatten option throws for hashify';
    } else {
        my $results = get_results($db, $role);
        lives_ok
            { $results->$method({flatten => 1}, 'name') }
            qq"flatten option lives for $method";
    }

    my $one_key_value_pair_error = $method eq 'hashify' ? 'one key/value pair is allowed for options'
                                                        : 'In addition to flatten, one key/value pair is allowed for options';
    my $results = get_results($db, $role);
    throws_ok
        { $results->$method({array => 1, c => 1}, 'name') }
        qr/\Q$one_key_value_pair_error\E/,
        'two key value options throws';

    if ($method ne 'hashify') {
        $results = get_results($db, $role);
        throws_ok
            { $results->$method({flatten => 1, array => 1, c => 1}, 'name') }
            qr/\Q$one_key_value_pair_error\E/,
            'two key value options with flatten option throws';
    }

    $results = get_results($db, $role);
    throws_ok
        { $results->$method({array => 1, c => 1, hash => 1}, 'name') }
        qr/\Q$one_key_value_pair_error\E/,
        'three key value options throws';

    if ($method ne 'hashify') {
        $results = get_results($db, $role);
        throws_ok
            { $results->$method({flatten => 1, array => 1, c => 1, hash => 1}, 'name') }
            qr/\Q$one_key_value_pair_error\E/,
            'three key value options with flatten option throws';
    }

    my @options = qw(array c hash struct);
    for my $option (@options) {
        $results = get_results($db, $role);
        lives_ok
            { $results->$method({$option => 1}, 'name') }
            "$option option lives";

        if ($method ne 'hashify') {
            $results = get_results($db, $role);
            lives_ok
                { $results->$method({flatten => 1, $option => 1}, 'name') }
                "$option option with flatten option lives";
        }
    }

    my $options_sep_comma = join ', ', @options;
    for my $unknown_option (map { "unknown_$_" } @options) {
        $results = get_results($db, $role);
        throws_ok
            { $results->$method({$unknown_option => 1}, 'name') }
            qr/option must be one of: $options_sep_comma/,
            "unknown $unknown_option option throws";

        if ($method ne 'hashify') {
            $results = get_results($db, $role);
            throws_ok
                { $results->$method({flatten => 1, $unknown_option => 1}, 'name') }
                qr/option must be one of: $options_sep_comma/,
                "unknown $unknown_option option with flatten option throws";
        }
    }
}

sub test_method {
    my ($db, $role, $method, @options) = @_;

    test_parse_transform_key_validate($db, $role, $method, @options);
    test_parse_transform_value_validate($db, $role, $method, @options);
    test_unknown_columns_throw($db, $role, $method, @options);
}

sub test_parse_transform_key_validate {
    my ($db, $role, $method, @options) = @_;

    my $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, \'key') }
        qr/key must be an arrayref, a sub or a non-empty string, but had ref 'SCALAR'/,
        'SCALAR key throws';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, \{}) }
        qr/key must be an arrayref, a sub or a non-empty string, but had ref 'REF'/,
        'REF key throws';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, []) }
        qr/key array must not be empty/,
        'empty key array throws';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, [undef]) }
        qr/key array elements must be defined and non-empty/,
        'undef key array element throws';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, ['']) }
        qr/key array elements must be defined and non-empty/,
        'empty string key array element throws';

    $results = get_results($db, $role);
    lives_ok
        { $results->$method(@options, ['name']) }
        'key array with one column lives';

    $results = get_results($db, $role);
    lives_ok
        { $results->$method(@options, ['name', 'age']) }
        'key array with two columns lives';

    $results = get_results($db, $role);
    lives_ok
        { $results->$method(@options, sub { 'key' }) }
        'sub key lives';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, undef) }
        qr/key was undefined or an empty string/,
        'undef key throws';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, '') }
        qr/key was undefined or an empty string/,
        'empty string key throws';

    $results = get_results($db, $role);
    lives_ok
        { $results->$method(@options, 'name') }
        'string column key lives';
}

sub test_parse_transform_value_validate {
    my ($db, $role, $method, @options) = @_;

    my $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, 'name', []) }
        qr/value must be a sub or non-empty string, but was 'ARRAY'/,
        'ARRAY value throws';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, 'name', {}) }
        qr/value must be a sub or non-empty string, but was 'HASH'/,
        'HASH value throws';

    $results = get_results($db, $role);
    lives_ok
        { $results->$method(@options, 'name', sub { 'value' }) }
        'CODE value lives';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, 'name', undef) }
        qr/value must not be undefined or an empty string/,
        'undef value throws';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, 'name', '') }
        qr/value must not be undefined or an empty string/,
        'empty string value throws';

    $results = get_results($db, $role);
    lives_ok
        { $results->$method(@options, 'name', 'age') }
        'string column value lives';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, 'name', 'age', 'extra_arg') }
        qr/too many arguments provided \(more than one value\)/,
        'one extra value argument throws';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, 'name', 'age', 'extra_arg', 'other_extra_arg') }
        qr/too many arguments provided \(more than one value\)/,
        'two extra value arguments throws';
}

sub test_unknown_columns_throw {
    my ($db, $role, $method, @options) = @_;

    my $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, 'unknown', 'age') }
        qr/could not find column 'unknown' in returned columns/,
        'unknown column as string column key throws';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, ['unknown', 'name'], 'age') }
        qr/could not find column 'unknown' in returned columns/,
        'unknown column as in key array throws';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, ['name', 'unknown'], 'age') }
        qr/could not find column 'unknown' in returned columns/,
        'unknown column as in key array throws';

    $results = get_results($db, $role);
    throws_ok
        { $results->$method(@options, 'name', 'unknown') }
        qr/could not find column 'unknown' in returned columns/,
        'unknown column as string column value throws';

    $results = get_results($db, $role);
    lives_ok
        { $results->$method(@options, 'name', 'age') }
        'known key and value columns live';

    $results = get_results($db, $role);
    lives_ok
        { $results->$method(@options, 'name') }
        'known key column and no value column lives';

    $results = get_results($db, $role);
    lives_ok
        { $results->$method(@options, ['name', 'age'], 'age') }
        'known key columns in array and value column live';

    $results = get_results($db, $role);
    lives_ok
        { $results->$method(@options, ['name', 'age']) }
        'known key columns in array and no value live';
}

sub get_results { shift->select(people => '*')->with_roles(shift) }
