#!perl
use strict;
use warnings;
use SQL::Executor;
use Test::More;
use t::Util;
use Try::Tiny;


my $dbh = prepare_dbh();


subtest 'select_row', sub {
    my $db = SQL::Executor->new($dbh);
    run_and_check_exception(sub { 
        $db->select_row('TEST', { id => \'no_exist_func()' });
    });
};

subtest 'select_all', sub {
    my $db = SQL::Executor->new($dbh);
    run_and_check_exception(sub { 
        $db->select_all('TEST', { id => \'no_exist_func()' });
    });
};

subtest 'select_itr', sub {
    my $db = SQL::Executor->new($dbh);
    run_and_check_exception(sub { 
        $db->select_itr('TEST', { id => \'no_exist_func()' });
    });
};

subtest 'execute_query', sub {
    my $db = SQL::Executor->new($dbh);
    run_and_check_exception(sub { 
        $db->execute_query("INSERT INTO TEST (id) VALUES( no_exist_fun() )");
    });
};

subtest 'execute_query_named', sub {
    my $db = SQL::Executor->new($dbh);
    run_and_check_exception(sub { 
        $db->execute_query_named("INSERT INTO TEST (id) VALUES( no_exist_fun() )");
    });
};


sub run_and_check_exception {
    my ($callback) = @_;
    try {
        $callback->();
        fail 'exception expected';
    } catch {
        #diag "$_\n";
        like( $_, qr/at $0 line \d+/ );#contains error and line no in this test
    }
}



done_testing;

