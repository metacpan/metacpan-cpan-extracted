use strict;
use warnings;
use Test::More;
# check test
my $host = "localhost";
eval {
    if (exists $ENV{MONGOD}) {
        $host = $ENV{MONGOD};
    }
    MongoDB::Connection->new(host => $host);
};

if ($@) {
    plan skip_all => $@;
}
else {
    plan tests => 34;
}


use MongoX::Context;

MongoX::Context::add_connection host => $host;

isa_ok(MongoX::Context::get_connection('default'),'MongoDB::Connection');

ok(!defined MongoX::Context::context_connection,'context connection is null first');
MongoX::Context::use_connection;
isa_ok(MongoX::Context::context_connection,'MongoDB::Connection');

MongoX::Context::use_db 'test';
isa_ok(MongoX::Context::context_db,'MongoDB::Database');
is(MongoX::Context::context_db->name,'test','switch context db');

my $col =MongoX::Context::use_collection 'foo';
my $col2 = MongoX::Context::context_collection;

is($col,$col2, 'switch context collection');

# reset
{
    MongoX::Context::reset;
    is(MongoX::Context::context_db,undef,'reset/db');
    is(MongoX::Context::context_connection,undef,'reset/connection');
    is(MongoX::Context::context_collection,undef,'reset/collection');
}

# quick boot
{
    MongoX::Context::boot host => $host,db => 'foo2';
    ok(MongoX::Context::context_connection,'boot/use_connection');
    is(MongoX::Context::context_db->name,'foo2','boot/use_db');
}

# with_context
{
    MongoX::Context::reset;
    MongoX::Context::boot host => $host,db => 'test';
    MongoX::Context::with_context sub {
        MongoX::Context::use_db 'test2';
        MongoX::Context::use_collection 'foo';
    };
    is(MongoX::Context::context_connection->host,$host,'with_context/sandbox/connection');
    is(MongoX::Context::context_db->name,'test','with_context/sandbox/db');
    is(MongoX::Context::context_collection,undef,'with_context/sandbox/collection');

    MongoX::Context::with_context sub {
        is(MongoX::Context::context_db->name,'test2','with_context/switch new db');
        is(MongoX::Context::context_collection->name,'foo','with_context/switch new collection');
    },db => 'test2', collection => 'foo';

    MongoX::Context::with_context sub {
        MongoX::Context::use_db 'test1';
        MongoX::Context::with_context sub {
            is(MongoX::Context::context_db->name,'test2','with_context/nested/db');
            is(MongoX::Context::context_collection->name,'foo2','with_context/nested/collection');
            
            MongoX::Context::use_db 'test4';
            
        },db => 'test2',collection => 'foo2';
        is(MongoX::Context::context_db->name,'test1','with_context/nested/restore db,inner');
        is(MongoX::Context::context_collection->name,'foo1','with_context/nested/restor collection,inner');
    },collection => 'foo1';

    is(MongoX::Context::context_db->name,'test','with_context/sandbox/restor db,outer');
    is(MongoX::Context::context_collection,undef,'with_context/sandbox/restor collection,outer');
}
# for_dbs
{
    my $i = 1;
    MongoX::Context::for_dbs sub {
        is(MongoX::Context::context_db->name,"test$i",'for_dbs/list');
        $i++;
        MongoX::Context::context_db->drop;
    },'test1','test2','test3';

    $i = 1;
    MongoX::Context::for_dbs sub {
        is(MongoX::Context::context_db->name,"test$i",'for_dbs/list');
        $i++;
        MongoX::Context::context_db->drop;
    },qw(test1 test2 test3);
}

{
    MongoX::Context::use_db 'test';
    my $i=1;

    MongoX::Context::for_collections sub {
        is(MongoX::Context::context_collection->name,"test$i",'for_collections/list');
        $i++;
    },'test1','test2','test3';

    $i=1;
    MongoX::Context::for_collections sub {
        is(MongoX::Context::context_collection->name,"test$i",'for_collections/collection object array');
        $i++;
    }, ('test1','test2','test3');

    MongoX::Context::context_db->drop;
}