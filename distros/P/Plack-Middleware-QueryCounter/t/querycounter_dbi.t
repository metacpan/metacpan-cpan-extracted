use Test::More;

use strict;
use warnings;
use utf8;

use_ok "Plack::Middleware::QueryCounter::DBI";

use HTTP::Request::Common;
use Plack::Test;

subtest "_callback", sub {
    my $stats = {
        total => 0,
        read  => 0,
        write => 0,
        other => 0,
    };

    Plack::Middleware::QueryCounter::DBI::_callback({
        sql => "/*  */ SELECT * FROM table;"
    }, $stats);

    is $stats->{total}, 1, 'total countup ok';
    is $stats->{read}, 1, 'read countup ok';
    is $stats->{write}, 0, 'write is 0 ok';
    is $stats->{other}, 0, 'other is 0 ok';
};

subtest "_callback much", sub {
    my $stats = {
        total => 0,
        read  => 0,
        write => 0,
        other => 0,
    };

    Plack::Middleware::QueryCounter::DBI::_callback({
        sql => "SELECT * FROM table; DELETE FROM player; /* test.pm:L26 */ UPDATE table SET password = 'powawa';\n\
ALTER TABLE hoge ADD COLUMN powawa int;
insert into foo (hoge_id, fuga_id) values (42, 24);"
    }, $stats);

    is $stats->{total}, 5, 'total count = 5 ok';
    is $stats->{read}, 1, 'read count = 1 ok';
    is $stats->{write}, 3, 'write = 3 ok';
    is $stats->{other}, 1, 'other = 1 ok';
};


# middleware test
subtest "middleware", sub {
    my $app = sub {
        my $dbh = DBI->connect("dbi:SQLite::memory:");

        $dbh->do('create table test (id integer)');
        $dbh->do('insert into test (id) values (1), (3), (5)');
        $dbh->do('select * from test where id in (3, 5)');
        $dbh->do('select * from test where id in (1, 5)');
        $dbh->do('select * from test where id in (1, 3)');

        return [200, ['Content-Type' => 'text/plain'], ["Hello Wild"]];
    };
    my $wrap_app = Plack::Middleware::QueryCounter::DBI->wrap($app);

    test_psgi $wrap_app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/");

        is $res->code, 200, '200 ok';
        is $res->header('X-QueryCounter-DBI-Total'), 5, 'total 5 query ok';
        is $res->header('X-QueryCounter-DBI-Read'), 3, 'read 3 query ok';
        is $res->header('X-QueryCounter-DBI-Write'), 1, 'write 1 query ok';
        is $res->header('X-QueryCounter-DBI-Other'), 1, 'other 1 query ok';
    };

    my $wrap_app2 = Plack::Middleware::QueryCounter::DBI->wrap($app, prefix => 'X-Hoge');

    test_psgi $wrap_app2, sub {
        my $cb = shift;
        my $res = $cb->(GET "/");

        is $res->code, 200, '200 ok';
        is $res->header('X-Hoge-Total'), 5, 'total 5 query ok';
        is $res->header('X-Hoge-Read'), 3, 'read 3 query ok';
        is $res->header('X-Hoge-Write'), 1, 'write 1 query ok';
        is $res->header('X-Hoge-Other'), 1, 'other 1 query ok';
    };

};


done_testing;

