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
    $groups->{$rv->{name}} = $rv;
    return $rv;
}

my $plan = DBIx::Migration::Directories::Test->new_test(
    dbh     => $dbh, schema_dir => 'schema', schema => 'Schema::RDBMS::AUS',
    tests   => [
        sub {
            my $self = shift;
            $self->{_groups} = {};
            mkgroup($self, "republicans");
        },
        sub { mkgroup(shift, "democrats"); },
        sub { mkgroup(shift, "greens"); },
        sub { mkgroup(shift, "ndp"); },
        sub { mkgroup(shift, "rhinos"); },
        sub { mkgroup(shift, "morons"); },
        sub { mkgroup(shift, "politicians"); },
        sub {
            my $self = shift;
            $self->{_groups}->{greens}->set_flag('hippy');
            dies_ok
                { $self->{_groups}->{greens}->save }
                "Can't set a flag that doesn't exist yet";
        },
        sub {
            my $self = shift;
            $self->{_groups}->{greens}->set_flag('hippy', undef, 1);
            lives_ok
                { $self->{_groups}->{greens}->save }
                "... unless we specify that we want to create it";
        },
        sub {
            my $self = shift;
            is(
                $self->{_groups}->{greens}->{_flags}->{hippy}, 1,
                "Flags default to true"
            );
        },
        sub {
            my $self = shift;
            $self->{_groups}->{politicians}->set_flag('hippy', "");
            lives_ok
                { $self->{_groups}->{politicians}->save }
                "politicians aren't generally hippys";
        },
        sub {
            my $self = shift;
            is(
                $self->{_groups}->{politicians}->{_flags}->{hippy}, 0,
                "Explicitly specifying a false flag value sets flag to false"
            );
        },
        sub {
            my $self = shift;
            $self->{_groups}->{republicans}->set_flag("redneck", "texas", 1);
            lives_ok
                { $self->{_groups}->{republicans}->save }
                "republicans can be rednecks";
        },
        sub {
            my $self = shift;
            is(
                $self->{_groups}->{republicans}->{_permissions}->{redneck}, 1,
                "explicitly passing in a true value sets flag to true"
            );
        },
        sub {
            my $self = shift;
            $self->{_groups}->{republicans}->clear_flag("redneck");
            lives_ok
                { $self->{_groups}->{republicans}->save }
                "OK, maybe that redneck thing was a bit of a stereotype...";
        },
        sub {
            my $self = shift;
            ok(
                !exists
                    $self->{_groups}->{republicans}->{_permissions}->{redneck},
                "clearing a flag makes it not exist anymore"
            );
        },
        sub {
            my $self = shift;
            ok(
                !exists
                    $self->{_groups}->{republicans}->{_flags}->{hippy},
                "republicans aren't hippys"
            );
        },
        sub {
            my $self = shift;
            ok(
                !exists
                    $self->{_groups}->{republicans}->{_permissions}->{hippy},
                "republicans have no hippy inheritance"
            );
        },
        sub {
            my $self = shift;
            ok(
                $self->{_groups}->{republicans}->add_to_group('politicians'),
                "republicans are politicians"
            );
        },
        sub {
            my $self = shift;
            ok(
                !defined
                    $self->{_groups}->{republicans}->flag('hippy'),
                "republicans still aren't hippys"
            );            
        },
        sub {
            my $self = shift;
            is(
                $self->{_groups}->{republicans}->{_permissions}->{hippy}, 0, 
                "republicans have a negative hippy inheritance"
            );
        },
        sub {
            my $self = shift;
            $self->{_groups}->{greens}->set_flag('hippy');
            ok($self->{_groups}->{greens}->save, "save the hippy greens");
        },
        sub {
            my $self = shift;
            ok(
                $self->{_groups}->{greens}->add_to_group('politicians'),
                "greens are politicians now"
            );
        },
        sub {
            my $self = shift;
            is(
                $self->{_groups}->{greens}->{_permissions}->{hippy}, 1, 
                "greens have their own hippydom"
            );
        },
        sub {
            my $self = shift;
            ok(
                $self->{_groups}->{rhinos}->add_to_group('politicians'),
                "rhinos are politicians... sort-of..."
            );
        },
        sub {
            my $self = shift;
            is(
                $self->{_groups}->{rhinos}->{_permissions}->{hippy}, 0, 
                "rhinos aren't hippys yet"
            );
        },
        sub {
            my $self = shift;
            ok(
                $self->{_groups}->{rhinos}->add_to_group('greens'),
                "rhinos are greens. well, it's kind of hard to tell *what* rhinos are."
            );
        },
        sub {
            my $self = shift;
            is(
                $self->{_groups}->{rhinos}->{_permissions}->{hippy}, 0, 
                "rhinos aren't hippys because the least permissive rule is taken"
            );
        },
        sub {
            my $self = shift;
            ok(
                $self->{_groups}->{rhinos}->remove_from_group('politicians'),
                "remove rhinos from politicians"
            );
        },
        sub {
            my $self = shift;
            is(
                $self->{_groups}->{rhinos}->{_permissions}->{hippy}, 1, 
                "oh wow man, rhinos are hippys now!"
            );
        },
        sub {
            my $self = shift;
            ok(
                $self->{_groups}->{rhinos}->add_to_group('politicians'),
                "make rhinos politicians again..."
            );
        },
        sub {
            my $self = shift;
            is(
                $self->{_groups}->{rhinos}->permission('hippy'), 0, 
                "least permissive flag setting still dominates"
            );
        },
        
    ]
);

plan tests => $plan->num_tests;

$plan->run_tests;
