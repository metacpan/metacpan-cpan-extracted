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

    my $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                        ->with_roles($role)
                        ->collect_by('name')
                        ;
    is_deeply
        $collection,
        [[$bob, $bob2], [$alice]],
        'default values are hashes';
    isa_ok $collection, 'Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;
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

    my $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                        ->with_roles($role)
                        ->collect_by({array => 1}, 'name')
                        ;
    is_deeply
        $collection,
        [
            [map { [@{$_}{qw(name age favorite_food)}] } $bob, $bob2],
            [ [@{$alice}{qw(name age favorite_food)}] ],
        ],
        'array option returns array for value';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;
    isa_ok $_, 'ARRAY', 'ARRAY returned' for $collection->[0]->each;
    isa_ok $_, 'ARRAY', 'ARRAY returned' for $collection->[1]->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by({c => 1}, 'name')
                     ;
    is_deeply
        $collection,
        [
            [map { [@{$_}{qw(name age favorite_food)}] } $bob, $bob2],
            [ [@{$alice}{qw(name age favorite_food)}] ],
        ],
        'c option returns Mojo::Collection for value';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;
    isa_ok $_, 'Mojo::Collection', 'Mojo::Collection returned' for $collection->[0]->each;
    isa_ok $_, 'Mojo::Collection', 'Mojo::Collection returned' for $collection->[1]->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by({hash => 1}, 'name')
                     ;
    is_deeply
        $collection,
        [[$bob, $bob2], [$alice]],
        'hash option returns hash for value';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;
    isa_ok $_, 'HASH', 'HASH returned' for $collection->[0]->each;
    isa_ok $_, 'HASH', 'HASH returned' for $collection->[1]->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by({struct => 1}, 'name')
                     ;
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    is $collection->size, 2, 'two collections';
    is $collection->[0]->size, 2, 'Bob collection is size 2';
    is $collection->[1]->size, 1, 'Alice collection is size 1';
    for my $person_and_struct (
        [$bob, $collection->[0][0]],
        [$bob2, $collection->[0][1]],
        [$alice, $collection->[1][0]],
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

    my $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                        ->with_roles($role)
                        ->collect_by('name')
                        ;
    is_deeply
        $collection,
        [
            [$bob, $bob2],
            [$alice],
            [$eve],
        ],
        'single key works';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;
}

sub test_multiple_keys {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob    = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $bob2   = {name => 'Bob', age => 23, favorite_food => 'Pizza Rolls'};
    my $bob3   = {name => 'Bob', age => 23, favorite_food => 'Pizza Rolls'};
    my $alice  = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    my $alice2 = {name => 'Alice', age => 23, favorite_food => 'Hamburger Helper'};
    my $eve    = {name => 'Eve', age => 27, favorite_food => 'Nachos'};
    my $eve2   = {name => 'Eve', age => 25, favorite_food => 'Cheetos'};
    $db->insert(people => $bob);
    $db->insert(people => $bob2);
    $db->insert(people => $bob3);
    $db->insert(people => $alice);
    $db->insert(people => $alice2);
    $db->insert(people => $eve);
    $db->insert(people => $eve2);

    my $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                        ->with_roles($role)
                        ->collect_by(['name', 'age'])
                        ;
    is_deeply
        $collection,
        [
            [$bob, $bob2, $bob3],
            [$alice, $alice2],
            [$eve],
            [$eve2],
        ],
        'two keys group correctly';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection', for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                     ->with_roles($role)
                     ->collect_by(['favorite_food', 'name', 'age'])
                     ;
    is_deeply
        $collection,
        [
            [$bob],
            [$bob2, $bob3],
            [$alice],
            [$alice2],
            [$eve],
            [$eve2],
        ],
        'three keys group correctly';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection', for $collection->each;
}

sub test_sub_key_multiple_keys {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob    = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $bob2   = {name => 'Bob', age => 23, favorite_food => 'Pizza Rolls'};
    my $bob3   = {name => 'Bob', age => 23, favorite_food => 'Pizza Rolls'};
    my $alice  = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    my $alice2 = {name => 'Alice', age => 23, favorite_food => 'Hamburger Helper'};
    my $eve    = {name => 'Eve', age => 27, favorite_food => 'Nachos'};
    my $eve2   = {name => 'Eve', age => 25, favorite_food => 'Cheetos'};
    $db->insert(people => $bob);
    $db->insert(people => $bob2);
    $db->insert(people => $bob3);
    $db->insert(people => $alice);
    $db->insert(people => $alice2);
    $db->insert(people => $eve);
    $db->insert(people => $eve2);

    my $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                        ->with_roles($role)
                        ->collect_by(sub { @{$_}{qw(name age)} })
                        ;
    is_deeply
        $collection,
        [
            [$bob, $bob2, $bob3],
            [$alice, $alice2],
            [$eve],
            [$eve2],
        ],
        'two keys group correctly';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection', for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                     ->with_roles($role)
                     ->collect_by(sub { @{$_}{qw(favorite_food name age)} })
                     ;
    is_deeply
        $collection,
        [
            [$bob],
            [$bob2, $bob3],
            [$alice],
            [$alice2],
            [$eve],
            [$eve2],
        ],
        'three keys group correctly';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection', for $collection->each;
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

    my $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                        ->with_roles($role)
                        ->collect_by(
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
        $collection,
        [[$bob, $bob2], [$alice]],
        'no option uses hash in subs';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [[$bob, $bob2], [$alice]],
        'empty option hash uses hash in subs';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [
                [@{$bob}{qw(name age favorite_food)}],
                [@{$bob2}{qw(name age favorite_food)}],
            ],
            [[@{$alice}{qw(name age favorite_food)}]],
        ],
        'array option uses array in subs';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;
    isa_ok $_, 'ARRAY' for map { $_->each } $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [
                [@{$bob}{qw(name age favorite_food)}],
                [@{$bob2}{qw(name age favorite_food)}],
            ],
            [[@{$alice}{qw(name age favorite_food)}]],
        ],
        'c option uses Mojo::Collection in subs';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;
    isa_ok $_, 'Mojo::Collection' for map { $_->each } $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                    ->with_roles($role)
                    ->collect_by(
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
        $collection,
        [[$bob, $bob2], [$alice]],
        'hash option uses hash in subs';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                    ->with_roles($role)
                    ->collect_by(
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
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    is $collection->size, 2, 'two collections';
    is $collection->[0]->size, 2, 'Bob collection is size 2';
    is $collection->[1]->size, 1, 'Alice collection is size 1';
    for my $person_and_struct (
        [$bob, $collection->[0][0]],
        [$bob2, $collection->[0][1]],
        [$alice, $collection->[1][0]],
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

    my $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                        ->with_roles($role)
                        ->collect_by('name', 'age')
                        ;
    is_deeply
        $collection,
        [
            [23, 27],
            [24],
            [25],
        ],
        'single value works';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;
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

    my $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                        ->with_roles($role)
                        ->collect_by('name', sub { $_->{age} })
                        ;
    is_deeply
        $collection,
        [
            [23, 27],
            [24],
            [25],
        ],
        'single returned value from get_values sub works';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;
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

    my $collection = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                        ->with_roles($role)
                        ->collect_by('name', sub { @{$_}{qw(name age favorite_food)} })
                        ;
    is_deeply
        $collection,
        [
            [ map { @{$_}{qw(name age favorite_food)} } $bob, $bob2 ],
            [ @{$alice}{qw(name age favorite_food)} ],
            [ @{$eve}{qw(name age favorite_food)} ],
        ],
        'multiple returned values from get_values sub works';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;
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

    note 'Test array';
    my $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                        ->with_roles($role)
                        ->collect_by({array => 1, flatten => 1}, sub { $_->[0] })
                        ;
    is_deeply
        $collection,
        [
            [map { @{$_}{qw(name age favorite_food)} } $bob, $bob2, $bob3],
            [ @{$alice}{qw(name age favorite_food)} ],
        ],
        'flatten works for default array value sub';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            [ @{$alice}{qw(name age)} ],
        ],
        'flatten works for provided value sub that returns list of values';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            [ @{$alice}{qw(name age)} ],
        ],
        'flatten works for provided value sub that returns arrayref';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [map { @{$_}{qw(age)} } $bob, $bob2, $bob3],
            [ $alice->{age} ],
        ],
        'flatten works for provided value sub that returns single value';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    note 'Test c';
    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
                         {c => 1, flatten => 1},
                         sub {
                             isa_ok $_, 'Mojo::Collection';
                             $_->[0]
                         },
                     )
                     ;
    is_deeply
        $collection,
        [
            [map { @{$_}{qw(name age favorite_food)} } $bob, $bob2, $bob3],
            [ @{$alice}{qw(name age favorite_food)} ],
        ],
        'flatten works for default c value sub';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            [ @{$alice}{qw(name age)} ],
        ],
        'flatten works for provided value sub that returns list of values';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            => [ @{$alice}{qw(name age)} ],
        ],
        'flatten works for provided value sub that returns arrayref';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [map { @{$_}{qw(age)} } $bob, $bob2, $bob3],
            [ $alice->{age} ],
        ],
        'flatten works for provided value sub that returns single value';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    note 'Test hash';
    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
                         {hash => 1, flatten => 1},
                         sub {
                             isa_ok $_, 'HASH';
                             $_->{name}
                         },
                     )
                     ;
    is_deeply
        $collection,
        [
            [map { @{$_}{qw(name age favorite_food)} } $bob, $bob2, $bob3],
            [ @{$alice}{qw(name age favorite_food)} ],
        ],
        'flatten works for default hash value sub';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            [ @{$alice}{qw(name age)} ],
        ],
        'flatten works for provided value sub that returns list of values';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            [ @{$alice}{qw(name age)} ],
        ],
        'flatten works for provided value sub that returns arrayref';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [map { @{$_}{qw(age)} } $bob, $bob2, $bob3],
            [ $alice->{age} ],
        ],
        'flatten works for provided value sub that returns single value';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    note 'Test struct';
    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
                         {struct => 1, flatten => 1},
                         sub {
                             can_ok $_, qw(name age favorite_food);
                             $_->name
                         },
                     )
                     ;
    is_deeply
        $collection,
        [
            [map { @{$_}{qw(name age favorite_food)} } $bob, $bob2, $bob3],
            [ @{$alice}{qw(name age favorite_food)} ],
        ],
        'flatten works for default struct value sub';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            [ @{$alice}{qw(name age)} ],
        ],
        'flatten works for provided value sub that returns list of values';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [map { @{$_}{qw(name age)} } $bob, $bob2, $bob3],
            [ @{$alice}{qw(name age)} ],
        ],
        'flatten works for provided value sub that returns arrayref';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['name', 'age', 'favorite_food'])
                     ->with_roles($role)
                     ->collect_by(
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
        $collection,
        [
            [map { @{$_}{qw(age)} } $bob, $bob2, $bob3],
            [ $alice->{age} ],
        ],
        'flatten works for provided value sub that returns single value';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;
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
    $db->insert(people => {'first name' => 'Bob', 'last name' => 'Smith', age => 24});

    my $collection = $db->select(people => ['first name', 'age'])
                        ->with_roles($role)
                        ->collect_by({struct => 1}, sub { $_->age }, 'first name')
                        ;
    is_deeply $collection, [['Bob'], ['Bob']], 'auto get_values sub gets value for weird column name';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['first name', 'age'])
                     ->with_roles($role)
                     ->collect_by({struct => 1}, 'first name', sub { $_->age })
                     ;
    is_deeply $collection, [[23, 24]], 'auto get_keys sub gets value for one weird column name';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;

    $collection = $db->select(people => ['first name', 'last name', 'age'])
                     ->with_roles($role)
                     ->collect_by({struct => 1}, ['first name', 'last name'], sub { $_->age })
                     ;
    is_deeply $collection, [[23], [24]], 'auto get_keys sub gets value for two weird column names';
    isa_ok $collection, 'Mojo::Collection', 'collect_by returns Mojo::Collection';
    isa_ok $_, 'Mojo::Collection' for $collection->each;
}

sub drop_and_create_db {
    my ($db, $drop_table_sql, $create_table_sql) = @_;

    ok $db->ping, 'connected';
    $db->query($drop_table_sql);
    $db->query($create_table_sql);
}
