#! /usr/bin/env perl

use strict;
use warnings;

require Carp;
$SIG{__WARN__} = \&Carp::cluck;
$SIG{__DIE__} = \&Carp::confess;

use Storable qw(dclone freeze thaw);
use Test::More tests => 159;
use UNIVERSAL qw(isa);

use Pinwheel::Context;
use Pinwheel::Database;
use Pinwheel::Model;


sub prepare_test_database
{
    Pinwheel::Database::set_connection(
        $ENV{'PINWHEEL_TEST_DB'} || 'dbi:SQLite:dbname=testdb.sqlite3',
        $ENV{'PINWHEEL_TEST_USER'} || '',
        $ENV{'PINWHEEL_TEST_PASS'} || ''
    );
    Pinwheel::Database::connect();
    my $testdb = q{
        DROP TABLE IF EXISTS `services`;
        CREATE TABLE `services` (
          `id` INT(11) NOT NULL,
          `directory` VARCHAR(255) NOT NULL,
          PRIMARY KEY (`id`)
        );

        DROP TABLE IF EXISTS `programmes`;
        CREATE TABLE `programmes` (
          `id` INT(11) NOT NULL,
          `type` VARCHAR(255),
          `parent_id` INT(11),
          `name` VARCHAR(255) DEFAULT NULL,
          `updated_at` DATETIME DEFAULT NULL,
          PRIMARY KEY (`id`)
        );

        DROP TABLE IF EXISTS `broadcasts`;
        CREATE TABLE `broadcasts` (
          `id` INT(11) NOT NULL,
          `service_id` INT(11) NOT NULL,
          `episode_id` INT(11) NOT NULL,
          `start` DATETIME NOT NULL,
          `duration` INT(11) NOT NULL,
          `schedule_date` DATE NOT NULL,
          PRIMARY KEY (`id`)
        );

        DROP TABLE IF EXISTS `promotions`;
        CREATE TABLE `promotions` (
          `id` INT(11) NOT NULL,
          `src_programme_id` INT(11) NOT NULL,
          `dst_programme_id` INT(11) NOT NULL,
          PRIMARY KEY (`id`)
        );

        INSERT INTO `services` VALUES (1, 'radio1');
        INSERT INTO `services` VALUES (2, 'radio2');
        INSERT INTO `services` VALUES (3, 'radio3');
        INSERT INTO `services` VALUES (4, 'radio4');
        INSERT INTO `services` VALUES (100, 'radio0');

        INSERT INTO `programmes` VALUES (1, 'Brand', NULL, 'The Chris Moyles Show', NULL);
        INSERT INTO `programmes` VALUES (2, 'Brand', NULL, 'Wake Up To Wogan', NULL);
        INSERT INTO `programmes` VALUES (3, 'Brand', NULL, 'Sara Mohr-Pietsch', NULL);
        INSERT INTO `programmes` VALUES (4, 'Brand', NULL, 'Today', NULL);
        INSERT INTO `programmes` VALUES (5, 'Brand', NULL, 'Start the Week', NULL);

        INSERT INTO `programmes` VALUES (11, 'Episode', 1, 'The Chris Moyles Show', NULL);
        INSERT INTO `programmes` VALUES (12, 'Episode', 2, 'Wake Up To Wogan', NULL);
        INSERT INTO `programmes` VALUES (13, 'Episode', 3, 'Sara Mohr-Pietsch', NULL);
        INSERT INTO `programmes` VALUES (14, 'Episode', 4, 'Today', NULL);
        INSERT INTO `programmes` VALUES (15, 'Episode', 5, 'Start the Week', NULL);
        INSERT INTO `programmes` VALUES (16, 'Episode', NULL, 'Unbranded', NULL);
        INSERT INTO `programmes` VALUES (17, 'Episode', 4, 'Still Today', NULL);
        INSERT INTO `programmes` VALUES (20, 'Episode', NULL, NULL, NULL);

        INSERT INTO `programmes` VALUES (99, 'Blah', NULL, 'Bad data', NULL);

        INSERT INTO `broadcasts` VALUES (1, 1, 11, '2007-03-12 07:00:00', 10800, '2007-03-12');
        INSERT INTO `broadcasts` VALUES (2, 2, 12, '2007-03-12 07:30:00',  7200, '2007-03-12');
        INSERT INTO `broadcasts` VALUES (3, 3, 13, '2007-03-12 07:00:00', 10800, '2007-03-12');
        INSERT INTO `broadcasts` VALUES (4, 4, 14, '2007-03-12 06:00:00', 10800, '2007-03-12');
        INSERT INTO `broadcasts` VALUES (5, 4, 15, '2007-03-12 09:00:00',  2700, '2007-03-12');
        INSERT INTO `broadcasts` VALUES (6, 4, 15, '2007-03-12 21:30:00',  1800, '2007-03-12');
        INSERT INTO `broadcasts` VALUES (9, 0,  0, '0000-00-00 00:00:00',     0, '0000-00-00');

        INSERT INTO `promotions` VALUES (1, 1, 2);
        INSERT INTO `promotions` VALUES (2, 1, 11);
        INSERT INTO `promotions` VALUES (3, 11, 3);
        INSERT INTO `promotions` VALUES (4, 12, 13);
    };
    foreach (split(/\s*;\s*/, $testdb)) {
        Pinwheel::Database::do($_);
    }
}

BEGIN {
    prepare_test_database();
}


package Models::Service;

use Pinwheel::Model 'services';
our @ISA = qw(Pinwheel::Model::Base);

has_many 'broadcasts';
query 'count';
query 'find_count', type => '1', fn => sub { () };
query 'find_every_service', type => '[-]';
query 'find_extra_by_directory';
query 'stupid_count', type => '[-]', postfn => sub { scalar(@{$_[1]}) };
query 'echo', type => '1', postfn => sub { [@_] };

sub route_param { $_[0]->directory }

our %sql = (
    count => q{SELECT COUNT(*) FROM services},
    find_count => q{SELECT COUNT(*) FROM services},
    find_every_service => q{SELECT * FROM services ORDER BY id},
    find_extra_by_directory => q{
        SELECT *, 'x' AS extra FROM services WHERE directory = ?
    },
    stupid_count => q{SELECT id FROM services},
    echo => q{SELECT ?},
);


package Models::Programme;

use Pinwheel::Model 'programmes';
our @ISA = qw(Pinwheel::Model::Base);

query 'find_all_like';
query 'find_all_by_not_parent_id', order => 'id';

our %sql = (
    find_all_like => q{
        SELECT p.*
        FROM programmes p
        WHERE p.name LIKE ?
        ORDER BY p.name ASC, p.type ASC
    },
    find_all_by_not_parent_id => q{SELECT * FROM programmes WHERE parent_id != ?},
);


package Models::Brand;

use Pinwheel::Model 'programmes', 'type' => 'Brand';
our @ISA = qw(Models::Programme);


package Models::Episode;

use Pinwheel::Model 'programmes', 'type' => 'Episode';
our @ISA = qw(Models::Programme);

belongs_to 'brand', key => 'parent_id';
has_many 'broadcasts', key => 'id';
has_one 'first_broadcast',
        finder => 'find_first', package => 'Models::Broadcast';
query 'find_with_brand', fn => sub { ( ['brand'], $_[1] ) };
query 'find_all_by_parent_and_name', order => 'id';
query 'find_all_not_parent', order => 'id';

our %sql = (
    find_with_brand => q{
        SELECT e.*, b.*
        FROM programmes e
        LEFT JOIN programmes b ON e.parent_id = b.id
        WHERE e.id = ?
    },
    find_all_by_parent_and_name => q{SELECT * FROM programmes WHERE parent_id=? AND name=?},
);


package Models::SuperBroadcast;

use Pinwheel::Model 'broadcasts';
our @ISA = qw(Pinwheel::Model::Base);

belongs_to 'episode', key => 'episode_id', package => 'Models::Episode';


package Models::Broadcast;

use Pinwheel::Model 'broadcasts';
use DBI qw(SQL_INTEGER);
our @ISA = qw(Models::SuperBroadcast);

belongs_to 'service', finder => 'find';
has_one 'broken_relation';
query 'find_first';
query 'find_minimal';
query 'find_prefetched', include => ['episode', 'episode.brand'];
query 'find_unknown_relation', include => ['foo'];
query 'find_broken_relation', include => ['broken_relation'];;
query 'find_all_by_service';
query 'find_all_by_programme', fn => sub { $_[1] };
query 'find_with_episode', include => ['episode'];
query 'unique_durations', type => '[1]';
query 'set_duration', type => 'x', fn => sub { ( $_[1], $_[0] ) };
query 'get_duration', type => '1';
query 'find_n', type => '[-]', fn => sub { ({$_[1] => SQL_INTEGER}) };
query 'find_slice_ids', type => '[1]';

our %sql = (
    find_first => q{
        SELECT *
        FROM broadcasts
        WHERE episode_id = ?
        ORDER BY start
        LIMIT 1
    },
    find_minimal => q{SELECT id FROM broadcasts WHERE id = ?},
    find_prefetched => q{
        SELECT bc.*, e.*, b.*
        FROM broadcasts bc, programmes e, programmes b
        WHERE bc.id = ?
        AND bc.episode_id = e.id
        AND e.parent_id = b.id
    },
    find_unknown_relation => q{
        SELECT bc.*, e.*
        FROM broadcasts bc, programmes e
        WHERE bc.id = ?
        AND bc.episode_id = e.id
    },
    find_broken_relation => q{
        SELECT bc.*, e.*
        FROM broadcasts bc, programmes e
        WHERE bc.id = ?
        AND bc.episode_id = e.id
    },
    find_all_by_service => q{SELECT * FROM broadcasts WHERE service_id = ?},
    find_all_by_programme => q{SELECT * FROM broadcasts WHERE episode_id = ?},
    find_with_episode => q{
        SELECT b.*, e.*
        FROM broadcasts b, programmes e
        WHERE b.id = ?
        AND b.episode_id = e.id
    },
    unique_durations => q{
        SELECT DISTINCT(duration) n
        FROM broadcasts
        ORDER BY n ASC
    },
    set_duration => q{UPDATE broadcasts SET duration = ? WHERE id = ?},
    get_duration => q{SELECT duration FROM broadcasts WHERE id = ?},
    find_n => q{SELECT * FROM broadcasts ORDER BY start LIMIT ?},
    find_slice_ids => q{
        SELECT id
        FROM broadcasts
        WHERE start ?$[<>!=]+$ ?
        ORDER BY id ASC
    },
);


package Models::Promotion;

use Pinwheel::Model 'promotions';
our @ISA = qw(Pinwheel::Model::Base);

belongs_to 'from', key => 'src_programme_id', package => 'Models::Programme';
belongs_to 'to', key => 'dst_programme_id', package => 'Models::Programme';

query 'find_with_promoted', include => ['from', 'to'];
query 'find_with_missing_type', include => ['from'];

our %sql = (
    find_with_promoted => q{
        SELECT pr.*, p1.*, p2.*
        FROM promotions pr
        INNER JOIN programmes p1 ON p1.id = pr.src_programme_id
        INNER JOIN programmes p2 ON p2.id = pr.dst_programme_id
        WHERE pr.id = ?
    },
    find_with_missing_type => q{
        SELECT pr.*, p1.id
        FROM promotions pr
        INNER JOIN programmes p1 ON p1.id = pr.src_programme_id
        WHERE pr.id = ?
    },
);


package main;


# Utility functions
{
    my ($s1, $s2);

    no strict 'refs';
    ($s1, $s2) = (*{'Pinwheel::Model::'}, *{'Pinwheel::Model::Base::'});
    use strict 'refs';

    is(Pinwheel::Model::_get_stash('Pinwheel::Model'), $s1, 'can find Pinwheel::Model package');
    is(Pinwheel::Model::_get_stash('Pinwheel::Model::Base'), $s2, 'can find Pinwheel::Model::Base package');
}

# Simple queries
{
    is(Models::Service->find(1)->directory, 'radio1');
    is(Models::Service->find_by_directory('radio2')->id, 2);
    is(Models::Service->find_by_directory(undef), undef);
    is(Models::Service->count, 5);
    is(Models::Episode->find_by_parent_id(undef)->id, 16);
}

# Queries with null parameters
{
    my $x;
    
    $x = Models::Episode->find_all_by_parent_id(undef);
    is(scalar(@$x), 2);
    is($x->[0]->id, 16);

    $x = Models::Episode->find_all_by_not_parent_id(undef);
    is(scalar(@$x), 6);
    is($x->[0]->id, 11);
    
    $x = Models::Episode->find_all_by_name(undef);
    is(scalar(@$x), 1);
    is($x->[0]->id, 20);
    
    $x = Models::Episode->find_all_by_parent_and_name(undef,undef);
    is(scalar(@$x), 1);
    is($x->[0]->id, 20);
}

# Failed lookups
{
    is(Models::Service->find_by_directory('foobar'), undef);
    is_deeply(Models::Broadcast->find_all_by_service(-1), []);
}

# Query result types
{
    my $x;

    # find (but not find_all) returns a row
    $x = Models::Service->find(1);
    ok(isa($x, 'Models::Service'), 'find returns a model object');

    # count returns a single value
    $x = Models::Service->count();
    is($x, 5, 'count returns a scalar');

    # otherwise returns a list of rows
    $x = Models::Broadcast->find_all_by_service(1);
    is(ref($x), 'ARRAY');
    ok(isa($x->[0], 'Models::Broadcast'), 'find_all returns a list of objects');

    # or can be overridden
    $x = Models::Broadcast->get_duration(1);
    is($x, 10800, 'query can return a scalar');
    $x = Models::Broadcast->unique_durations();
    is_deeply(Models::Broadcast->unique_durations, [0, 1800, 2700, 7200, 10800],
            'query can return a list of scalars');
    $x = Models::Service->find_every_service();
    is(ref($x), 'ARRAY');
    ok(isa($x->[0], 'Models::Service'), 'query can return a list of objects');

    # inheritance affects the class of the result object
    $x = Models::Programme->find(1);
    is(ref($x), 'Models::Brand');
    $x = Models::Programme->find(11);
    is(ref($x), 'Models::Episode');

    eval { $x = Models::Programme->find(99) };
    like($@, qr/no model found for subclass/i);
}

# Limit result set
{
    my ($x, $y);

    $x = Models::Service->find_every_service(limit => 3);
    is(scalar(@$x), 3, 'results can be limited');
    is($x->[0]->id, 1);

    $x = Models::Service->find_every_service(limit => 3, offset => 2);
    is(scalar(@$x), 3, 'results can be paged');
    is($x->[0]->id, 3);

    $x = Models::Broadcast->find_all_by_service(4, limit => 2);
    is(scalar(@$x), 2, 'results from queries with arguments can be limited');

    $x = Models::Broadcast->find_all(order => 'start ASC');
    $y = Models::Broadcast->find_all(order => 'start DESC');
    is(scalar(@$x), scalar(@$y));
    is($x->[0]->id, $y->[-1]->id);
    is($y->[0]->id, $x->[-1]->id);

    eval { Models::Broadcast->find_all(order => 'start ASC; SELECT 1') };
    like($@, qr/invalid sort order/i);
}

# Finders
{
    my ($brand, $ep, $p, $l1, $l2, $l3);

    $brand = Models::Brand->find(undef);
    is($brand, undef);

    $brand = Models::Brand->find(3);
    ok(isa($brand, 'Models::Brand'));
    is($brand->id, 3);

    $brand = Models::Brand->find_by_name('Today');
    ok(isa($brand, 'Models::Brand'));
    is($brand->name, 'Today');

    $ep = Models::Episode->find(11);
    $p = Models::Programme->find(11);
    ok(isa($ep, 'Models::Episode'));
    ok(isa($p, 'Models::Episode'));
    is($ep, $p);

    $ep = Models::Episode->find(undef);
    is($ep, undef);
    $ep = Models::Episode->find_by_parent(undef);
    ok(isa($ep, 'Models::Episode'));
    is($ep->name, 'Unbranded');

    $l1 = Models::Episode->find_all_by_parent($brand);
    is(ref($l1), 'ARRAY');
    cmp_ok(scalar(@$l1), '>', 0);
    $l2 = Models::Episode->find_all_by_parent_id($brand->id);
    is(ref($l2), 'ARRAY');
    is(scalar(@$l1), scalar(@$l2));
    $l3 = Models::Episode->find_all_by_parent_id($brand);
    is(ref($l3), 'ARRAY');
    is(scalar(@$l1), scalar(@$l3));

    $l1 = Models::Brand->find_all(order => 'id');
    $l2 = Models::Programme->find_all_by_type('Brand', order => 'id');
    is(ref($l1), 'ARRAY');
    is_deeply([map { $_->id } @$l1], [map { $_->id } @$l2]);

    eval { Models::Episode->find_by_foo(1) };
    like($@, qr/can't locate .*find_by_foo/i);
}

# Dynamic SQL parameters
{
    my $x;

    $x = Models::Broadcast->find_slice_ids('=', '2007-03-12 07:00:00');
    is_deeply($x, [1, 3]);
    $x = Models::Broadcast->find_slice_ids('!=', '2007-03-12 07:00:00');
    is_deeply($x, [2, 4, 5, 6, 9]);
    $x = Models::Broadcast->find_slice_ids('<', '2007-03-12 09:00:00');
    is_deeply($x, [1, 2, 3, 4, 9]);

    eval { Models::Broadcast->find_slice_ids('foo', '2007-03-12 07:00:00') };
    like($@, qr/does not match requirement/i);
}

# Relations
{
    my $x;

    $x = Models::Service->find(1);
    is(ref($x->broadcasts), 'ARRAY');
    ok(isa($x->broadcasts->[0], 'Models::Broadcast'));
    ok(isa($x->broadcasts->[0]->episode, 'Models::Episode'));
    is($x->broadcasts->[0]->episode->name, 'The Chris Moyles Show');

    $x = Models::Episode->find(12);
    ok(isa($x->brand, 'Models::Brand'));
    is($x->brand->name, 'Wake Up To Wogan');

    $x = Models::Broadcast->find(3);
    ok(isa($x->episode, 'Models::Episode'));
    is($x->episode->name, 'Sara Mohr-Pietsch');
    ok(isa($x->service, 'Models::Service'));
    is($x->service->directory, 'radio3');

    $x = Models::Episode->find(14);
    ok(isa($x->first_broadcast, 'Models::Broadcast'));
    is($x->first_broadcast->id, 4);
}

# Queries with pre/post-processing
{
    my ($x, $i);

    # Null op function
    is(Models::Service->find_count, 5, 'query fn can be specified');

    # Null op with parameter
    $x = Models::Broadcast->find_all_by_programme(11);
    is(scalar(@$x), 1, 'query fn can supply parameter');

    # Shuffle parameters
    $x = Models::Broadcast->find(1);
    $i = $x->duration;
    $x->set_duration($i + 1);
    ok($x->get_duration == $i + 1, 'query fn can supply multiple parameters');
    $x->set_duration($i);

    # Pre-fill relation
    $x = Models::Broadcast->find_with_episode(1);
    ok($x->has_key('episode'), 'broadcast.episode was prefetched');
    is(ref($x->episode), 'Models::Episode', 'episode is an Episode object');
    is($x->episode->name, 'The Chris Moyles Show', 'episode has correct data');

    # Pre-fill deep relation
    $x = Models::Broadcast->find_prefetched(1);
    ok($x->has_key('episode'));
    ok($x->episode->has_key('brand'), 'broadcast.episode.brand was prefetched');
    is(ref($x->episode->brand), 'Models::Brand', 'brand is a Brand object');
    is($x->episode->brand->name, 'The Chris Moyles Show', 'correct brand');

    # Pre-fill relation with NULL
    $x = Models::Episode->find_with_brand(16);
    ok($x->has_key('brand'));
    is($x->brand, undef, 'NULL episode.brand was prefetched');

    # Attempt to pre-fill with an unknown relation
    eval { Models::Broadcast->find_unknown_relation(1) };
    like($@, qr/unknown relation/i, 'cannot pre-fill an unknown relation');

    # Pre-fill with a broken relation (ie, the relation points to a Model that
    # hasn't been imported)
    eval { $x = Models::Broadcast->find_broken_relation(1) };
    like($@, qr/unable to resolve relation/i);

    # Bind an integer value to LIMIT ?
    $x = Models::Broadcast->find_n(3);
    is(scalar(@$x), 3, 'bound integer to LIMIT ?');

    $x = Models::Service->stupid_count();
    is($x, Models::Service->count(), 'results can be modified by postfn');

    $x = Models::Service->echo(10);
    is_deeply($x, [[10], 10]);
}

# On-demand fetching of data
{
    my ($x, $t);

    # Flush the model cache
    Pinwheel::Context::reset();

    $x = Models::Broadcast->find_minimal(1);
    ok(!$x->has_key('duration'), 'object starts without duration value');
    is($x->duration, 10800, 'duration value was fetched on demand');

    $x = Models::Broadcast->find_minimal(2);
    ok(!$x->has_key('start'), 'object starts without start value');
    $t = $x->start;
    is($t->iso8601, '2007-03-12T07:30:00Z', 'start value fetched on demand');

    $x = Models::Broadcast->find_minimal(4);
    ok(!$x->has_key('episode'), 'object starts without episode');
    is($x->episode->name, 'Today', 'episode was fetched on demand');
}

# Pre-fetching
{
    my ($p, $i);

    # Flush the model cache
    Pinwheel::Context::reset();

    $p = Models::Programme->find(1);
    $i = Models::Programme->prefetch(1, 2, 3, 3, 2, 1);
    is($i, 2);
    $i = Models::Programme->prefetch(3, 2, 1);
    is($i, 0);

    is(scalar(keys %{Pinwheel::Context::get('Model--programmes')}), 3);
}

# Eager loading of models that use single table inheritance
{
    my ($p);

    # Flush the model cache
    Pinwheel::Context::reset();

    $p = Models::Promotion->find_with_promoted(1);
    ok(isa($p->from, 'Models::Brand'));
    ok(isa($p->to, 'Models::Brand'));

    $p = Models::Promotion->find_with_promoted(2);
    ok(isa($p->from, 'Models::Brand'));
    ok(isa($p->to, 'Models::Episode'));

    $p = Models::Promotion->find_with_promoted(3);
    ok(isa($p->from, 'Models::Episode'));
    ok(isa($p->to, 'Models::Brand'));

    $p = Models::Promotion->find_with_promoted(4);
    ok(isa($p->from, 'Models::Episode'));
    ok(isa($p->to, 'Models::Episode'));

    eval { $p = Models::Promotion->find_with_missing_type(1) };
    like($@, qr/missing inheritance key/i);
}

# Time conversion
{
    my ($x, $t);

    $x = Models::Broadcast->find(1);

    $t = $x->start;
    is(ref($t), 'Pinwheel::Model::Time', 'datetime is converted to Pinwheel::Model::Time object');
    is($t->iso8601, '2007-03-12T07:00:00Z', 'timestamp is correct');
    is($t, $x->start, 'Pinwheel::Model::Time object is cached');

    $t = $x->schedule_date;
    is(ref($t), 'Pinwheel::Model::Date', 'date is converted to Pinwheel::Model::Date object');
    is($t->iso8601, '2007-03-12', 'timestamp is correct');
    is($t, $x->schedule_date, 'Pinwheel::Model::Date object is cached');

    $t = $x->episode->updated_at;
    is($t, undef, 'NULL datetime is converted to undef');

    $x = Models::Broadcast->find(9);
    is($x->start, undef, '0000-00-00 00:00:00 timestamp converted to undef');
    is($x->schedule_date, undef, '0000-00-00 date converted to undef');
}

# has_key/keys/attributes
{
    my ($x, @keys);

    $x = Models::Service->find_by_directory('radio4');
    ok($x->has_key('id'), 'service object has "id" key');
    ok($x->has_key('directory'), 'service object has "directory" key');
    ok(!$x->has_key('foo'), 'service object does not have "foo" key');
    @keys = sort @{$x->keys()};
    is(scalar(@keys), 2, 'keys() returns expected number of keys');
    is(shift(@keys), 'directory', 'keys() includes "directory"');
    is(shift(@keys), 'id', 'keys() includes "id"');

    is($x->id, 4, 'id method returns expected value');
    is($x->directory, 'radio4', 'directory method returns expected value');
    is(ref($x->broadcasts), 'ARRAY', 'broadcasts methods returns array');

    $x->{data}{foo} = 'bar';
    ok($x->has_key('foo'), 'has_key sees added values');
    is($x->get('id'), 4, 'get method returns column value');
    is($x->get('foo'), 'bar', 'get method returns extra values');
    is($x->get('xyz'), undef, 'get returns undef for non-existent keys');

    $x = Models::Broadcast->find_minimal(1);
    is($x->get('duration'), 10800, 'get fetches missing data');
    $x = Models::Broadcast->find_minimal(2);
    is($x->get('schedule_date')->iso8601, '2007-03-12', 'get expands values');

    eval { $x->foo };
    like($@, qr/can't locate/i, 'access to invalid key fails');
}

# SQL and route representations
{
    my $x;

    $x = Models::Service->find_by_directory('radio3');
    is($x->sql_param, 3);
    is($x->route_param, 'radio3');
    $x = Models::Episode->find(12);
    is($x->sql_param, 12);
    is($x->route_param, 12);
}

# Mixed class result sets
{
    my $x;

    $x = Models::Programme->find_all_like('S%');
    is(scalar(@$x), 5);
    is(ref($x->[0]), 'Models::Brand');
    is($x->[0]->id, 3);
    is($x->[0]->name, 'Sara Mohr-Pietsch');
    is(ref($x->[1]), 'Models::Episode');
    is($x->[1]->id, 13);
    is($x->[1]->name, 'Sara Mohr-Pietsch');
    is(ref($x->[2]), 'Models::Brand');
    is($x->[2]->id, 5);
    is($x->[2]->name, 'Start the Week');
    is(ref($x->[3]), 'Models::Episode');
    is($x->[3]->id, 15);
    is($x->[3]->name, 'Start the Week');
    is(ref($x->[4]), 'Models::Episode');
    is($x->[4]->id, 17);
    is($x->[4]->name, 'Still Today');
}

# Freeze and thaw
{
    my ($ice, $b1, $b2);

    # Flush the model cache
    Pinwheel::Context::reset();

    $b1 = Models::Broadcast->find(4);
    $ice = freeze($b1);
    $b2 = thaw($ice);
    is($b1, $b2, 'thawing uses model object cache');
    is($b2->episode->name, 'Today', 'association fetching works after thaw');

    # Flush the model cache
    Pinwheel::Context::reset();

    $b2 = thaw($ice);
    is($b1->id, $b2->id, 'thaw works without cached entries');
    isnt($b1, $b2);
    is($b2->episode->name, 'Today');

    # Flush the model cache
    Pinwheel::Context::reset();

    $b1 = Models::Broadcast->find(4);
    $b2 = dclone($b1);
    is($b1, $b2, 'dclone produces the same object');
}
