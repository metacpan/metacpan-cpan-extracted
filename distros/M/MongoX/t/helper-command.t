use strict;
use warnings;
use Test::More;
use Test::Deep;
use IO::File;
use Digest::MD5 qw(md5_hex);
my $host;

BEGIN {
    $host = 'localhost';
    # check test
    if (exists $ENV{MONGOD}) {
        $host = $ENV{MONGOD};
    }
    eval "use MongoX host => '$host', db => 'test'";
    if ($@) {
        plan skip_all => $@;
    }
    else {
        plan tests => 39;
    }
}

use MongoX::Helper;

my $result = db_list_commands;

is($result->{resync}->{adminOnly},1,'db_list_commands');

# note explain $result;

$result = db_stats;

ok(exists $result->{storageSize},'db_stats');

ok(db_is_master,'db_is_master');

is(db_eval('function(){return 10;}'),10,'db_eval');

ok(db_add_user('pan_fan_ns','12345'),'db_add_user');

ok(db_auth('pan_fan_ns','12345'),'db_auth');

db_remove_user('pan_fan_ns');
ok(!db_auth('pan_fan_ns','12345'),'db_remove_user');

$result = db_ping;
ok($result->{ok},'db_ping');

$result = db_run_command {ping => 1};
ok($result->{ok},'db_run_command');

diag('Testing repair database, this will take a while ...');
$result = db_repair_database;
ok($result->{ok},'db_repair_database');


$result = db_current_op;
ok(exists $result->{inprog},'db_current_op');

{
    use_collection 'foo_test';
    db_ensure_index({ name => 1});
    my $indexes = db_get_indexes;
    is($indexes,2,'db_get_indexes/db_ensure_index');
    my $ok = db_drop_index('name_1');
    is($ok->{ok},1,'db_drop_index');
    ok(db_re_index,'db_re_index');
    db_drop_indexes;
    is(db_get_indexes,1,'db_drop_indexes');
    context_collection->drop;
}

{
    context_db->get_collection('capped_foo')->drop();
    $result = db_create_collection 'capped_foo',{ capped => 1 };
    ok($result->{ok},'db_create_collection');
    context_db->capped_foo->drop();
}

{
    db_create_collection 'common_foo';
    $result = db_convert_to_capped('common_foo',1024*1000);
    ok($result->{ok},'db_convert_to_capped');
    context_db->common_foo->drop();
}
{
    my $gridfs = context_db->get_gridfs;
    my $bytes = 'abx'x20;
    my $fh = new IO::File \$bytes,'<';
    my $id = $gridfs->insert($fh);
    is(db_filemd5($id),md5_hex($bytes),'db_filemd5');
    $gridfs->remove({_id => $id});
}

{
    use_collection 'foo';
    my $id = db_insert {name => 'foo1'};
    isa_ok($id,'MongoDB::OID');
    $id = db_insert {_id => 2, name => 'foo2'};
    is($id,2,'db_insert');
    context_collection->drop;
}

{
    use_collection 'mongox_test';

    db_insert {'tag' => 'A' };
    db_insert {'tag' => 'A' };
    db_insert {'tag' => 'B' };
    db_insert {'tag' => 'C' };
    db_insert {'tag' => 'C' };
    $result = db_group {
        reduce => 'function(doc,out){ out.count++; }',
        initial => { count => 0.0 },
        key => {tag => 1}
    };
    cmp_deeply($result,[
        { count => 2, tag => 'A' },
        { count => 1, tag => 'B' },
        { count => 2, tag => 'C' },
        ],'db_group');
    context_collection->drop;
}

{
    use_collection 'mongox_test';
    db_insert {'tag' => 'A' };
    db_insert {'tag' => 'A' };
    db_insert {'tag' => 'B' };
    db_insert {'tag' => 'C' };
    db_insert {'tag' => 'C' };

    $result = db_distinct 'tag';
    # is(@{$result},3,'db_distinct');
    cmp_deeply( $result, ['A','B','C'],'db_distinct');
    context_collection->drop;
}
{
    use_collection 'mongox_test';
    context_collection->drop;
    db_insert {'tags' => ['A','B'] ,state => 1 };
    db_insert {'tags' => ['C','B'] ,state => 0  };
    db_insert {'tags' => ['C','B'] ,state => 1  };
    db_insert {'tags' => ['C','B'] ,state => 1  };
    db_insert {'tags' => ['G','B'] ,state => 1  };
    db_insert {'tags' => ['D','A'] ,state => 1  };
    db_insert {'tags' => ['C','B'] ,state => 1  };
    db_insert {'tags' => ['E','B'] ,state => 2  };
    db_insert {'tags' => ['C','E'] ,state => 0  };

    my $map = <<MAP;
    function() {
        this.tags.forEach(function(tag) {
            emit(tag, {count : 1});
        });
    }
MAP
    my $reduce = <<REDUCE;
    function(prev, current) {
        result = {count : 0};
        current.forEach(function(item) {
            result.count += item.count;
        });
        return result;
    }
REDUCE

    $result = db_map_reduce { map => $map,reduce => $reduce };
    my @tags = $result->find->all;
    cmp_deeply(\@tags,[
    {'_id' => 'A', 'value' => { count => 2 } },
    {'_id' => 'B', 'value' => { count => 7 } },
    {'_id' => 'C', 'value' => { count => 5 } },
    {'_id' => 'D', 'value' => { count => 1 } },
    {'_id' => 'E', 'value' => { count => 2 } },
    {'_id' => 'G', 'value' => { count => 1 } },
    ],'db_map_reduce');
    $result->drop;

    $result = db_map_reduce { map => $map,reduce => $reduce ,query => {state => 1} };
    @tags = $result->find->all;
    cmp_deeply(\@tags,[
    {'_id' => 'A', 'value' => { count => 2 } },
    {'_id' => 'B', 'value' => { count => 5 } },
    {'_id' => 'C', 'value' => { count => 3 } },
    {'_id' => 'D', 'value' => { count => 1 } },
    {'_id' => 'G', 'value' => { count => 1 } },
    ],'db_map_reduce/query');
    $result->drop;

    context_collection->drop;
    
    
}
{
    use_collection 'mongox_test';
    
    db_insert { _id => 1, 'counter' => 1 };
    db_insert { _id => 2, 'counter' => 1 };
    is(db_count,2,'db_count');

    db_remove;
    is(db_count,0,'db_remove');
    
    db_update {_id => 1},{ _id => 1, 'counter' => 1 },{ upsert => 1};
    
    is(db_count,1,'db_update');
    
    cmp_deeply(db_find_one,{ _id => 1, 'counter' => 1 },'db_find_one');
    
    db_update_set {_id => 1},{'new_attr' => 25};
    
    cmp_deeply(db_find_one,{ _id => 1, 'counter' => 1, new_attr => 25 },'db_update_set');
    
    isa_ok(db_find,'MongoDB::Cursor','db_find');
    
    my @rows = db_find_all;
    
    cmp_deeply(\@rows,[{ _id => 1, 'counter' => 1, new_attr => 25 }],'db_find_all');
    
    db_increment {_id => 1}, {new_attr => 1,counter => 2};
    
    cmp_deeply(db_find_one({_id => 1}),{_id => 1, counter => 3, new_attr => 26},'db_increment');
    context_collection->drop;
}
{
    use_collection 'mongox_test';
    context_collection->drop;
    
    db_insert { x => 1 };
    my $obj = db_find_and_modify { update => {'$inc' => {'x' => 1}} };
    my $obj2 = db_find_one;
    
    ok($obj->{x}==1 && $obj2->{x} == 2,'find_and_modify update/inc');

    $obj = db_find_and_modify({remove => 1});
    
    ok($obj->{x} == 2 && db_count == 0,'find_and_modify /remove');
    
    db_insert({x => 1,idx => 1});
    db_insert({x => 2,idx => 2});
    db_insert({x => 3,idx => 3});
    
    $obj = db_find_and_modify {sort => {idx => -1}, remove => 1};
    
    is($obj->{x},3,'find_and_modify/sort');
    
    $obj = db_find_and_modify { query => { x => 1}, new => 1, update => { x => 1, idx => 200 } };
    $obj2 = db_find_one({x => 1});
    ok($obj->{idx} == $obj2->{idx} && $obj2->{idx} == 200,'find_and_modify/new option');
    
    context_collection->drop;
}
{
    use_collection 'mongox_test';
    context_collection->drop;
    my $oid = db_insert {foo => 1};
    my $row = db_find_by_id $oid;
    is($row->{foo},1,'db_find_by_id/oid');
    $row = db_find_by_id $oid->value;
    is($row->{foo},1,'db_find_by_id/id string');
    db_remove_by_id $oid->value;
    is(db_count,0,'db_remov_by_id');
}
TODO: {
    local $TODO = 'these collection shortcut not done.';
}