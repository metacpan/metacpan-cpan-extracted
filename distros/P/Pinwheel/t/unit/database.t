#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 80;

use Pinwheel::Database qw(describe fetchone_tables fetchall_tables finish_all prepare);

my %sql = (
    find_all_one => q{
        SELECT * FROM one ORDER BY id
    },
    find_all_two => q{
        SELECT * FROM two ORDER BY id
    },
    find_both => q{
        SELECT o.*, t.*
        FROM one o, two t
        WHERE o.id = t.one_id
        ORDER BY o.id
    },
    find_all_one_three => q{
        SELECT a.*, 'foobar' blah, b.*
        FROM one a
        INNER JOIN three b ON a.id = b.one_id
        ORDER BY a.id
    },
    count_one => q{
        SELECT COUNT(*) FROM one
    },
    find_nothing => q{
        SELECT * FROM one WHERE id > 0 AND id < 0
    },
    update_nothing => q{
        UPDATE one SET text = text
    },
);

{
    package FailPingDBH;
    sub new { return bless({}, shift) }
    sub ping { 0 }
}


# Behaviour without a database backend
{
    my ($backend);

    $backend = $Pinwheel::Database::backend;
    $Pinwheel::Database::backend = undef;

    eval { Pinwheel::Database::connect() };
    like($@, qr/no database/i, 'connect errors without backend');

    eval { Pinwheel::Database::disconnect() };
    is($@, '', 'disconnect succeeds without backend');

    eval { Pinwheel::Database::finish_all() };
    is($@, '', 'finish_all succeeds without backend');

    eval { Pinwheel::Database::do('SELECT 1') };
    like($@, qr/no database/i, 'do errors without backend');

    eval { Pinwheel::Database::without_foreign_keys { 1 } };
    like($@, qr/no database/i, 'without_foreign_keys errors without backend');

    eval { Pinwheel::Database::prepare('SELECT 1') };
    like($@, qr/no database/i, 'prepare errors without backend');

    eval { Pinwheel::Database::describe('one') };
    like($@, qr/no database/i, 'describe errors without backend');

    eval { Pinwheel::Database::tables() };
    like($@, qr/no database/i, 'tables errors without backend');

    eval { Pinwheel::Database::dbhostname() };
    like($@, qr/no database/i, 'dbhostname errors without backend');

    eval { Pinwheel::Database::fetchone_tables('sth', 'tables') };
    like($@, qr/no database/i, 'fetchone_tables errors without backend');

    eval { Pinwheel::Database::fetchall_tables('sth', 'tables') };
    like($@, qr/no database/i, 'fetchall_tables errors without backend');

    $Pinwheel::Database::backend = $backend;
}


# Database connection check
{
    my ($dbh1, $dbh2);

    $Pinwheel::Database::backend->{dbh} = undef;
    Pinwheel::Database::connect();
    like(ref($Pinwheel::Database::backend->{dbh}), qr/^DBI::/,
            'connect establishes a database connection');
    isnt(Pinwheel::Database::dbhostname, undef, 'connect fills in dbhostname');
    isnt(Pinwheel::Database::dbhostname, "", 'connect fills in dbhostname');
    is($Pinwheel::Database::backend->{dbh_checked}, 1, 'connect sets dbh_checked to 1');

    Pinwheel::Database::finish_all();
    is($Pinwheel::Database::backend->{dbh_checked}, 0, 'finish_all sets dbh_checked to 0');

    $Pinwheel::Database::backend->{dbh} = undef;
    prepare($sql{count_one});
    like(ref($Pinwheel::Database::backend->{dbh}), qr/^DBI::/,
            'prepare() establishes a database connection if necessary');

    $Pinwheel::Database::backend->{dbh} = undef;
    Pinwheel::Database::do($sql{update_nothing});
    like(ref($Pinwheel::Database::backend->{dbh}), qr/^DBI::/,
            'do() establishes a database connection if necessary');

    $Pinwheel::Database::backend->{dbh_checked} = 0;
    prepare($sql{count_one});
    is($Pinwheel::Database::backend->{dbh_checked}, 1,
            'prepare() checks a database connection if necessary');

    $Pinwheel::Database::backend->{dbh_checked} = 0;
    Pinwheel::Database::do($sql{update_nothing});
    is($Pinwheel::Database::backend->{dbh_checked}, 1,
            'do() checks a database connection if necessary');

    $Pinwheel::Database::backend->{dbh} = FailPingDBH->new();
    Pinwheel::Database::connect();
    like(ref($Pinwheel::Database::backend->{dbh}), qr/^DBI::/,
            'failed dbh->ping results in new connection');

    $dbh1 = $Pinwheel::Database::backend->{dbh};
    Pinwheel::Database::connect();
    $dbh2 = $Pinwheel::Database::backend->{dbh};
    is($dbh1, $dbh2, 'connect does nothing with an established connection');

    $dbh1 = $Pinwheel::Database::backend->{dbh};
    Pinwheel::Database::disconnect();
    Pinwheel::Database::connect();
    $dbh2 = $Pinwheel::Database::backend->{dbh};
    isnt($dbh1, $dbh2, 'disconnect/connect forces a new connection');

    $Pinwheel::Database::backend->{connect_time} = time() - 301;
    $dbh1 = $Pinwheel::Database::backend->{dbh};
    Pinwheel::Database::connect();
    $dbh2 = $Pinwheel::Database::backend->{dbh};
    isnt($dbh1, $dbh2, 'database handle is expired after 5 minutes');

    Pinwheel::Database::disconnect();
    is($Pinwheel::Database::backend->{dbh}, undef, 'disconnect makes dbh undef');
    is($Pinwheel::Database::dbhostname, undef, 'disconnect makes dbhostname undef');

    eval { Pinwheel::Database::disconnect() };
    is("$@", "", 'disconnect when already disconnected is not an error');
}

# Statement caching
{
    my ($sth1, $sth2);

    $sth1 = prepare($sql{find_all_one});
    $sth2 = prepare($sql{find_all_one});
    is($sth1, $sth2, 'prepare caches statement handles');
    $sth1->execute();
    $sth2 = prepare($sql{find_all_one});
    isnt($sth1, $sth2, '... unless the original is in use');
    $sth1->finish();

    $sth1 = prepare($sql{find_all_one});
    $sth2 = prepare($sql{find_all_one}, 1);
    is($sth1, $sth2, 'transient handles can be served from the cache');
    $sth1 = prepare($sql{find_all_two}, 1);
    $sth2 = prepare($sql{find_all_two}, 1);
    isnt($sth1, $sth2, '... but will not added to the cache');
}

# Statement handle cleanup
{
    my ($sth1, $sth2);

    $sth1 = prepare($sql{find_all_one});
    $sth1->execute();
    $sth2 = prepare($sql{find_all_one});
    $sth2->execute();
    finish_all();
    ok(!$sth1->{Active}, 'finish_all finished cached sth');
    ok(!$sth2->{Active}, 'finish_all finished orphan sth');

    $sth1 = prepare($sql{find_all_one});
    $sth1->execute();
    $sth2 = prepare($sql{find_all_one});
    $sth1->finish();
    $sth2->finish();
    finish_all();
    ok(!$sth1->{Active}, 'finish_all worked with finished sth');
    ok(!$sth2->{Active}, 'finish_all worked with finished orphan sth');
}

# Table list
{
    my @tables = Pinwheel::Database::tables();
    isnt(@tables, 0, "tables function should return a list of tables");
    
    # Check that the three tables we created are there
    ok(grep(/^one$/, @tables), "... and table 'one' should be in the list");
    ok(grep(/^two$/, @tables), "... and table 'two' should be in the list");
    ok(grep(/^three$/, @tables), "... and table 'three' should be in the list");
}

# Table description
{
    my ($x, $keys);

    $x = describe('one');
    ok(exists($x->{'id'}), 'found id field in description');
    is($x->{'id'}{'type'}, 'int(11)', '... with right type');
    ok(!$x->{'id'}{'null'}, '... and not null');
    ok(exists($x->{'text'}), 'found text field in description');
    is($x->{'text'}{'type'}, 'varchar(255)', '... with right type');
    ok($x->{'text'}{'null'}, '... and can be null');
}

# FIXME: write some tests for without_foreign_keys

# Fetch one/all tables
{
    my ($sth, $x);

    $sth = prepare($sql{find_all_one});
    $sth->execute();
    $x = fetchone_tables($sth);
    ok(exists($x->{''}), 'fetchone_tables: found first key');
    is($x->{''}{id}, 1, '... id is correct');
    is($x->{''}{text}, '1.1', '... text is correct');
    $x = fetchall_tables($sth);
    ok(exists($x->[0]{''}), 'fetchall_tables: found first key');
    is($x->[0]{''}{id}, 2, '... id is correct');
    is($x->[0]{''}{text}, '1.2', '... text is correct');

    $sth = prepare($sql{find_both});
    $sth->execute();
    $x = fetchone_tables($sth, ['two']);
    ok(exists($x->{''}), 'fetchone_tables: found first key');
    ok(exists($x->{two}), 'fetchone_tables: found second key');
    is($x->{''}{id}, 1, '... one.id is correct');
    is($x->{''}{text}, '1.1', '... one.text is correct');
    is($x->{two}{id}, 1, '... two.id is correct');
    is($x->{two}{text}, '2.1', '... two.text is correct');
    $x = fetchall_tables($sth, ['two']);
    ok(exists($x->[0]{''}), 'fetchall_tables: found first key');
    ok(exists($x->[0]{two}), 'fetchall_tables: found second key');
    is($x->[0]{''}{id}, 2, '... one.id is correct');
    is($x->[0]{''}{text}, '1.2', '... one.text is correct');
    is($x->[0]{two}{id}, 2, '... two.id is correct');
    is($x->[0]{two}{text}, '2.2', '... two.text is correct');

    $sth = prepare($sql{find_all_one_three});
    $sth->execute();
    $x = fetchone_tables($sth, ['three']);
    ok(exists($x->{''}), 'fetchone_tables: found first key');
    ok(exists($x->{'three'}), 'fetchone_tables: found second key');
    is($x->{''}{id}, 1, '... one.id is correct');
    is($x->{''}{text}, '1.1', '... one.text is correct');
    is($x->{''}{blah}, 'foobar', '... one.blah is correct');
    is($x->{three}{id}, 1, '... three.id is correct');
    is($x->{three}{text}, '3.1', '... three.text is correct');
    $x = fetchall_tables($sth, ['three']);
    ok(exists($x->[0]{''}), 'fetchall_tables: found first key');
    ok(exists($x->[0]{three}), 'fetchall_tables: found second key');
    is($x->[0]{''}{id}, 2, '... one.id is correct');
    is($x->[0]{''}{text}, '1.2', '... one.text is correct');
    is($x->[0]{''}{blah}, 'foobar', '... one.blah is correct');
    is($x->[0]{three}{id}, 2, '... three.id is correct');
    is($x->[0]{three}{text}, '3.2', '... three.text is correct');
}

# Failed lookups
{
    my ($sth, $x);

    $sth = prepare($sql{find_nothing});

    $sth->execute();
    $x = fetchone_tables($sth, []);
    is($x, undef, 'no rows in fetchone_tables means undef');

    $sth->execute();
    $x = fetchone_tables($sth, ['two']);
    is($x, undef, 'no rows in fetchone_tables (many tables) means undef');

    $sth->execute();
    $x = fetchall_tables($sth, []);
    is_deeply($x, [], 'fetchall_tables: no data results in []');
}


sub prepare_test_database
{
    Pinwheel::Database::set_connection(
        $ENV{'PINWHEEL_TEST_DB'} || 'dbi:SQLite:dbname=testdb.sqlite3',
        $ENV{'PINWHEEL_TEST_USER'} || '',
        $ENV{'PINWHEEL_TEST_PASS'} || ''
    );
    Pinwheel::Database::connect();
    my $testdb = q{
        DROP TABLE IF EXISTS `one`;
        CREATE TABLE `one` (
          `id` INT(11) NOT NULL,
          `text` VARCHAR(255) DEFAULT NULL,
          PRIMARY KEY (`id`)
        );

        DROP TABLE IF EXISTS `two`;
        CREATE TABLE `two` (
          `id` INT(11) NOT NULL,
          `one_id` INT(11) NOT NULL,
          `text` VARCHAR(255) DEFAULT NULL,
          PRIMARY KEY (`id`)
        );

        DROP TABLE IF EXISTS `three`;
        CREATE TABLE `three` (
          `id` INT(11) NOT NULL,
          `one_id` INT(11) NOT NULL,
          `text` VARCHAR(255) DEFAULT NULL,
           PRIMARY KEY (`id`)
        );

        INSERT INTO `one` VALUES (1, '1.1');
        INSERT INTO `one` VALUES (2, '1.2');
        INSERT INTO `one` VALUES (3, '1.3');
        INSERT INTO `one` VALUES (4, '1.4');

        INSERT INTO `two` VALUES (1, 1, '2.1');
        INSERT INTO `two` VALUES (2, 2, '2.2');
        INSERT INTO `two` VALUES (3, 3, '2.3');
        INSERT INTO `two` VALUES (4, 4, '2.4');

        INSERT INTO `three` VALUES (1, 1, '3.1');
        INSERT INTO `three` VALUES (2, 2, '3.2');
        INSERT INTO `three` VALUES (3, 3, '3.3');
    };
    foreach (split(/\s*;\s*/, $testdb)) {
        Pinwheel::Database::do($_);
    }
}

BEGIN {
    prepare_test_database();
}
