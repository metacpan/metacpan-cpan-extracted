#! perl -w

use strict;
use warnings;

use DBI;
use File::Temp;
use File::Slurp;

use Test::More;
use Test::DB::Shared::mysqld;



# use Log::Any::Adapter qw/Stderr/;


my @pids = ();

my ( $fh, $db_pid_file )  = File::Temp::tempfile();

foreach my $i ( 1..3 ){
    my $child_pid;
    unless( $child_pid = fork() ){
        my $db_pid;
        my $testdb = Test::DB::Shared::mysqld->new(
            test_namespace => 'test_forked',
            my_cnf => {
                'skip-networking' => '', # no TCP socket
            }
        );
        my $dbh = DBI->connect($testdb->dsn(), 'root', '', { RaiseError => 1 } );
        if( $testdb->_holds_mysqld() ){
            File::Slurp::write_file( $db_pid_file , $testdb->pid() );
        }

        $dbh->ping();
        # diag( "Creating table bla in ".$testdb->dsn() );
        $dbh->do('CREATE TABLE bla( foo INTEGER PRIMARY KEY NOT NULL )');

        exit(0);
    }else{
        push @pids, $child_pid;
    }
}

foreach my $pid ( @pids ){
    # diag("Waiting for pid $pid");
    waitpid( $pid, 0 );
}

my $db_pid = File::Slurp::read_file( $db_pid_file );

ok( ! kill( 0, $db_pid ), "Ok db pid is NOT running (was teared down by the scope escape)");

done_testing();
