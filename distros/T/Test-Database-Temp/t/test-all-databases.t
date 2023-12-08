#!perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;

use utf8;
use Test2::V0;
set_encoding('utf8');

use File::Temp;

use Try::Tiny;
use DBI;
use Const::Fast;

# Activate for testing
# use Log::Any::Adapter ('Stdout', log_level => 'debug' );

use Test::Database::Temp;
use Database::Temp;

const my $DDL => <<'EOF';
    CREATE TABLE test_table (
        id INTEGER
        , name VARCHAR(20)
        , age INT
        );
EOF

sub init_db {
    my ($dbh) = @_;
    $dbh->begin_work();
    foreach my $row ( split qr/;\s*/msx, $DDL ) {
        $dbh->do($row);
    }
    $dbh->commit;
    return;
}

sub init_db_csv {
    my ($dbh) = @_;
    foreach my $row ( split qr/;\s*/msx, $DDL ) {
        $dbh->do($row);
    }
    return;
}

# ##############################################################################
# Create a subtest for each database we test.
#

my @tested_drivers;
my $sqlite_predefined_dir;
my $db_fullname;

Test::Database::Temp->use_all_available(
    build => sub {
        my ($driver) = @_;

        my %params = ( args => {} );
        $params{basename} = 'baseName_';
        $params{name}     = Database::Temp::random_name();
        $db_fullname      = $params{basename} . $params{name};
        if ( $driver eq 'SQLite' ) {
            $sqlite_predefined_dir = File::Temp->newdir( cleanup => 1 );    # Cleanup when object out of scope.
            my $path = $sqlite_predefined_dir->dirname;
            $params{args}->{'dir'} = $path;
        }
        return \%params;
    },
    init => sub {
        my ( $dbh, $name, $info, $driver ) = @_;
        if ( $driver eq 'CSV' ) {
            init_db_csv( $dbh, $name );
        }
        else {
            init_db( $dbh, $name );
        }
    },
    deinit => sub {
        my ( $dbh, $name, $info, $driver ) = @_;
    },
    do => sub {
        my ($db) = @_;
        my $dbh = DBI->connect( $db->connection_info );
        my ( $db_driver, $db_name ) = ( $db->driver, $db->name );
        subtest "Testing with $db_driver in db $db_name" => sub {
            my @row_ary;
            my $r = try {
                @row_ary = $dbh->selectrow_array('SELECT 1+2');
                1;
            }
            catch {
                diag 'Failed to select 1+2';
            };
            is( $row_ary[0], 3, 'returned correct' );

            # Test passing of parameters in build sub
            is( $db_name, $db_fullname, 'Temp db has the predefined name' );
            if ( $db_driver eq 'SQLite' ) {
                diag 'SQLite db was created in predefined dir and filename ' . $sqlite_predefined_dir . q{/} . $db_fullname;
                is(
                    $db->info->{'filepath'},
                    $sqlite_predefined_dir . q{/} . $db_fullname,
                    'SQLite db was created in predefined dir'
                );
            }
            done_testing;
        };
    },
    demolish => sub {
        my ($db) = @_;
        my $driver = $db->driver;
        push @tested_drivers, $driver;
        diag "Test for $driver finished";
    },
);

subtest 'Did we test all available databases' => sub {
    my @drivers = Test::Database::Temp->available_drivers();

    is( [ sort @drivers ], [ sort @tested_drivers ], 'Tested all available drivers' );

    done_testing;
};

done_testing;
