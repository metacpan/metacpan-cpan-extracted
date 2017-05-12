#!perl

use lib 't/tlib';

use Test::More;
use Test::Exception;
use DBIx::Migration::Directories;
use DBIx::Migration::Directories::Test;
use DBIx::Transaction;
use Schema::RDBMS::AUS;
use t::dbh;

my(@db_opts) = test_db()
    or plan skip_all => 'Schema DSN was not set';

local %ENV = %ENV;

my $dbh = DBIx::Transaction->connect_cached(@db_opts, { PrintWarn => 0 })
    or die "Failed to connect to database";

our @tests = (
    sub {
        my $self = shift;
        delete $ENV{DBI_DSN};
        delete $ENV{AUS_DB_DSN};
        throws_ok
            { Schema::RDBMS::AUS::User->login("gee", "sar", %{$self->{args}}) }
            qr/^Can't connect to data source/,
            'Missing DSN error';
    },
    sub {
        my $self = shift;
        throws_ok
            {
                Schema::RDBMS::AUS::User->login(
                    "gee", "sar",
                    _db_dsn     => $db_opts[0],
                    _db_user    => $db_opts[1],
                    _db_pass    => $db_opts[2],
                    %{$self->{args}}
                )
            }
            qr/^User not found/,
            'DSN is found in parameter';
    },
    sub {
        my $self = shift;
        throws_ok
            {
                Schema::RDBMS::AUS::User->login(
                    "gee", "sar", _dbh => $dbh, %{$self->{args}}
                )
            }
            qr/^User not found/,
            'Database handle can be passed in directly';
    },
    sub {
        my $self = shift;
        @ENV{qw(DBI_DSN DBI_USER DBI_PASS)} = @db_opts;
        
        throws_ok
            {
                Schema::RDBMS::AUS::User->login(
                    "gee", "sar", %{$self->{args}}
                )
            }
            qr/^User not found/,
            'DSN is found in $ENV{DBI_DSN}';
    },
    sub {
        my $self = shift;
        delete @ENV{qw(DBI_DSN DBI_USER DBI_PASS)};
        @ENV{qw(AUS_DB_DSN AUS_DB_USER AUS_DB_PASS)} = @db_opts;
        
        throws_ok
            {
                Schema::RDBMS::AUS::User->login(
                    "gee", "sar", %{$self->{args}}
                )
            }
            qr/^User not found/,
            'DSN is found in $ENV{AUS_DB_DSN}';
    },
    sub {
        my $self = shift;
        lives_and
            {
                ok $self->{_user} = Schema::RDBMS::AUS::User->create(
                    name        =>  'gee',
                    _password   =>  'sar',
                    %{$self->{args}}                    
                )
            }
            "Created a new user";
    },
    sub {
        my $self = shift;
        ok($self->{_user}->{id}, "New user has an ID");
    },
    sub {
        my $self = shift;
        throws_ok
            {
                Schema::RDBMS::AUS::User->login(
                    "gee", "whiz", %{$self->{args}}
                )
            }
            qr/^Bad password for user/,
            "Can't log in with bad password";
    },
    sub {
        my $self = shift;
        lives_and
            {
                ok $self->{_user} =
                    Schema::RDBMS::AUS::User->login(
                        "gee", "sar", %{$self->{args}}
                    )
            }
            "Can log in as new user";
    },
    sub {
        my $self = shift;
        throws_ok
            { $self->{_user}->change_password("whiz", "biz") }
            qr/^Old password does not match/,
            "Can't change password if you don't know the old one";
    },
    sub {
        my $self = shift;
        lives_and
            { ok $self->{_user}->change_password("sar", "whiz") }
            "Can change password if you know the old one";
    },
    sub {
        my $self = shift;
        throws_ok
            { $self->{_user}->login("gee", "sar", %{$self->{args}}) }
            qr/^Bad password for user/,
            "Can't log in with old password";
    },
    sub {
        my $self = shift;
        lives_and
            {
                ok $self->{_user} =
                    $self->{_user}->login("gee", "whiz", %{$self->{args}})
            }
            "Can log in with new password";
    },
    sub {
        my $self = shift;
        throws_ok
            { $self->{_user}->reset_password(''); }
            qr/^Invalid password./,
            "Empty password is not allowed by default";
    },
    sub {
        my $self = shift;
        lives_and
            { ok $self->{_user}->_reset_password(''); }
            "Primitive method lets us reset to a blank password";
    },
    sub {
        my $self = shift;
        ok(
            !$self->{_user}->check_password(''),
            "An empty password is never valid for logging in"
        );
    },
    sub {
        my $self = shift;
        ok(
            $self->{_user}->_check_password(''),
            "... Even if that's the user's actual password"
        );
    },
    sub {
        my $self = shift;
        lives_and
            { ok $self->{_user}->change_password('', 'pers') }
            "Can change away from an empty password"
    },
    sub {
        my $self = shift;
        throws_ok
            { $self->{_user}->change_password('pers', '') }
            qr/^Invalid password/,
            "Can not change to an empty password"
    },
    sub {
        my $self = shift;
        lives_and
            {
                is(
                    Schema::RDBMS::AUS::User->login(
                        "gee", "pers", _post_login => sub {
                            my $uu = shift;
                            $uu->{_post_login} =
                                sub { return "bers"; };
                            $self->{_user} = $uu;
                            return "zers"
                        },
                        %{$self->{args}}
                    ),
                    "zers"
                );
            }
            "_post_login hooks work"
    },
    sub {
        my $self = shift;
        is(
            $self->{_user}->{_post_login}->(), "bers",
            "_post_login hooks get user object passed in"
        );
        delete $self->{_user}->{_post_login};
    },
    sub {
        my $self = shift;
        is(
            $self->{_user}->{_crypt_class},
            "Schema::RDBMS::AUS::Crypt::SHA1",
            "Default is SHA1 encryption"
        );
    },
    sub {
        my $self = shift;
        ok(
            $self->{_user}->check_password("pers"),
            "Actual password is stored correctly"
        );
    },
    sub {
        my $self = shift;
        $self->{_user}->{password_crypt} = "None";
        lives_ok { $self->{_user}->save } "Saved user with SHA1 encryption";
    },
    sub {
        my $self = shift;
        lives_and
            { ok $self->{_user} = $self->{_user}->load(%{$self->{args}}); }
            "Can use 'load' on an existing user"
    },
    sub {
        my $self = shift;
        is(
            $self->{_user}->{password_crypt},
            "None",
            "Password crypt was saved"
        );
    },
    sub {
        my $self = shift;
        is(
            $self->{_user}->{_crypt_class},
            "Schema::RDBMS::AUS::Crypt::None",
            "Crypt class is None"
        );
    },
    sub {
        my $self = shift;
        ok(
            !$self->{_user}->check_password("pers"),
            "Old password does not verify under None"
        );
    },
    sub {
        my $self = shift;
        lives_and
            { ok $self->{_user}->reset_password("wilbur"); }
            "Password can be reset with no crypt"
    },
    sub {
        my $self = shift;
        lives_and
            { ok $self->{_user}->check_password("wilbur"); }
            "Password can be verified with no crypt"
    },
    sub {
        my $self = shift;
        is(
            $self->{_user}->{password},
            "wilbur",
            "Password attribute is not encrypted"
        );
    },
    sub {
        my $self = shift;
        dies_ok { # different RDBMS may give us different errors
            Schema::RDBMS::AUS::User->create(
                name => "gee", _password => "wilbur", %{$self->{args}}
            )
        }
        "Can't create a user that already exists"
    },
    sub {
        my $self = shift;
        TODO: {
            # must add a check that SELECTs from the user table first
            # so that we can differentiate between a user already being
            # taken, and other SQL errors, reliably
            
            local $TODO = "We currently rely on primary keys to fail for us";
                
            throws_ok {
                Schema::RDBMS::AUS::User->create(
                    name => "gee", _password => "wilbur", %{$self->{args}}
                )
            }
            qr/\QThat user name is already taken\E/,
            "User already taken error"
        }
    },
    sub {
        my $self = shift;
        ok(
            $self->{_user} = Schema::RDBMS::AUS::User->create(
                name => "buggy", %{$self->{args}}
            ),
            "Can create a user without a password"
        )
    },
    sub {
        my $self = shift;
        ok(
            !$self->{_user}->check_password(''),
            "Empty password is not good for logging in"
        );
    },
    sub {
        my $self = shift;
        ok($self->{_user}->reset_password("dix"), "Reset password");
    },
    sub {
        my $self = shift;
        ok(!defined $self->{_user}->flag('Disabled'), "Account is not disabled");
    },
    sub {
        my $self = shift;
        ok($self->{_user}->login("buggy", "dix"), "Can log in now");
    },
    sub {
        my $self = shift;
        is($self->{_user}->set_flag("disabled", "foo"), 1, "Set Disabled flag on user");
    },
    sub {
        my $self = shift;
        ok($self->{_user}->save, "Saved user OK");
    },
    sub {
        my $self = shift;
        is($self->{_user}->flag("Disabled"), 1, "Account is disabled");
    },
    sub {
        my $self = shift;
        throws_ok
            { $self->{_user}->login("buggy", "dix") }
            qr/Account #\d+ "buggy" is disabled/,
            "Can not log into a disabled account";
    },
    sub {
        my $self = shift;
        is($self->{_user}->set_flag("disabled", 0), 0, "Set disabled flag to false");
    },
    sub {
        my $self = shift;
        ok($self->{_user}->save, "Saved user OK");
    },
    sub {
        my $self = shift;
        is($self->{_user}->flag("Disabled"), 0, "Account is UN-disabled");
    },
    sub {
        my $self = shift;
        ok($self->{_user}->login("buggy", "dix"), "Can log into UN-disabled account");
    },
    sub {
        my $self = shift;
        $self->{_user}->clear_flag("Disabled");
        ok($self->{_user}->save, "Saved user with cleared flag");
    },
    sub {
        my $self = shift;
        is($self->{_user}->flag("Disabled"), undef, "Account has no disabled status");
    },
);

        
my $plan;

$plan = DBIx::Migration::Directories::Test->new_test(
    dbh     => $dbh, schema_dir => 'schema', schema => 'Schema::RDBMS::AUS',
    tests   => [
        sub { use_ok('Schema::RDBMS::AUS::User'); },
        test_pass($plan, {}),
        sub {
            ok(
                $dbh->transaction(sub {
                    $dbh->do("DELETE FROM aus_user")
                }),
                "Cleared out user table for next test pass"
            )
        },
        test_pass($plan, {
            _db_opts => {
                RaiseError => 1, PrintError => 0, AutoCommit => 0
            }
        }),
    ],
);

plan tests => $plan->num_tests;
$plan->run_tests;
exit;
        
sub test_pass {
    my($plan, $args) = @_;
    $plan->{args} = $args;
    return(
        sub {
            my $self = shift;
            $self->{args} = $args;
            pass("New test, arguments: " . join(",", %$args))
        },
        @tests
    );
}
