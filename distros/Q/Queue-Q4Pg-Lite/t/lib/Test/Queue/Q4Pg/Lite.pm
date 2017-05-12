package Test::Queue::Q4Pg::Lite;
use strict;
use warnings;
use Queue::Q4Pg::Lite;
use Test::More;

our @CONNECT_INFO;
our @TABLES;

sub import {
    shift;
    my $dsn      = $ENV{Q4Pg_Lite_DSN} || 'dbi:Pg:dbname=test_q4pg_lite';
    my $username = $ENV{Q4Pg_Lite_USER};
    my $password = $ENV{Q4Pg_Lite_PASSWORD};

    if ($dsn !~ /^dbi:Pg:/i) {
        $dsn = "dbi:Pg:dbname=$dsn";
    }

    eval {
        @CONNECT_INFO = (
            $dsn,
            $username,
            $password,
            { RaiseError => 1, AutoCommit => 1 }
        );

        my $dbh = DBI->connect(@CONNECT_INFO);

        @TABLES = map { join('_', qw(q4pg test), $_, $$) } 1..10;
        foreach my $table (@TABLES) {
            $dbh->do(<<"            EOSQL");
                CREATE TABLE $table (
                    id serial primary key,
                    v INTEGER NOT NULL
                )
            EOSQL
        }
    };
    if ($@) {
        Test::More::diag($@);
        @_ = (skip_all => "Could not setup PostgreSQL");
    }

    Test::More::plan(@_);
    Test::More->export_to_level(1);
}

sub create_queue {
    return Queue::Q4Pg::Lite->connect(connect_info => \@CONNECT_INFO);
}

sub destroy_tables {
    local $@;
    eval { 
        my $dbh = DBI->connect(@CONNECT_INFO);
        foreach my $table (@TABLES) {
            $dbh->do("DROP TABLES $table");
        }
    }
}

1;
