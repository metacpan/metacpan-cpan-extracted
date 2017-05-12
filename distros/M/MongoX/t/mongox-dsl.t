use strict;
use warnings;
use Test::More;
my $host;
BEGIN {
    $host = 'localhost';
    # check test
    if (exists $ENV{MONGOD}) {
        $host = $ENV{MONGOD};
    }
    eval "use MongoX host => '$host', db => 'mongox_test'";
    if ($@) {
        plan skip_all => $@;
    }
    else {
        plan tests => 29;
    }
}

use MongoX::Context;

isa_ok(context_connection,'MongoDB::Connection');
isa_ok(context_db,'MongoDB::Database');


use_collection 'foo2';
isa_ok(context_collection, 'MongoDB::Collection');
is(context_collection->name,'foo2','use_collection');

context_db->drop();

use_db 'mongox_test2';
is(context_db->name,'mongox_test2','use_db');

context_db->drop();

# with_context
{

    MongoX::Context::reset;

    boot host => $host,db => 'mongo_test2';

    with_context {
        use_db 'test2';
        use_collection 'foo';
    };
    is(context_connection->host,$host,'with_context/sandbox/connection');
    is(context_db->name,'mongo_test2','with_context/sandbox/db');
    is(context_collection,undef,'with_context/sandbox/collection');

    with_context {
        is(context_db->name,'test2','with_context/switch new db');
        is(context_collection->name,'foo','with_context/switch new collection');
    } db => 'test2', collection => 'foo';

    with_context {
        use_db 'test1';
        with_context {
            is(context_db->name,'test2','with_context/nested/db');
            is(context_collection->name,'foo2','with_context/nested/collection');
            use_db 'test4';

        } db => 'test2',collection => 'foo2';
        is(context_db->name,'test1','with_context/nested/restore db,inner');
        is(context_collection->name,'foo1','with_context/nested/restor collection,inner');
    } collection => 'foo1';

    is(context_db->name,'mongo_test2','with_context/sandbox/restor db,outer');
    is(context_collection,undef,'with_context/sandbox/restor collection,outer');

    context_db->drop;
}

# for_dbs
{
    my $i = 1;
    for_dbs {
        is(context_db->name,"test$i",'for_dbs/list');
        $i++;
        context_db->drop;
    } 'test1','test2','test3';

    $i = 1;
    for_dbs {
        is(context_db->name,"test$i",'for_dbs/list');
        $i++;
        context_db->drop;
    } qw(test1 test2 test3);
}

{
    use_db 'test';

    my $i=1;
    for_collections {
        is(context_collection->name,"test$i",'for_collections/list');
        $i++;
    } 'test1','test2','test3';

    $i=1;
    for_collections {
        is(context_collection->name,"test$i",'for_collections/list');
        $i++;
    } qw(test1 test2 test3);

    context_db->drop;
}
# bug:context syntax error
{
    my $t = 0;
    with_context {
        $t++;
    };
    is($t,1,'with_context/invoke code bug');
}
