# $Id: /mirror/coderepos/lang/perl/Queue-Q4M/trunk/t/lib/Test/Queue/Q4M.pm 103793 2009-04-13T11:22:48.572118Z daisuke  $

package Test::Queue::Q4M;
use strict;
use warnings;
use Queue::Q4M;
use Test::More;

our @CONNECT_INFO;
our @TABLES;

sub import {
    shift;
    my $dsn      = $ENV{Q4M_DSN} || 'dbi:mysql:dbname=test_q4m';
    my $username = $ENV{Q4M_USER};
    my $password = $ENV{Q4M_PASSWORD};

    if ($dsn !~ /^dbi:mysql:/i) {
        $dsn = "dbi:mysql:dbname=$dsn";
    }

    eval {
        @CONNECT_INFO = (
            $dsn,
            $username,
            $password,
            { RaiseError => 1, AutoCommit => 1 }
        );

        my $dbh = DBI->connect(@CONNECT_INFO);

        @TABLES = map { join('_', qw(q4m test), $_, $$) } 1..10;
        foreach my $table (@TABLES) {
            $dbh->do(<<"            EOSQL");
                CREATE TABLE IF NOT EXISTS $table (
                    v INTEGER NOT NULL
                ) ENGINE=QUEUE;
            EOSQL
        }
    };
    if ($@) {
        Test::More::diag($@);
        @_ = (skip_all => "Could not setup mysql");
    }

    Test::More::plan(@_);
    Test::More->export_to_level(1);
}

sub create_queue {
    return Queue::Q4M->connect(connect_info => \@CONNECT_INFO);
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