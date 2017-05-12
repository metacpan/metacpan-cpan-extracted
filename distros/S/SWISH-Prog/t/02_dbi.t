#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 31;

use Carp;
use Data::Dump qw( dump );

use_ok('SWISH::Prog::Native::Indexer');

# we use Rose::DBx::TestDB just for devel testing.
# don't expect normal users to have it.
SKIP: {
    eval "use SWISH::Prog::Aggregator::DBI";
    if ($@) {
        skip "DBI tests require DBI", 30;
    }

    eval "use Rose::DBx::TestDB";
    if ($@) {
        diag "install Rose::DBx::TestDB to test the DBI aggregator";
        skip "Rose::DBx::TestDB not installed", 30;
    }

    # is executable present?
    my $indexer = SWISH::Prog::Native::Indexer->new;
    if ( !$indexer->swish_check ) {
        skip "swish-e not installed", 30;
    }

    # create db.
    my $db = Rose::DBx::TestDB->new;

    my $dbh = $db->retain_dbh;

    # put some data in it.
    $dbh->do( "
    CREATE TABLE foo (
        id      integer primary key autoincrement,
        myint   integer not null default 0,
        mychar  varchar(16),
        mydate  integer not null default 1
    );
    " )
        or croak "create failed: " . $dbh->errstr;

    $dbh->do( "
        INSERT INTO foo (myint, mychar, mydate) VALUES (100, 'hello', 1000000);
    " ) or croak "insert failed: " . $dbh->errstr;

    my $sth = $dbh->prepare("SELECT * from foo");
    $sth->execute;

    # index it
    ok( my $aggr = SWISH::Prog::Aggregator::DBI->new(
            db      => $dbh,
            indexer => SWISH::Prog::Native::Indexer->new(
                invindex => 't/dbi.index',
            ),
            schema => {
                foo => {
                    id     => { type => 'int' },
                    myint  => { type => 'int', bias => 10 },
                    mychar => { type => 'char' },
                    mydate => { type => 'date' },
                    swishtitle       => 'id',
                    swishdescription => { mychar => 1, mydate => 1 },
                }
            },
        ),
        "new aggregator"
    );

    ok( $aggr->indexer->start, "indexer started" );

    is( $aggr->crawl(), 1, "row data indexed" );

    ok( $aggr->indexer->finish, "indexer finished" );

    # test with a search
SKIP: {

        eval { require SWISH::Prog::Native::Searcher; };
        if ($@) {
            skip "Cannot test Searcher without SWISH::API", 26;
        }

        my $invindex = $aggr->indexer->invindex;

        ok( my $searcher
                = SWISH::Prog::Native::Searcher->new( invindex => $invindex,
                ),
            "new searcher"
        );

        my $query = 'hello';
        ok( my $results
                = $searcher->search( $query,
                { order => 'swishdocpath ASC' } ),
            "do search"
        );
        is( $results->hits, 1, "1 hit" );
        ok( my $result = $results->next, "results->next" );
        diag( $result->swishdocpath );
        is( $result->swishtitle, '1', "get swishtitle" );
        is( $result->get_property('swishtitle'),
            $result->swishtitle, "get_property(swishtitle)" );

        # test all the built-in properties and their method shortcuts
        my @methods = qw(
            swishdocpath
            uri
            swishlastmodified
            mtime
            swishtitle
            title
            swishdescription
            summary
            swishrank
            score
        );

        for my $m (@methods) {
            ok( defined $result->$m,               "get $m" );
            ok( defined $result->get_property($m), "get_property($m)" );
        }

    }

    # clean up header so other test counts work
    unlink('t/dbi_index/swish.xml') unless $ENV{PERL_DEBUG};

}
