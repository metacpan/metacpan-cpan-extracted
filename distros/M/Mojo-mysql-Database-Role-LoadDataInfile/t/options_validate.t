use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojo::mysql;
use Mojo::mysql::Database::Role::LoadDataInfile;

plan skip_all => q{TEST_ONLINE="mysql://root@/test;mysql_local_infile=1"} unless $ENV{TEST_ONLINE};

my $mysql = Mojo::mysql->new($ENV{TEST_ONLINE});
my $db = $mysql->db;
ok $db->ping, 'connected';

drop_and_create_table_and_assert_emtpy();

my $people = [
    {
        name => 'Bob',
        age => 23,
    },
    {
        name => 'Alice',
        age => 27,
    },
];

note 'Test low_priority and concurrent';
throws_ok {
        $db->load_data_infile(
            low_priority => 1,
            concurrent => 1,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    qr/cannot set both low_priority and concurrent/,
    'setting both low_priority and concurrent throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

lives_ok {
        $db->load_data_infile(
            low_priority => 1,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    'setting low_priority and not concurrent lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'expected number of rows in table';

drop_and_create_table_and_assert_emtpy();

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 1,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    'setting concurrent and not low_priority lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'expected number of rows in table';

note 'Test replace and ignore';
drop_and_create_table_and_assert_emtpy();

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 1,
            ignore => 1,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    qr/cannot set both replace and ignore/,
    'setting both replace and ignore throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 1,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    'setting replace and not ignore lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'expected number of rows in table';

drop_and_create_table_and_assert_emtpy();

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 1,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    'setting ignore and not replace lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'expected number of rows in table';


note 'Test table';
drop_and_create_table_and_assert_emtpy();

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => undef,
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    qr/table required for load_data_infile/,
    'undef table throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => '',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    qr/table required for load_data_infile/,
    'empty table throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

drop_and_create_table_and_assert_emtpy('0');

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => '0',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    'table name 0 lives';
is $db->query('SELECT COUNT(id) FROM `0`')->array->[0], 2, 'expected number of rows in table';

drop_and_create_table_and_assert_emtpy('the people');

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'the people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    'table name `the people` lives';
is $db->query('SELECT COUNT(id) FROM `the people`')->array->[0], 2, 'expected number of rows in table';


note 'Test partition';
drop_and_create_table_and_assert_emtpy();

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => {},
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    qr/partition must be an arrayref if provided/,
    'hashref partition fails';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => undef,
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    'undef partition lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'expected number of rows in table';

drop_and_create_table_and_assert_emtpy();

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    'empty partition lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'expected number of rows in table';

drop_and_create_table_and_assert_emtpy();

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => [],
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    'empty partition arrayref lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'expected number of rows in table';

$db->query("drop table if exists people");
$db->query(q{
    create table `people` (
        `id` int(11) not null auto_increment,
        `name` varchar(255) not null,
        `age` int(11) not null,
        `insert_time` datetime null default null,
        primary key (`id`)
    )
    auto_increment=1
    partition by list(id) (
        partition ponethree values in (1, 3),
        partition ptwo values in (2),
        partition pfour values in (4)
    );
});
my $partition_people = [
    {
        name => 'bob',
        age => 23,
    },
    {
        name => 'alice',
        age => 27,
    },
    {
        name => 'eve',
        age => 19,
    },
];

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => ['ponethree', 'ptwo'],
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $partition_people,
        )
    }
    'partition with values lives';
is $db->query('select count(id) from people')->array->[0], 3, 'expected number of rows in table';

$db->query("drop table if exists people");
$db->query(q{
    create table `people` (
        `id` int(11) not null auto_increment,
        `name` varchar(255) not null,
        `age` int(11) not null,
        `insert_time` datetime null default null,
        primary key (`id`)
    )
    auto_increment=1
    partition by list(id) (
        partition `p one three` values in (1, 3),
        partition `p two` values in (2),
        partition `p four` values in (4)
    );
});
$partition_people = [
    {
        name => 'bob',
        age => 23,
    },
    {
        name => 'alice',
        age => 27,
    },
    {
        name => 'eve',
        age => 19,
    },
];

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => ['p one three', 'p two'],
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $partition_people,
        )
    }
    'partition with unusual names lives';
is $db->query('select count(id) from people')->array->[0], 3, 'expected number of rows in table';


note 'Test character_set and tempfile_open_mode';
drop_and_create_table_and_assert_emtpy();

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => 'utf8',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    qr/character_set and tempfile_open_mode must both be set when one is/,
    'setting character_set without tempfile_open_mode throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '>:encoding(UTF-8)',
            set => '',
            rows => $people,
        )
    }
    qr/character_set and tempfile_open_mode must both be set when one is/,
    'setting tempfile_open_mode without character_set throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => 'utf8',
            tempfile_open_mode => '>:encoding(UTF-8)',
            set => '',
            rows => $people,
        )
    }
    'setting character_set and tempfile_open_mode lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'expected number of rows in table';


note 'Test set';
drop_and_create_table_and_assert_emtpy();

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => {},
            rows => $people,
        )
    }
    qr/set must be an arrayref if provided/,
    'hashref set fails';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => undef,
            rows => $people,
        )
    }
    'undef set lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'expected number of rows in table';

drop_and_create_table_and_assert_emtpy();

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    'empty set lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'expected number of rows in table';

drop_and_create_table_and_assert_emtpy();

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => [],
            rows => $people,
        )
    }
    'empty set arrayref lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'expected number of rows in table';

drop_and_create_table_and_assert_emtpy();

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => [{ insert_time => 'NOW()' }],
            rows => $people,
        )
    }
    'set with values lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'expected number of rows in table';


note 'Test rows';
drop_and_create_table_and_assert_emtpy();

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => undef,
        )
    }
    qr/rows required for load_data_infile/,
    'undef rows throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => '',
        )
    }
    qr/rows required for load_data_infile/,
    'empty string rows throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => {},
        )
    }
    qr/rows must be an arrayref/,
    'hashref rows throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => [],
        )
    }
    qr/rows cannot be empty/,
    'empty arrayref rows throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
        )
    }
    'non-empty arrayref rows lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'expected number of rows in table';


note 'Test columns';
drop_and_create_table_and_assert_emtpy();

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
            columns => [],
        )
    }
    qr/columns array cannot be empty/,
    'empty columns array throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
            columns => [undef],
        )
    }
    qr/columns elements cannot be undef or an empty string/,
    'undef column throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
            columns => [''],
        )
    }
    qr/columns elements cannot be undef or an empty string/,
    'empty string column throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

{
    no warnings 'uninitialized'; # for the undef key

    throws_ok {
            $db->load_data_infile(
                low_priority => 0,
                concurrent => 0,
                replace => 0,
                ignore => 0,
                table => 'people',
                partition => '',
                character_set => '',
                tempfile_open_mode => '',
                set => '',
                rows => $people,
                columns => [{ undef, 'column' }],
            )
        }
        qr/columns elements cannot be undef or an empty string/,
        'undef hash key column throws';
}
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
            columns => [{ '' => 'column' }],
        )
    }
    qr/columns elements cannot be undef or an empty string/,
    'empty string hash key column throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
            columns => [{ 'key' => undef }],
        )
    }
    qr/columns elements cannot be undef or an empty string/,
    'undef hash value column throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
            columns => [{ 'key' => '' }],
        )
    }
    qr/columns elements cannot be undef or an empty string/,
    'empty string hash value column throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
            columns => [{name => 'name', key => 'value'}, 'age'],
        )
    }
    qr/hashrefs passed to columns must have only one key and value/,
    'multiple keys/values for columns hashref throws';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
            columns => [{name => 'name'}, 'age'],
        )
    }
    'columns hashref with one key and value lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'people table is empty';

drop_and_create_table_and_assert_emtpy();

throws_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => [[]],
            columns => [{name => 'name'}, 'age'],
        )
    }
    qr/cannot provide hashes in columns when rows contains arrayrefs/,
    'hashref columns not allowed when rows contains arrayrefs';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 0, 'people table is empty';

lives_ok {
        $db->load_data_infile(
            low_priority => 0,
            concurrent => 0,
            replace => 0,
            ignore => 0,
            table => 'people',
            partition => '',
            character_set => '',
            tempfile_open_mode => '',
            set => '',
            rows => $people,
            columns => ['name', 'age'],
        )
    }
    'columns with string column names lives';
is $db->query('SELECT COUNT(id) FROM people')->array->[0], 2, 'people table is empty';

done_testing;

sub drop_and_create_table_and_assert_emtpy {
    my $table_name = shift // 'people';

    $db->query("DROP TABLE IF EXISTS `$table_name`");
    $db->query(qq{
        CREATE TABLE `$table_name` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(255) NOT NULL,
            `age` INT(11) NOT NULL,
            `insert_time` DATETIME NULL DEFAULT NULL,
            PRIMARY KEY (`id`)
        )
        AUTO_INCREMENT=1
    });
    is $db->query("SELECT COUNT(id) FROM `$table_name`")->array->[0], 0, "$table_name table is empty";
}
