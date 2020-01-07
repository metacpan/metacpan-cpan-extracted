use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Test::Warn;

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

for my $mojo_db_config (@mojo_dbs_config) {
    for my $role (qw(Mojo::DB::Results::Role::MoreMethods +MoreMethods)) {
        my $mojo_db = $mojo_db_config->{creator}->();
        note "Testing @{[ ref $mojo_db ]} with role $role";

        my $db = $mojo_db->db;
        test_default_option_is_hash($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_option_values($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_single_key($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_multiple_keys($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_sub_key_multiple_keys($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_sub_used_as_key_and_value($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_single_value($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_get_values_single_value_returned($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_get_values_multiple_values_returned($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_flatten($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_struct_weird_column_names($db, $role);
    }
}

done_testing;

sub test_default_option_is_hash {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $bob2  = {name => 'Bob', age => 24, favorite_food => 'Pizza Rolls'};
    my $alice = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    $db->insert(people => $bob);
    $db->insert(people => $bob2);
    $db->insert(people => $alice);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'])
                  ->with_roles($role)
                  ->hashify_collect('name')
                  ;
    is_deeply
        $hash,
        {Bob => [$bob, $bob2], Alice => [$alice]},
        'default values are hashes';
    isa_ok $_, 'Mojo::Collection' for values %$hash;
}

sub test_option_values {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $bob2  = {name => 'Bob', age => 24, favorite_food => 'Pizza Rolls'};
    my $alice = {name => 'Alice', age => 25, favorite_food => 'Hamburger'};
    $db->insert(people => $bob);
    $db->insert(people => $bob2);
    $db->insert(people => $alice);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'])
                  ->with_roles($role)
                  ->hashify_collect({array => 1}, 'name')
                  ;
    is_deeply
        $hash,
        {
            Bob => [map { [@{$_}{qw(name age favorite_food)}] } $bob, $bob2],
            Alice => [ [@{$alice}{qw(name age favorite_food)}] ]
        },
        'array option returns array for value';
    isa_ok $_, 'Mojo::Collection' for values %$hash;
    isa_ok $_, 'ARRAY', 'ARRAY returned' for $hash->{Bob}->each;
    isa_ok $_, 'ARRAY', 'ARRAY returned' for $hash->{Alice}->each;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect({c => 1}, 'name')
               ;
    is_deeply
        $hash,
        {
            Bob => [map { [@{$_}{qw(name age favorite_food)}] } $bob, $bob2],
            Alice => [ [@{$alice}{qw(name age favorite_food)}] ]
        },
        'c option returns Mojo::Collection for value';
    isa_ok $_, 'Mojo::Collection' for values %$hash;
    isa_ok $_, 'Mojo::Collection', 'Mojo::Collection returned' for $hash->{Bob}->each;
    isa_ok $_, 'Mojo::Collection', 'Mojo::Collection returned' for $hash->{Alice}->each;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect({hash => 1}, 'name')
               ;
    is_deeply
        $hash,
        {Bob => [$bob, $bob2], Alice => [$alice]},
        'hash option returns hash for value';
    isa_ok $_, 'Mojo::Collection' for values %$hash;
    isa_ok $_, 'HASH', 'HASH returned' for $hash->{Bob}->each;
    isa_ok $_, 'HASH', 'HASH returned' for $hash->{Alice}->each;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect({struct => 1}, 'name')
               ;
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    is scalar(keys %$hash), 2, 'two hash keys';
    is $hash->{Bob}->size, 2, 'Bob collection is size 2';
    is $hash->{Alice}->size, 1, 'Alice collection is size 1';
    for my $person_and_struct (
        [$bob, $hash->{Bob}[0]],
        [$bob2, $hash->{Bob}[1]],
        [$alice, $hash->{Alice}[0]],
    ) {
        my ($person, $struct) = @$person_and_struct;
        can_ok $struct, keys %$person;

        for my $key (keys %$person) {
            is $struct->$key, $person->{$key}, 'struct method returns expected value';
        }
    }
}

sub test_single_key {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $bob2  = {name => 'Bob', age => 25, favorite_food => 'Pizza Rolls'};
    my $alice = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    my $eve   = {name => 'Eve', age => 27, favorite_food => 'Nachos'};
    $db->insert(people => $bob);
    $db->insert(people => $bob2);
    $db->insert(people => $alice);
    $db->insert(people => $eve);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ->hashify_collect('name')
                  ;
    is_deeply
        $hash,
        {
            Bob   => [$bob, $bob2],
            Alice => [$alice],
            Eve   => [$eve],
        },
        'single key works';
    isa_ok $_, 'Mojo::Collection' for values %$hash;
}

sub test_multiple_keys {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $bob2  = {name => 'Bob', age => 23, favorite_food => 'Pizza Rolls'};
    my $alice = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    my $eve   = {name => 'Eve', age => 27, favorite_food => 'Nachos'};
    $db->insert(people => $bob);
    $db->insert(people => $bob2);
    $db->insert(people => $alice);
    $db->insert(people => $eve);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ->hashify_collect(['name', 'age'])
                  ;
    is_deeply
        $hash,
        {
            Bob   => { 23 => [$bob, $bob2] },
            Alice => { 23 => [$alice] },
            Eve   => { 27 => [$eve] },
        },
        'two keys returns a two level hash with correct value';
    isa_ok $_, 'Mojo::Collection', for map { values %$_ } @$hash{qw(Bob Alice Eve)};

    $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
               ->with_roles($role)
               ->hashify_collect(['favorite_food', 'name', 'age'])
               ;
    is_deeply
        $hash,
        {
            Pizza         => { Bob   => { 23 => [$bob] } },
            'Pizza Rolls' => { Bob   => { 23 => [$bob2] } },
            Hamburger     => { Alice => { 23 => [$alice] } },
            Nachos        => { Eve   => { 27 => [$eve] } },
        },
        'three keys returns a three level hash with correct value';
    isa_ok $hash->{Pizza}{Bob}{23}, 'Mojo::Collection';
    isa_ok $hash->{'Pizza Rolls'}{Bob}{23}, 'Mojo::Collection';
    isa_ok $hash->{Hamburger}{Alice}{23}, 'Mojo::Collection';
    isa_ok $hash->{Nachos}{Eve}{27}, 'Mojo::Collection';
}

sub test_sub_key_multiple_keys {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $bob2  = {name => 'Bob', age => 23, favorite_food => 'Pizza Rolls'};
    my $alice = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    my $eve   = {name => 'Eve', age => 27, favorite_food => 'Nachos'};
    $db->insert(people => $bob);
    $db->insert(people => $bob2);
    $db->insert(people => $alice);
    $db->insert(people => $eve);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ->hashify_collect(sub { @{$_}{qw(name age)} })
                  ;
    is_deeply
        $hash,
        {
            Bob   => { 23 => [$bob, $bob2] },
            Alice => { 23 => [$alice] },
            Eve   => { 27 => [$eve] },
        },
        'two keys returns a two level hash with correct value';
    isa_ok $_, 'Mojo::Collection' for map { values %$_ } values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
               ->with_roles($role)
               ->hashify_collect(sub { @{$_}{qw(favorite_food name age)} })
               ;
    is_deeply
        $hash,
        {
            Pizza         => { Bob   => { 23 => [$bob] } },
            'Pizza Rolls' => { Bob   => { 23 => [$bob2] } },
            Hamburger     => { Alice => { 23 => [$alice] } },
            Nachos        => { Eve   => { 27 => [$eve] } },
        },
        'three keys returns a three level hash with correct value';
    isa_ok $hash->{Pizza}{Bob}{23}, 'Mojo::Collection';
    isa_ok $hash->{'Pizza Rolls'}{Bob}{23}, 'Mojo::Collection';
    isa_ok $hash->{Hamburger}{Alice}{23}, 'Mojo::Collection';
    isa_ok $hash->{Nachos}{Eve}{27}, 'Mojo::Collection';
}

sub test_sub_used_as_key_and_value {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $bob2  = {name => 'Bob', age => 25, favorite_food => 'Pizza Rolls'};
    my $alice = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    $db->insert(people => $bob);
    $db->insert(people => $bob2);
    $db->insert(people => $alice);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ->hashify_collect(
                      sub {
                          isa_ok $_, 'HASH', 'HASH passed to key sub as default';
                          $_->{name}
                      },
                      sub {
                          isa_ok $_, 'HASH', 'HASH passed to value sub as default';
                          $_
                      },
                  );
    is_deeply
        $hash,
        {Bob => [$bob, $bob2], Alice => [$alice]},
        'no option uses hash in subs';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
               ->with_roles($role)
               ->hashify_collect(
                   {},
                   sub {
                       isa_ok $_, 'HASH', 'HASH passed to key sub as default';
                       $_->{name}
                   },
                   sub {
                       isa_ok $_, 'HASH', 'HASH passed to value sub as default';
                       $_
                   },
               );
    is_deeply
        $hash,
        {Bob => [$bob, $bob2], Alice => [$alice]},
        'empty option hash uses hash in subs';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
               ->with_roles($role)
               ->hashify_collect(
                    {array => 1},
                    sub {
                        isa_ok $_, 'ARRAY', 'ARRAY passed to key sub';
                        $_->[0]
                    },
                    sub {
                        isa_ok $_, 'ARRAY', 'ARRAY passed to value sub';
                        $_
                    },
                );
    is_deeply
        $hash,
        {
            Bob => [
                [@{$bob}{qw(name age favorite_food)}],
                [@{$bob2}{qw(name age favorite_food)}],
            ],
            Alice => [[@{$alice}{qw(name age favorite_food)}]]
        },
        'array option uses array in subs';
    isa_ok $_, 'Mojo::Collection' for values %$hash;
    isa_ok $_, 'ARRAY' for map { $_->each } values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
               ->with_roles($role)
               ->hashify_collect(
                    {c => 1},
                    sub {
                        isa_ok $_, 'Mojo::Collection', 'Mojo::Collection passed to key sub';
                        $_->[0]
                    },
                    sub {
                        isa_ok $_, 'Mojo::Collection', 'Mojo::Collection passed to value sub';
                        $_
                    },
                );
    is_deeply
        $hash,
        {
            Bob => [
                [@{$bob}{qw(name age favorite_food)}],
                [@{$bob2}{qw(name age favorite_food)}],
            ],
            Alice => [[@{$alice}{qw(name age favorite_food)}]]
        },
        'c option uses Mojo::Collection in subs';
    isa_ok $_, 'Mojo::Collection' for values %$hash;
    isa_ok $_, 'Mojo::Collection' for map { $_->each } values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
              ->with_roles($role)
              ->hashify_collect(
                  {hash => 1},
                  sub {
                      isa_ok $_, 'HASH', 'HASH passed to key sub';
                      $_->{name}
                  },
                  sub {
                      isa_ok $_, 'HASH', 'HASH passed to value sub';
                      $_
                  },
              );
    is_deeply
        $hash,
        {Bob => [$bob, $bob2], Alice => [$alice]},
        'hash option uses hash in subs';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
              ->with_roles($role)
              ->hashify_collect(
                  {struct => 1},
                  sub {
                      can_ok $_, 'name', 'age', 'favorite_food';
                      $_->name
                  },
                  sub {
                      can_ok $_, 'name', 'age', 'favorite_food';
                      $_
                  },
              );

    is scalar(keys %$hash), 2, 'two hash keys';
    is $hash->{Bob}->size, 2, 'Bob collection is size 2';
    is $hash->{Alice}->size, 1, 'Alice collection is size 1';
    for my $person_and_struct (
        [$bob, $hash->{Bob}[0]],
        [$bob2, $hash->{Bob}[1]],
        [$alice, $hash->{Alice}[0]],
    ) {
        my ($person, $struct) = @$person_and_struct;
        can_ok $struct, keys %$person;

        for my $key (keys %$person) {
            is $struct->$key, $person->{$key}, 'struct method returns expected value';
        }
    }
}

sub test_single_value {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $bob2  = {name => 'Bob', age => 27, favorite_food => 'Pizza Rolls'};
    my $alice = {name => 'Alice', age => 24, favorite_food => 'Hamburger'};
    my $eve   = {name => 'Eve', age => 25, favorite_food => 'Nachos'};
    $db->insert(people => $bob);
    $db->insert(people => $bob2);
    $db->insert(people => $alice);
    $db->insert(people => $eve);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ->hashify_collect('name', 'age')
                  ;
    is_deeply
        $hash,
        {
            Bob   => [23, 27],
            Alice => [24],
            Eve   => [25],
        },
        'single value works';
    isa_ok $_, 'Mojo::Collection' for values %$hash;
}

sub test_get_values_single_value_returned {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $bob2  = {name => 'Bob', age => 27, favorite_food => 'Pizza Rolls'};
    my $alice = {name => 'Alice', age => 24, favorite_food => 'Hamburger'};
    my $eve   = {name => 'Eve', age => 25, favorite_food => 'Nachos'};
    $db->insert(people => $bob);
    $db->insert(people => $bob2);
    $db->insert(people => $alice);
    $db->insert(people => $eve);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ->hashify_collect('name', sub { $_->{age} })
                  ;
    is_deeply
        $hash,
        {
            Bob   => [23, 27],
            Alice => [24],
            Eve   => [25],
        },
        'single returned value from get_values sub works';
    isa_ok $_, 'Mojo::Collection' for values %$hash;
}

sub test_get_values_multiple_values_returned {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $bob2  = {name => 'Bob', age => 27, favorite_food => 'Pizza Rolls'};
    my $alice = {name => 'Alice', age => 24, favorite_food => 'Hamburger'};
    my $eve   = {name => 'Eve', age => 25, favorite_food => 'Nachos'};
    $db->insert(people => $bob);
    $db->insert(people => $bob2);
    $db->insert(people => $alice);
    $db->insert(people => $eve);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ->hashify_collect('name', sub { @{$_}{qw(name age favorite_food)} })
                  ;
    is_deeply
        $hash,
        {
            Bob   => [ map { @{$_}{qw(name age favorite_food)} } $bob, $bob2 ],
            Alice => [ @{$alice}{qw(name age favorite_food)} ],
            Eve   => [ @{$eve}{qw(name age favorite_food)} ],
        },
        'multiple returned values from get_values sub works';
    isa_ok $_, 'Mojo::Collection' for values %$hash;
}

sub test_flatten {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $bob2  = {name => 'Bob', age => 24, favorite_food => 'Pizza Rolls'};
    my $bob3  = {name => 'Bob', age => 25, favorite_food => 'Calzone'};
    my $alice = {name => 'Alice', age => 25, favorite_food => 'Hamburger'};
    $db->insert(people => $bob);
    $db->insert(people => $bob2);
    $db->insert(people => $bob3);
    $db->insert(people => $alice);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'])
                  ->with_roles($role)
                  ->hashify_collect({array => 1, flatten => 1}, sub { $_->[0] })
                  ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(name age favorite_food)} } $bob, $bob2, $bob3],
            Alice => [ @{$alice}{qw(name age favorite_food)} ]
        },
        'flatten works for default array value sub';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {array => 1, flatten => 1},
                   sub {
                       isa_ok $_, 'ARRAY';
                       $_->[0]
                   },
                   sub {
                       isa_ok $_, 'ARRAY';
                       @{$_}[0, 1]
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            Alice => [ @{$alice}{qw(name age)} ]
        },
        'flatten works for provided value sub that returns list of values';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {array => 1, flatten => 1},
                   sub {
                       isa_ok $_, 'ARRAY';
                       $_->[0]
                   },
                   sub {
                       isa_ok $_, 'ARRAY';
                       [ @{$_}[0, 1] ]
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            Alice => [ @{$alice}{qw(name age)} ]
        },
        'flatten works for provided value sub that returns arrayref';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {array => 1, flatten => 1},
                   sub {
                       isa_ok $_, 'ARRAY';
                       $_->[0]
                   },
                   sub {
                       isa_ok $_, 'ARRAY';
                       $_->[1]
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(age)} } $bob, $bob2, $bob3],
            Alice => [ $alice->{age} ]
        },
        'flatten works for provided value sub that returns single value';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {c => 1, flatten => 1},
                   sub {
                       isa_ok $_, 'Mojo::Collection';
                       $_->[0]
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(name age favorite_food)} } $bob, $bob2, $bob3],
            Alice => [ @{$alice}{qw(name age favorite_food)} ]
        },
        'flatten works for default c value sub';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {c => 1, flatten => 1},
                   sub {
                       isa_ok $_, 'Mojo::Collection';
                       $_->[0]
                   },
                   sub {
                       isa_ok $_, 'Mojo::Collection';
                       @{$_}[0, 1]
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            Alice => [ @{$alice}{qw(name age)} ]
        },
        'flatten works for provided value sub that returns list of values';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {c => 1, flatten => 1},
                   sub {
                       isa_ok $_, 'Mojo::Collection';
                       $_->[0]
                   },
                   sub {
                       isa_ok $_, 'Mojo::Collection';
                       [ @{$_}[0, 1] ]
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            Alice => [ @{$alice}{qw(name age)} ]
        },
        'flatten works for provided value sub that returns arrayref';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {c => 1, flatten => 1},
                   sub {
                       isa_ok $_, 'Mojo::Collection';
                       $_->[0]
                   },
                   sub {
                       isa_ok $_, 'Mojo::Collection';
                       $_->[1]
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(age)} } $bob, $bob2, $bob3],
            Alice => [ $alice->{age} ]
        },
        'flatten works for provided value sub that returns single value';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {hash => 1, flatten => 1},
                   sub {
                       isa_ok $_, 'HASH';
                       $_->{name}
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(name age favorite_food)} } $bob, $bob2, $bob3],
            Alice => [ @{$alice}{qw(name age favorite_food)} ]
        },
        'flatten works for default hash value sub';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {hash => 1, flatten => 1},
                   sub {
                       isa_ok $_, 'HASH';
                       $_->{name}
                   },
                   sub {
                       isa_ok $_, 'HASH';
                       @{$_}{qw(name age)}
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            Alice => [ @{$alice}{qw(name age)} ]
        },
        'flatten works for provided value sub that returns list of values';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {hash => 1, flatten => 1},
                   sub {
                       isa_ok $_, 'HASH';
                       $_->{name}
                   },
                   sub {
                       isa_ok $_, 'HASH';
                       [ @{$_}{qw(name age)} ]
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            Alice => [ @{$alice}{qw(name age)} ]
        },
        'flatten works for provided value sub that returns arrayref';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {hash => 1, flatten => 1},
                   sub {
                       isa_ok $_, 'HASH';
                       $_->{name}
                   },
                   sub {
                       isa_ok $_, 'HASH';
                       $_->{age}
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(age)} } $bob, $bob2, $bob3],
            Alice => [ $alice->{age} ]
        },
        'flatten works for provided value sub that returns single value';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {struct => 1, flatten => 1},
                   sub {
                       can_ok $_, qw(name age favorite_food);
                       $_->name
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(name age favorite_food)} } $bob, $bob2, $bob3],
            Alice => [ @{$alice}{qw(name age favorite_food)} ]
        },
        'flatten works for default struct value sub';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {struct => 1, flatten => 1},
                   sub {
                       can_ok $_, 'name', 'age', 'favorite_food';
                       $_->name
                   },
                   sub {
                       can_ok $_, 'name', 'age', 'favorite_food';
                       $_->name, $_->age
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            Alice => [ @{$alice}{qw(name age)} ]
        },
        'flatten works for provided value sub that returns list of values';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {struct => 1, flatten => 1},
                   sub {
                       can_ok $_, 'name', 'age', 'favorite_food';
                       $_->name
                   },
                   sub {
                       can_ok $_, 'name', 'age', 'favorite_food';
                       [$_->name, $_->age]
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            Alice => [ @{$alice}{qw(name age)} ]
        },
        'flatten works for provided value sub that returns arrayref';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify_collect(
                   {struct => 1, flatten => 1},
                   sub {
                       can_ok $_, 'name', 'age', 'favorite_food';
                       $_->name
                   },
                   sub {
                       can_ok $_, 'name', 'age', 'favorite_food';
                       $_->age
                   },
               )
               ;
    is_deeply
        $hash,
        {
            Bob => [map { @{$_}{qw(age)} } $bob, $bob2, $bob3],
            Alice => [ $alice->{age} ]
        },
        'flatten works for provided value sub that returns single value';
    isa_ok $_, 'Mojo::Collection' for values %$hash;
}

sub test_struct_weird_column_names {
    my ($db, $role) = @_;

    $db->query('DROP TABLE IF EXISTS people');
    my $create_table_sql =
        ref $db eq 'Mojo::Pg::Database' ? q{
                                             CREATE TABLE people (
                                                 "first name" VARCHAR(255) NOT NULL,
                                                 "last name" VARCHAR(255) NOT NULL,
                                                 age integer NOT NULL
                                             )
                                           }
                                        : q{
                                              CREATE TABLE people (
                                                  `first name` VARCHAR(255) NOT NULL,
                                                  `last name` VARCHAR(255) NOT NULL,
                                                  `age` INT(11) NOT NULL
                                              )
                                            }
                                        ;
    $db->query($create_table_sql);
    $db->insert(people => {'first name' => 'Bob', 'last name' => 'Seees', age => 23});

    my $hash = $db->select(people => ['first name', 'age'])
                  ->with_roles($role)
                  ->hashify_collect({struct => 1}, sub { $_->age }, 'first name')
                  ;
    is_deeply $hash, {23 => ['Bob']}, 'auto get_values sub gets value for weird column name';
    isa_ok $hash->{23}, 'Mojo::Collection';

    $hash = $db->select(people => ['first name', 'age'])
               ->with_roles($role)
               ->hashify_collect({struct => 1}, 'first name', sub { $_->age })
               ;
    is_deeply $hash, {Bob => [23]}, 'auto get_keys sub gets value for one weird column name';
    isa_ok $hash->{Bob}, 'Mojo::Collection';

    $hash = $db->select(people => ['first name', 'last name', 'age'])
               ->with_roles($role)
               ->hashify_collect({struct => 1}, ['first name', 'last name'], sub { $_->age })
               ;
    is_deeply $hash, {Bob => {Seees => [23]}}, 'auto get_keys sub gets value for two weird column names';
    isa_ok $hash->{Bob}{Seees}, 'Mojo::Collection';
}

sub drop_and_create_db {
    my ($db, $drop_table_sql, $create_table_sql) = @_;

    ok $db->ping, 'connected';
    $db->query($drop_table_sql);
    $db->query($create_table_sql);
}
