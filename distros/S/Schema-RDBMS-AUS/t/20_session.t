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

my $plan = DBIx::Migration::Directories::Test->new_test(
    dbh     => $dbh, schema_dir => 'schema', schema => 'Schema::RDBMS::AUS',
    tests   => [
        sub {
            my $self = shift;
            ok(
                $self->{_session} = CGI::Session::AUS->new(
                    undef, undef,
                    { Handle => $dbh, TableName => "aus_session" }
                ),
                "Get a new session"
            );
        },
        sub {
            my $self = shift;
            ok(
                $self->{_session}->param("foo", "bar"),
                "Assign a value to the sesion"
            );
        },
        sub {
            my $self = shift;
            ok(
                $self->{_session}->flush,
                "Flush session to database"
            );
        },
        sub {
            my $self = shift;
            $self->{_session_id} = $self->{_session}->id;
            delete $self->{_session};
            ok(
                $self->{_session} = CGI::Session::AUS->new(
                    undef, $self->{_session_id}, { Handle => $dbh }
                ),
                "Load previous session"
            );
        },
        sub {
            my $self = shift;
            is(
                $self->{_session_id}, $self->{_session}->id,
                "Session ID matches"
            );
        },
        sub {
            my $self = shift;
            is($self->{_session}->param("foo"), "bar", "Values persisted");
        },
        sub {
            my $self = shift;
            ok(
                $self->{_newuser} = Schema::RDBMS::AUS::User->create(
                    name        =>  "inhaler",
                    _password   =>  "eggo",
                    _dbh        =>  $dbh
                ),
                "created a user"
            );
        },
        sub {
            my $self = shift;
            throws_ok
                { $self->{_session}->login("gee", "whiz") }
                qr{\QUser not found.\E},
                "Login fails on nonexistant user"
        },
        sub {
            my $self = shift;
            throws_ok 
                { $self->{_session}->login("inhaler", "cookie") }
                qr{\QBad password for user\E},
                "Login fails on bad password"
        },
        sub {
            my $self = shift;
            ok(
                $self->{_user} = $self->{_session}->login("inhaler", "eggo"),
                "Session can log a user in"
            );
        },
        sub {
            my $self = shift;
            isnt(
                scalar($self->{_newuser}), scalar($self->{_user}),
                "User object isn't the same as the one we used to create"
            );
        },
        sub {
            my $self = shift;
            is(
                scalar($self->{_session}->user), scalar($self->{_user}),
                "User object is the same as the one stored on session"
            );
        },
        sub {
            my $self = shift;
            ok(
                !$self->{_session}->flush,
                "No flush: session has not changed"
            );
        },
        sub {
            my $self = shift;
            ok(
                $self->{_session}->param("foo", "oof"),
                "Change a param in session"
            );
        },
        sub {
            my $self = shift;
            ok($self->{_session}->flush, "Flush happens after param change");
        },
        sub {
            my $self = shift;
            $self->{_session_id} = $self->{_session}->id;
            delete $self->{_session};
            ok(
                $self->{_session} = CGI::Session::AUS->new(
                    undef, $self->{_session_id}, {
                        Handle => $dbh,
                    }
                ),
                "Session loads ok"
            );
        },
        sub {
            my $self = shift;
            is(
                $self->{_session_id}, $self->{_session}->id,
                "Session ID matches"
            );
        },
        sub {
            my $self = shift;
            is(
                $self->{_session}->{_user}->{id}, $self->{_user}->{id},
                "User is placed back into session properly."
            );
        },
        sub {
            my $self = shift;
            throws_ok
                { $self->{_session}->_driver->session_method("bollocks"); }
                qr/^\S+ can not do bollocks/,
                "AUS catches invalid session methods";
        },
    ]    
);

plan tests => $plan->num_tests + 1;

use_ok('CGI::Session::AUS') or die "Faile to use CGI::Session::AUS: $@";

$plan->run_tests;
