use strict;
use warnings;

use Test::More;
use Test::MockObject;
use DBI;
use Data::Dumper;

use_ok('Pgtools::Kill');
use Pgtools::Kill;

subtest 'basic' => sub {
    my $opt = {
        "help"                   => 0,
        "ignore_match_query"     => '',
        "ignore_match_state"     => '',
        "kill"                   => '',
        "match_query"            => '^select',
        "match_state"            => '',
        "print"                  => 0,
        "run_time"               => 0,
        "version"                => 0,
    };

    my $k = Pgtools::Kill->new($opt);
    ok $k;
    isa_ok($k, "Pgtools::Kill");

    my @data1 = (
        ['datname', 'pid', 'query_start', 'state', 'query'],
        ['postgres', 2234, '2016-03-12 11:52:42.400975+00', 'idle', 'select * from actor;'],
        ['postgres', 2834, '2016-03-12 11:53:42.400975+00', 'idle', 'SELECT * from actor limit 3;'],
        ['postgres', 1234, '2016-03-12 11:54:42.400975+00', 'idle', 'INSERT INTO actor values(1,1,1);'],
    );
    my $dbh = DBI->connect('DBI:Mock:', '', '');
    $dbh->{mock_add_resultset} = \@data1;

    # $mock_db->fake_module('Mod::Connection');
    # $mock_db->fake_new('Mod::Connection');
    my $mock_db = Test::MockObject->new;
    $mock_db->set_always('dbh', $dbh);
    $mock_db->set_always('database', 'postgres');

    my $ret = $k->search_queries($mock_db);
    is_deeply $ret, +{
        2234 => {
            datname => 'postgres',
            pid => 2234,
            query_start => '2016-03-12 11:52:42.400975+00',
            state => 'idle',
            query => 'select * from actor;'
        },
        2834 => {
            datname => 'postgres',
            pid => 2834,
            query_start => '2016-03-12 11:53:42.400975+00',
            state => 'idle',
            query => 'SELECT * from actor limit 3;'
        }
    };
};

subtest 'state(disabled)' => sub {
    my $opt = {
        "help"                   => 0,
        "ignore_match_query"     => '',
        "ignore_match_state"     => '',
        "kill"                   => '',
        "match_query"            => '^select',
        "match_state"            => 'disabled',
        "print"                  => 0,
        "run_time"               => 0,
        "version"                => 0,
    };
    my $k = Pgtools::Kill->new($opt);

    my @data1 = (
        ['datname', 'pid', 'query_start', 'state', 'query'],
        ['postgres', 2234, '2016-03-12 11:52:42.400975+00', 'idle', 'select * from actor;'],
        ['postgres', 2834, '2016-03-12 11:53:42.400975+00', 'disabled', 'SELECT * from actor limit 3;'],
        ['postgres', 1234, '2016-03-12 11:54:42.400975+00', 'idle', 'INSERT INTO actor values(1,1,1);'],
    );
    my $dbh = DBI->connect('DBI:Mock:', '', '');
    $dbh->{mock_add_resultset} = \@data1;

    my $mock_db = Test::MockObject->new;
    $mock_db->set_always('dbh', $dbh);
    $mock_db->set_always('database', 'postgres');

    my $ret = $k->search_queries($mock_db);
    is_deeply $ret, +{
        2834 => {
            datname => 'postgres',
            pid => 2834,
            query_start => '2016-03-12 11:53:42.400975+00',
            state => 'disabled',
            query => 'SELECT * from actor limit 3;'
        }
    };
};

subtest 'Same query in match_query & ignore_match_query' => sub {
    my $opt = {
        "help"                   => 0,
        "ignore_match_query"     => '^select',
        "ignore_match_state"     => '',
        "kill"                   => '',
        "match_query"            => '^select',
        "match_state"            => 'disabled',
        "print"                  => 0,
        "run_time"               => 0,
        "version"                => 0,
    };
    my $k = Pgtools::Kill->new($opt);

    my @data1 = (
        ['datname', 'pid', 'query_start', 'state', 'query'],
        ['postgres', 2234, '2016-03-12 11:52:42.400975+00', 'idle', 'select * from actor;'],
        ['postgres', 2834, '2016-03-12 11:53:42.400975+00', 'disabled', 'SELECT * from actor limit 3;'],
        ['postgres', 1234, '2016-03-12 11:54:42.400975+00', 'idle', 'INSERT INTO actor values(1,1,1);'],
    );
    my $dbh = DBI->connect('DBI:Mock:', '', '');
    $dbh->{mock_add_resultset} = \@data1;

    my $mock_db = Test::MockObject->new;
    $mock_db->set_always('dbh', $dbh);
    $mock_db->set_always('database', 'postgres');

    my $ret = $k->search_queries($mock_db);
    is_deeply $ret, +{};
};

subtest 'runtime' => sub {
    plan skip_all => 'uncertaion';
    my $opt = {
        "help"                   => 0,
        "ignore_match_query"     => '',
        "ignore_match_state"     => '',
        "kill"                   => '',
        "match_query"            => '^insert',
        "match_state"            => '',
        "print"                  => 0,
        "run_time"               => 30,
        "version"                => 0,
    };
    my $k = Pgtools::Kill->new($opt);

    my @data1 = (
        ['datname', 'pid', 'query_start', 'state', 'query'],
        ['postgres', 2234, '2016-03-12 11:52:42.400975+00', 'idle', 'select * from actor;'],
        ['postgres', 2834, '2016-04-02 00:04:42.400975+00', 'idle', 'SELECT * from actor limit 3;'],
        ['postgres', 1234, '2016-03-22 00:04:42.400975+00', 'idle', 'INSERT INTO actor values(1,1,1);'],
    );
    my $dbh = DBI->connect('DBI:Mock:', '', '');
    $dbh->{mock_add_resultset} = \@data1;

    my $mock_db = Test::MockObject->new;
    $mock_db->set_always('dbh', $dbh);
    $mock_db->set_always('database', 'postgres');

    my $ret = $k->search_queries($mock_db);
    is_deeply $ret, +{
        1234 => {
            datname => 'postgres',
            pid => 1234,
            query_start => '2016-03-22 00:04:42.400975+00',
            state => 'idle',
            query => 'INSERT INTO actor values(1,1,1);'
        }
    };

    done_testing;
};



done_testing;

