#! perl -w

use strict;
use warnings;

use DBI;
use Test::More;
use Test::DB::Shared::mysqld;

# use Log::Any::Adapter qw/Stderr/;

my $db_pid;

if( my $child = fork() ){
    waitpid( $child , 0 );
    ok( ! $? , "Ok zero exit code");
}else{
    Test::DB::Shared::mysqld->load();
    exit(0);
}

done_testing();
