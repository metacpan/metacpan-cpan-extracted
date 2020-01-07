use Mojo::Base -strict;
use Test::More;

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
        ok $db->ping, 'connected';
        $db->query($mojo_db_config->{drop_table_sql});
        $db->query($mojo_db_config->{create_table_sql});

        note 'Test empty table';
        my $collections = $db->select(people => ['name'], undef, {-asc => 'id'})->with_roles($role)->collections;
        isa_ok $collections, 'Mojo::Collection';
        is $collections->size, 0, 'collections is empty';

        note 'Test one row in table';
        $db->insert(people => {name => 'Bob', age => 23, favorite_food => 'Pizza'});
        $collections = $db->select(people => ['name'], undef, {-asc => 'id'})->with_roles($role)->collections;
        isa_ok $collections, 'Mojo::Collection';
        is $collections->size, 1, 'collections has size 1';
        isa_ok $collections->[0], 'Mojo::Collection';
        is_deeply $collections, [['Bob']];

        note 'Test two rows in table';
        $db->insert(people => {name => 'Alice', age => 27, favorite_food => 'Hamburgers'});
        $collections = $db->select(people => ['name'], undef, {-asc => 'id'})->with_roles($role)->collections;
        isa_ok $collections, 'Mojo::Collection';
        is $collections->size, 2, 'collections has size 2';
        isa_ok $_, 'Mojo::Collection' for $collections->each;
        is_deeply $collections, [['Bob'], ['Alice']];

        note 'Test three rows in table';
        $db->insert(people => {name => 'Eve', age => 33, favorite_food => 'Sushi'});
        $collections = $db->select(people => ['name'], undef, {-asc => 'id'})->with_roles($role)->collections;
        isa_ok $collections, 'Mojo::Collection';
        is $collections->size, 3, 'collections has size 3';
        isa_ok $_, 'Mojo::Collection' for $collections->each;
        is_deeply $collections, [['Bob'], ['Alice'], ['Eve']];

        note 'Test selecting multiple columns';
        $collections = $db->select(people => ['name', 'favorite_food'], undef, {-asc => 'id'})->with_roles($role)->collections;
        isa_ok $collections, 'Mojo::Collection';
        is $collections->size, 3, 'collections has size 3';
        isa_ok $_, 'Mojo::Collection' for $collections->each;
        is_deeply $collections, [[Bob => 'Pizza'], [Alice => 'Hamburgers'], [Eve => 'Sushi']];
    }
}

done_testing;
