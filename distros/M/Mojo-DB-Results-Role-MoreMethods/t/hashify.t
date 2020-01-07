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
        test_only_final_value_matching_key_is_kept($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_single_key($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_multiple_keys($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_sub_key_multiple_keys($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_sub_used_as_key_and_value($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_single_value($db, $mojo_db_config->{drop_table_sql}, $mojo_db_config->{create_table_sql}, $role);
        test_struct_weird_column_names($db, $role);
    }
}

done_testing;

sub test_default_option_is_hash {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $alice = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    $db->insert(people => $bob);
    $db->insert(people => $alice);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'])
                  ->with_roles($role)
                  ->hashify('name')
                  ;
    is_deeply
        $hash,
        {Bob => $bob, Alice => $alice},
        'default values are hashes';
}

sub test_option_values {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $alice = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    $db->insert(people => $bob);
    $db->insert(people => $alice);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'])
                  ->with_roles($role)
                  ->hashify({array => 1}, 'name')
                  ;
    is_deeply
        $hash,
        {Bob => [@{$bob}{qw(name age favorite_food)}], Alice => [@{$alice}{qw(name age favorite_food)}]},
        'array option returns array for value';
    isa_ok $hash->{Bob}, 'ARRAY', 'ARRAY returned';
    isa_ok $hash->{Alice}, 'ARRAY', 'ARRAY returned';

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify({c => 1}, 'name')
               ;
    is_deeply
        $hash,
        {Bob => [@{$bob}{qw(name age favorite_food)}], Alice => [@{$alice}{qw(name age favorite_food)}]},
        'c option returns Mojo::Collection for value';
    isa_ok $hash->{Bob}, 'Mojo::Collection', 'Mojo::Collection returned';
    isa_ok $hash->{Alice}, 'Mojo::Collection', 'Mojo::Collection returned';

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify({hash => 1}, 'name')
               ;
    is_deeply
        $hash,
        {Bob => $bob, Alice => $alice},
        'hash option returns hash for value';

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify({struct => 1}, 'name')
               ;

    is scalar(keys %$hash), 2, 'two results returned';
    for my $person ($bob, $alice) {
        my $struct = $hash->{$person->{name}};
        can_ok $struct, keys %$person;

        for my $key (keys %$person) {
            is $struct->$key, $person->{$key}, 'struct method returns expected value';
        }
    }
}

sub test_only_final_value_matching_key_is_kept {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $alice = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    $db->insert(people => $bob);
    $db->insert(people => $alice);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ->hashify('age')
                  ;

    is_deeply
        $hash,
        {23 => $alice},
        'only final value matching key is kept';
}

sub test_single_key {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $alice = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    my $eve   = {name => 'Eve', age => 27, favorite_food => 'Nachos'};
    $db->insert(people => $bob);
    $db->insert(people => $alice);
    $db->insert(people => $eve);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ->hashify('name')
                  ;
    is_deeply
        $hash,
        {
            Bob   => $bob,
            Alice => $alice,
            Eve   => $eve,
        },
        'single key works';
}

sub test_multiple_keys {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $alice = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    my $eve   = {name => 'Eve', age => 27, favorite_food => 'Nachos'};
    $db->insert(people => $bob);
    $db->insert(people => $alice);
    $db->insert(people => $eve);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ->hashify(['name', 'age'])
                  ;
    is_deeply
        $hash,
        {
            Bob   => { 23 => $bob },
            Alice => { 23 => $alice },
            Eve   => { 27 => $eve },
        },
        'two keys returns a two level hash with correct value';

    $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
               ->with_roles($role)
               ->hashify(['favorite_food', 'name', 'age'])
               ;
    is_deeply
        $hash,
        {
            Pizza     => { Bob   => { 23 => $bob } },
            Hamburger => { Alice => { 23 => $alice } },
            Nachos    => { Eve   => { 27 => $eve } },
        },
        'three keys returns a three level hash with correct value';
}

sub test_sub_used_as_key_and_value {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $alice = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    $db->insert(people => $bob);
    $db->insert(people => $alice);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'])
                  ->with_roles($role)
                  ->hashify(
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
        {Bob => $bob, Alice => $alice},
        'no option uses hash in subs';

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify(
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
        {Bob => $bob, Alice => $alice},
        'empty option hash uses hash in subs';

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify(
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
        {Bob => [@{$bob}{qw(name age favorite_food)}], Alice => [@{$alice}{qw(name age favorite_food)}]},
        'array option uses array in subs';

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
               ->with_roles($role)
               ->hashify(
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
        {Bob => [@{$bob}{qw(name age favorite_food)}], Alice => [@{$alice}{qw(name age favorite_food)}]},
        'c option uses Mojo::Collection in subs';
    isa_ok $_, 'Mojo::Collection' for values %$hash;

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
              ->with_roles($role)
              ->hashify(
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
        {Bob => $bob, Alice => $alice},
        'hash option uses hash in subs';

    $hash = $db->select(people => ['name', 'age', 'favorite_food'])
              ->with_roles($role)
              ->hashify(
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

    for my $person ($bob, $alice) {
        my $struct = $hash->{$person->{name}};
        can_ok $struct, keys %$person;

        for my $key (keys %$person) {
            is $struct->$key, $person->{$key}, 'struct method returns expected value';
        }
    }
}

sub test_sub_key_multiple_keys {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $alice = {name => 'Alice', age => 23, favorite_food => 'Hamburger'};
    my $eve   = {name => 'Eve', age => 27, favorite_food => 'Nachos'};
    $db->insert(people => $bob);
    $db->insert(people => $alice);
    $db->insert(people => $eve);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ->hashify(sub { @{$_}{qw(name age)} })
                  ;
    is_deeply
        $hash,
        {
            Bob   => { 23 => $bob },
            Alice => { 23 => $alice },
            Eve   => { 27 => $eve },
        },
        'two keys returns a two level hash with correct value';

    $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
               ->with_roles($role)
               ->hashify(sub { @{$_}{qw(favorite_food name age)} })
               ;
    is_deeply
        $hash,
        {
            Pizza     => { Bob   => { 23 => $bob } },
            Hamburger => { Alice => { 23 => $alice } },
            Nachos    => { Eve   => { 27 => $eve } },
        },
        'three keys returns a three level hash with correct value';
}

sub test_single_value {
    my ($db, $drop_table_sql, $create_table_sql, $role) = @_;

    drop_and_create_db($db, $drop_table_sql, $create_table_sql);

    my $bob   = {name => 'Bob', age => 23, favorite_food => 'Pizza'};
    my $alice = {name => 'Alice', age => 24, favorite_food => 'Hamburger'};
    my $eve   = {name => 'Eve', age => 25, favorite_food => 'Nachos'};
    $db->insert(people => $bob);
    $db->insert(people => $alice);
    $db->insert(people => $eve);

    my $hash = $db->select(people => ['name', 'age', 'favorite_food'] => undef, {order_by => {-asc => 'id'}})
                  ->with_roles($role)
                  ->hashify('name', 'age')
                  ;
    is_deeply
        $hash,
        {
            Bob   => 23,
            Alice => 24,
            Eve   => 25,
        },
        'single value works';
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
                  ->hashify({struct => 1}, sub { $_->age }, 'first name')
                  ;
    is_deeply $hash, {23 => 'Bob'}, 'auto get_value sub gets value for weird column name';

    $hash = $db->select(people => ['first name', 'age'])
               ->with_roles($role)
               ->hashify({struct => 1}, 'first name', sub { $_->age })
               ;
    is_deeply $hash, {Bob => 23}, 'auto get_keys sub gets value for one weird column name';

    $hash = $db->select(people => ['first name', 'last name', 'age'])
               ->with_roles($role)
               ->hashify({struct => 1}, ['first name', 'last name'], sub { $_->age })
               ;
    is_deeply $hash, {Bob => {Seees => 23}}, 'auto get_keys sub gets value for two weird column names';
}

sub drop_and_create_db {
    my ($db, $drop_table_sql, $create_table_sql) = @_;

    ok $db->ping, 'connected';
    $db->query($drop_table_sql);
    $db->query($create_table_sql);
}
