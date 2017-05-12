#!/usr/bin/env perl

# This test is nearly identical to 04_mail.t except
# that we don't create 'new' 'tmp' and 'cur'
# subdirs to mimic the maildir format
# and instead just assume every file in a tree
# is one email message.

use strict;
use warnings;
use Test::More tests => 10;
use Path::Class::Dir;
use Data::Dump qw( dump );

use_ok('SWISH::Prog::Native::Indexer');

SKIP: {

    eval "use SWISH::Prog::Aggregator::MailFS";
    if ($@) {
        diag "install Mail::Box to test MailFS aggregator";
        skip "mail test requires Mail::Box", 9;
    }

    # is executable present?
    my $indexer = SWISH::Prog::Native::Indexer->new(
        verbose    => $ENV{PERL_DEBUG},
        debug      => $ENV{PERL_DEBUG},
        'invindex' => 't/mail.index',
    );
    if ( !$indexer->swish_check ) {
        skip "swish-e not installed", 9;
    }

    ok( my $mail = SWISH::Prog::Aggregator::MailFS->new(
            indexer => $indexer,
            verbose => $ENV{PERL_DEBUG},
            debug   => $ENV{PERL_DEBUG},
        ),
        "new mail aggregator"
    );

    $ENV{PERL_DEBUG} and diag( dump($mail) );

    ok( $mail->indexer->start, "start" );
    is( $mail->crawl('t/mailfs'), 1, "crawl" );
    ok( $mail->indexer->finish, "finish" );

    # test with a search
SKIP: {

        eval { require SWISH::Prog::Native::Searcher; };
        if ($@) {
            skip "Cannot test Searcher without SWISH::API::More", 5;
        }
        ok( my $searcher = SWISH::Prog::Native::Searcher->new(
                invindex => 't/mail.index',
            ),
            "new searcher"
        );

        my $query = 'test';
        ok( my $results
                = $searcher->search( $query,
                { order => 'swishdocpath ASC' } ),
            "do search"
        );
        is( $results->hits, 1, "1 hits" );
        ok( my $result = $results->next, "results->next" );
        diag( $result->swishdocpath );
        like(
            $result->swishdescription,
            qr/Peter Karman/,
            "get swishdescription"
        );
    }

}
