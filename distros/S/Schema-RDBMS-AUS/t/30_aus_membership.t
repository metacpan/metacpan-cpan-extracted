#!perl

use lib 't/tlib';

use Test::More;
use Test::Exception;
use DBIx::Migration::Directories;
use DBIx::Migration::Directories::Test;
use DBIx::Transaction;
use Schema::RDBMS::AUS;
use Schema::RDBMS::AUS::User;
use t::dbh;

local %ENV = %ENV;

delete @ENV{qw(DBI_DSN DBI_USER DBI_PASS AUS_DB_DSN AUS_DB_USER AUS_DB_PASS)};

my(@db_opts) = test_db()
    or plan skip_all => 'Schema DSN was not set';

my $dbh = DBIx::Transaction->connect_cached(@db_opts)
    or die "Failed to connect to database";

sub mkgroup {
    my $self = shift;
    my $group_name = shift;
    my $groups = $self->{_groups};
    my $rv = Schema::RDBMS::AUS::User->create(
        name => $group_name, is_group => 1, _dbh => $dbh
    );
    ok($rv, "Create a group ($group_name).");
    push(@$groups, $rv);
    return $rv;
}

my $plan = DBIx::Migration::Directories::Test->new_test(
    dbh     => $dbh, schema_dir => 'schema', schema => 'Schema::RDBMS::AUS',
    tests   => [
        sub {
            my $self = shift;
            $self->{_user} = Schema::RDBMS::AUS::User->create(
                name => "lando", _dbh => $dbh
            );
            ok($self->{_user}, "Create a user.");
            $self->{_groups} = [];
        },
        sub { mkgroup(shift, "activators"); },
        sub { mkgroup(shift, "japhs"); },
        sub { mkgroup(shift, "stoners"); },
        sub { mkgroup(shift, "hippys"); },
        sub {
            my $self = shift;
            $self->{_groups}->[0]->reset_password('bongle');
            $self->{_groups}->[0]->save;
            throws_ok
                { Schema::RDBMS::AUS::User->login(
                    "activators", "bongle", _dbh => $dbh
                ) }
                qr/Can not log in as group \#/,
                "Can't log in as a group";
        },
        sub {
            my $self = shift;
            ok(
                $self->{_groups}->[0]->add_to_group('japhs'),
                "Add activators to japhs"
            );
        },
        sub {
            my $self = shift;
            is_deeply(
                $self->{_groups}->[0]->{_membership},
                {
                    $self->{_groups}->[1]->{id} => 1,
                    $self->{_groups}->[0]->{id} => 0
                },
                "Activators are now japhs as well"
             );
        },
        sub {
            my $self = shift;
            throws_ok
                { $self->{_groups}->[0]->add_to_group($self->{_user}); }
                qr/is not a group/,
                "Can't make a group a member of a user";
        },
        sub {
            my $self = shift;
            ok(
                $self->{_groups}->[1]->add_to_group('stoners'),
                "Add japhs to stoners"
            );
        },
        sub {
            my $self = shift;
            is_deeply(
                $self->{_groups}->[1]->{_membership},
                {
                    $self->{_groups}->[2]->{id} => 1,
                    $self->{_groups}->[1]->{id} => 0
                },
                "japhs are now stoners"
             );
        },
        sub {
            my $self = shift;
            ok(
                $self->{_groups}->[0]->refresh,
                "Reload activators"
            );
        },
        sub {
            my $self = shift;
            is_deeply(
                $self->{_groups}->[0]->{_membership},
                {
                    $self->{_groups}->[2]->{id} => 2,
                    $self->{_groups}->[1]->{id} => 1,
                    $self->{_groups}->[0]->{id} => 0
                },
                "Activators are now stoners by 2 degrees of separation"
             );
        },
        sub {
            my $self = shift;
            throws_ok
                { $self->{_groups}->[2]->add_to_group($self->{_groups}->[0]) }
                qr/circular membership/i,
                "Can't create a circular membership"
        },
        sub {
            my $self = shift;
            ok(
                $self->{_groups}->[0]->add_to_group($self->{_groups}->[2]),
                "Add activators directly to stoners"
            );
        },
        sub {
            my $self = shift;
            is_deeply(
                $self->{_groups}->[0]->{_membership},
                {
                    $self->{_groups}->[2]->{id} => 1,
                    $self->{_groups}->[1]->{id} => 1,
                    $self->{_groups}->[0]->{id} => 0
                },
                "Activators are now stoners directly"
             );
        },
        sub {
            my $self = shift;
            ok(
                $self->{_groups}->[0]->remove_from_group($self->{_groups}->[1]),
                "Remove activators from japhs"
            );
        },
        sub {
            my $self = shift;
            is_deeply(
                $self->{_groups}->[0]->{_membership},
                {
                    $self->{_groups}->[2]->{id} => 1,
                    $self->{_groups}->[0]->{id} => 0
                },
                "Activators are not japhs anymore"
             );
        },
        sub {
            my $self = shift;
            ok(
                $self->{_groups}->[2]->add_to_group('hippys'),
                "stoners are hippys"
            );
        },
        sub {
            my $self = shift;
            $self->{_groups}->[0]->refresh;
            is_deeply(
                $self->{_groups}->[0]->{_membership},
                {
                    $self->{_groups}->[2]->{id} => 1,
                    $self->{_groups}->[0]->{id} => 0,
                    $self->{_groups}->[3]->{id} => 2,
                },
                "hippydom cascades"
             );
        },
        sub {
            my $self = shift;
            ok(
                $self->{_groups}->[0]->add_to_group($self->{_groups}->[1]),
                "reconnect groups"
            );
        },
        sub {
            my $self = shift;
            $self->{_groups}->[0] = $self->{_groups}->[0]->load;
            is_deeply(
                $self->{_groups}->[0]->{_membership},
                {
                    $self->{_groups}->[0]->{id} => 0,
                    $self->{_groups}->[1]->{id} => 1,
                    $self->{_groups}->[2]->{id} => 1,
                    $self->{_groups}->[3]->{id} => 2,
                },
                "Everything is connected"
             );
        },
        sub {
            my $self = shift;
            $self->{_groups}->[0]->remove_from_group($self->{_groups}->[2]);
            is_deeply(
                $self->{_groups}->[0]->{_membership},
                {
                    $self->{_groups}->[0]->{id} => 0,
                    $self->{_groups}->[1]->{id} => 1,
                    $self->{_groups}->[2]->{id} => 2,
                    $self->{_groups}->[3]->{id} => 3,
                },
                "Connected like a ladder"
             );
        },
        sub {
            my $self = shift;
            $self->{_groups}->[1]->remove_from_group($self->{_groups}->[2]);
            $self->{_groups}->[0] = $self->{_groups}->[0]->load;
            is_deeply(
                $self->{_groups}->[0]->{_membership},
                {
                    $self->{_groups}->[0]->{id} => 0,
                    $self->{_groups}->[1]->{id} => 1,
                },
                "Chop off the middle peg"
             );
        },
    ]
);

plan tests => $plan->num_tests;

$plan->run_tests;
