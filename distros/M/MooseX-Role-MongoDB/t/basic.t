use strict;
use warnings;
use Test::More 0.96;
use Test::FailWarnings;
use Test::Requires qw/MongoDB MongoDB::MongoClient/;

use Config;
use Log::Any::Adapter;
use MooseX::Role::Logger 0.002;
use Parallel::Iterator qw/iterate/;
use MooseX::Role::MongoDB
  ; #check at least compilation in case that other tests are skipped

plan skip_all => "Requires forking" unless $Config{d_fork};

diag "MongoDB::MongoClient version " . MongoDB::MongoClient->VERSION;

if ( $ENV{PERL_MONGODB_DEBUG} ) {
    Log::Any::Adapter->set('Stdout');
}

#--------------------------------------------------------------------------#
# Fixtures
#--------------------------------------------------------------------------#

my $coll_name = "moose_role_mongodb_test";

my $conn = eval {
    my $mc = MongoDB::MongoClient->new;
    $mc->get_database("admin")->run_command( [ ismaster => 1 ] );
    $mc;
} or plan skip_all => "No MongoDB on localhost";

$conn->get_database("test")->get_collection($coll_name)->drop;

{

    package MongoManager;
    use Moose;
    with 'MooseX::Role::MongoDB', 'MooseX::Role::Logger';

}

{

    package OpinionatedManager;
    use Moose;
    with 'MooseX::Role::MongoDB', 'MooseX::Role::Logger';

    has default_database => (
        is      => 'ro',
        isa     => 'Str',
        default => 'test2'
    );

    has client_options => (
        is      => 'ro',
        isa     => 'HashRef',
        default => sub { { host => "mongodb://localhost" } }
    );

    sub _build__mongo_default_database { return $_[0]->default_database }
    sub _build__mongo_client_options   { return $_[0]->client_options }
}

#--------------------------------------------------------------------------#
# Tests
#--------------------------------------------------------------------------#

subtest 'database names and constructor arguments' => sub {
    my $mgr = new_ok('MongoManager');

    my ( $db, $coll );

    # default database name
    isa_ok( $db = $mgr->_mongo_database, "MongoDB::Database", "_mongo_database" );
    is( $db->name, 'test', "default database is 'test'" );

    isa_ok( $coll = $mgr->_mongo_collection($coll_name),
        "MongoDB::Collection", "_mongo_collection" );
    is( $coll->full_name, "test.$coll_name", "collection name from default database" );

    isa_ok( $coll = $mgr->_mongo_collection( test2 => $coll_name ),
        "MongoDB::Collection", "_mongo_collection" );
    is( $coll->full_name, "test2.$coll_name", "collection name from explicit database" );

    $mgr = new_ok('OpinionatedManager');
    is( $mgr->_mongo_collection($coll_name)->full_name,
        "test2.$coll_name", "collection name from class default database" );

    $mgr = new_ok( 'OpinionatedManager', [ default_database => 'test3' ] );
    is( $mgr->_mongo_collection($coll_name)->full_name,
        "test3.$coll_name", "collection name from constructor argument" );

    $mgr = new_ok( 'OpinionatedManager',
        [ client_options => { host => "mongodb://127.0.0.1" } ] );
    is( $mgr->_mongo_collection($coll_name)->full_name,
        "test2.$coll_name", "collection name from class default database" );

};

subtest 'parallel insertion' => sub {

    my $mgr = new_ok('MongoManager');

    ok( $mgr->_mongo_collection($coll_name)->insert_one( { job => '-1', 'when' => time } ),
        "insert before cache clear" );

    ok( $mgr->_mongo_clear_caches, "caches cleared" );

    ok( $mgr->_mongo_collection($coll_name)->insert_one( { job => '-1', 'when' => time } ),
        "insert after cache clear, before fork" );

    my $num_forks = 3;

    my $iter = iterate(
        sub {
            my ( $id, $job ) = @_;
            $mgr->_mongo_collection($coll_name)->insert_one( { job => $job, 'when' => time } );
            return {
                pid        => $$,
                cached_pid => $mgr->_mongo_pid,
            };
        },
        [ 1 .. $num_forks ],
    );

    while ( my ( $index, $value ) = $iter->() ) {
        isnt( $value->{cached_pid}, $$, "child $index updated cached pid" )
          or diag explain $value;
    }

    is(
        $mgr->_mongo_collection($coll_name)->count,
        $num_forks + 2,
        "children created $num_forks objects"
    );
};

done_testing;
#
# This file is part of MooseX-Role-MongoDB
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
