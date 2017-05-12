#!/usr/bin/perl

##
## Tests for Pangloss::Search::Request
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok("Pangloss::Search::Request") };

my $sreq = new Pangloss::Search::Request;
ok( $sreq, 'new' ) || die "cannot continue";

is( $sreq->modified(0), $sreq, 'modified(set)' );

test_toggle( $sreq, 'category' );
test_toggle( $sreq, 'concept' );
test_toggle( $sreq, 'language' );
test_toggle( $sreq, 'proofreader' );
test_toggle( $sreq, 'translator' );
test_toggle( $sreq, 'status' );
test_toggle( $sreq, 'date_range' );

is( $sreq->keyword( 'foo bar' ), $sreq, 'keyword(set)' );
is( $sreq->keyword, 'foo bar',          'keyword(get)' );

ok( $sreq->modified, 'is modified' );
$sreq->modified(0);

is( $sreq->document_uri( 'foo' ), $sreq,     'document_uri(set)' );
is( $sreq->document_uri, 'foo',              'document_uri(get)' );
is( $sreq->document( 'foo bar baz' ), $sreq, 'document(set)' );
is( $sreq->document, 'foo bar baz',          'document(get)' );

ok( $sreq->modified, 'is modified' );

my $filters = $sreq->get_filters;
isa_ok( $filters, 'ARRAY', 'get_filters' );

ok(!$sreq->modified, 'not modified' );

my $uri = $sreq->create_uri_from( 'www.quiup.com' );
is( $uri, 'http://www.quiup.com', 'create_uri_from' );

ok(!$sreq->is_document_loaded_from( $uri ), 'is_document_loaded_from false' );
$sreq->document_uri( 'http://www.quiup.com' )
     ->document( 'welcome to quiup' );
ok( $sreq->is_document_loaded_from( $uri ), 'is_document_loaded_from true' );


sub test_toggle {
    my $sreq = shift;
    my $type = shift;
    my $set_method         = "$type";
    my $toggle_method      = "toggle_$type";
    my $is_selected_method = "is_$type\_selected";

    is( $sreq->$set_method( 'test', 1 ), $sreq, "$set_method(test, on)" );
    ok( $sreq->$is_selected_method('test'),     " sets $is_selected_method(test)" );
    is( $sreq->$toggle_method('test'), $sreq,   " $toggle_method(test)" );
    ok(!$sreq->$is_selected_method('test'),     " unsets $is_selected_method(test)" );
}

