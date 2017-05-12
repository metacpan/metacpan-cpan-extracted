package MongoX::Helper;
# ABSTRACT: Helper to invoke MongoDB commands handy.
use strict;
use warnings;

use Carp 'croak';
use Tie::IxHash;
use Digest::MD5 qw(md5_hex);
use MongoX::Context;
use boolean;
use Exporter qw( import );

# admin only commands
my @TAG_ADMIN = qw(
    admin_fsync_lock
    admin_unlock
    admin_server_status
    admin_shutdown_server
    admin_build_info
    admin_get_cmd_line_opts
    admin_log_rotate
    admin_logout
    admin_resync
    admin_sharding_state
    admin_unset_sharding
    admin_diag_logging
);

my @TAG_COMMON = qw(
    db_list_commands
    db_stats
    db_is_master
    db_eval
    db_add_user
    db_remove_user
    db_auth
    db_create_collection
    db_convert_to_capped
    db_ping
    db_repair_database
    db_run_command
    db_current_op
    db_re_index
    db_filemd5
    db_map_reduce
    db_distinct
    db_group
    db_insert
    db_count
    db_remove
    db_update
    db_update_set
    db_find_one

    db_find
    db_find_all
    db_find_and_modify
    db_increment
    db_ensure_index
    db_drop_index
    db_drop_indexes
    db_get_indexes

    db_find_by_id
    db_remove_by_id
);
# TODO: Replica Set commands
my @TAG_RS = qw(
    rs_freeze
    rs_get_status
    rs_initiate
    rs_reconfig
    rs_step_down
);

our %EXPORT_TAGS = (
    admin => [@TAG_ADMIN],
    all => [ @TAG_COMMON, @TAG_ADMIN ]
);
our @EXPORT_OK = (@TAG_ADMIN,@TAG_COMMON);
our @EXPORT = @TAG_COMMON;


sub AUTOLOAD {
    shift;
    our $AUTOLOAD;
    my $cmd_name = $AUTOLOAD;
    my $admin_only = 0;

    $cmd_name =~ s/.*:://;
    if ($cmd_name =~ m/^db_/ ) {
        $cmd_name =~ s/^db_//;
    }
    elsif ($cmd_name =~ m/^admin_/ ) {
        $cmd_name =~ s/^admin_//;
        $admin_only = 1;
    }

    $cmd_name = lcfirst(join('', map{ ucfirst $_ } split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $cmd_name)));

    # print '$cmd_name:',$cmd_name,"\n";
    {
        no strict 'refs';
        if ($admin_only) {
            *$AUTOLOAD = sub {
                my $c = Tie::IxHash->new($cmd_name => 1,@_);
                return __PACKAGE__->_admin_db->run_command($c);
            };
        }
        else {
            *$AUTOLOAD = sub {
                my $c = Tie::IxHash->new($cmd_name => 1,@_);
                # $c->Push(@_);
                return __PACKAGE__->_db->run_command($c);
            };
        }
    }
    goto &$AUTOLOAD;
}


# private
sub _db { MongoX::Context::context_db }

sub _connection { MongoX::Context::context_connection }

sub _collection { MongoX::Context::context_collection }

sub _admin_db { MongoX::Context::context_connection->get_database('admin') }

# ====================admin only commands section


sub admin_fsync_lock {
    my $result = _admin_db->run_command(Tie::IxHash->new('fsync' => 1, 'lock' => 1));
    return $result->{ok} ? 1 : 0;
}


sub admin_unlock {
    my $result = _admin_db->get_collection('$cmd.sys.unlock')->find_one();
    return $result->{ok} ? 1 : 0;
}





sub admin_shutdown_server {
    eval { _admin_db->run_command({ shutdown => 1 }) };
    # hack, todo
    return 1 if $@ =~ m/couldn't connect to server/;
}



# ====================common commands section


sub db_stats { db_run_command({dbstats => 1 }) }


sub db_is_master {
    my $result = db_run_command({isMaster => 1});
    return unless ref $result;
    return $result->{ismaster}?1:0;
}



sub db_eval { _db->eval(@_) }


sub db_current_op {
    _connection->get_database('local')->get_collection('$cmd.sys.inprog')->find_one();
}


sub db_filemd5 {
    my $result = db_run_command({filemd5 => shift });
    return unless $result;
    return $result->{md5};
}



sub db_re_index {
    my ($col) = @_;
    $col ||= _collection->name;
    my $result = db_run_command({reIndex => $col});
    return $result->{ok}?1:0;
}


sub db_distinct {
    my ($key,$query) = @_;
    my $result = db_run_command(Tie::IxHash->new(
        distinct  => _collection->name,
        key => $key,
        query => ref $query ? $query : {},
    ));
    return unless ref $result;
    return $result->{values};
}


sub db_group {
    my ($args) = @_;
    my $group = { ns => _collection->name };
    $group->{cond} = ref $args->{condition} ? $args->{condition} : {};
    $group->{'$reduce'} = $args->{reduce};
    $group->{key} = $args->{key} if $args->{key};
    $group->{'$keyf'} = $args->{keyf} if $args->{keyf};
    $group->{initial} = ref $args->{initial} ? $args->{initial} : {};
    $group->{finalize} = $args->{finalize} if $args->{finalize};
    my $result = db_run_command({ group => $group });
    return unless ref $result;
    return $result->{retval};
}


sub db_map_reduce {
    my ($opts) = @_;
    my $cmd = Tie::IxHash->new('mapreduce' => _collection->name,'map' => $opts->{map},'reduce' => $opts->{reduce});
    $cmd->Push(query => $opts->{query}) if exists $opts->{query};
    $cmd->Push(sort => $opts->{sort}) if exists $opts->{sort};
    $cmd->Push(limit => $opts->{limit}) if exists $opts->{limit};
    $cmd->Push(out => $opts->{out}) if exists $opts->{out};
    $cmd->Push(keeptemp => $opts->{keeptemp}? true:false ) if exists $opts->{keeptemp};
    $cmd->Push(finalize => $opts->{finalize}) if exists $opts->{finalize};
    $cmd->Push(scope => $opts->{scope}?true:false) if exists $opts->{scope};
    my $result = db_run_command($cmd);
    return unless ref $result;
    return _db->get_collection($result->{result}) if $result->{ok};
}



sub db_run_command { _db->run_command(@_) }


sub db_list_commands {
    my $result = db_run_command { listCommands => 1};
    return unless ref $result;
    return $result->{commands};
}


sub db_add_user {
    my ($username,$password,$readonly) = @_;
    my $col = _db->get_collection('system.users');
    my $user = $col->find_one({user => $username});
    $user ||= { user => $username};
    $user->{readOnly} = $readonly?true:false;
    $user->{pwd} = md5_hex($username.':mongo:'.$password);
    $col->save($user);
}



sub db_remove_user { _db->get_collection('system.users')->remove({ user => shift }) }



sub db_find_and_modify {
    my ($options) = @_;

    my $cmd = Tie::IxHash->new(findandmodify => _collection->name );

    $cmd->Push(query => $options->{query} || {});
    $cmd->Push(new => $options->{new} ? true : false ) if exists $options->{new};
    $cmd->Push(remove => $options->{remove} ? true : false) if exists $options->{remove};
    $cmd->Push(update => $options->{update}) if exists $options->{update};
    $cmd->Push(sort => $options->{sort}) if exists $options->{sort};

    my $result;

    eval {
        $result = db_run_command($cmd);
    };
    if ($@) {
        croak $@;
    }
    unless (ref $result) {
        if ($result eq 'No matching object found') {
            return;
        }
        croak $result;
    }
    return $result->{value};
}



sub db_auth {
    my ($username,$password,$is_digest) = @_;
    my $result = _connection->authenticate(_db->name,$username,$password,$is_digest);
    return unless ref $result;
    return $result->{ok};
}


sub db_convert_to_capped { db_run_command(Tie::IxHash->new('convertToCapped' => shift, 'size' => shift)) }


sub db_create_collection {
    my ($name,$options) = @_;
    $options = {} unless ref $options;
    my $cmd = Tie::IxHash->new('create' => $name);
    $cmd->Push('capped' => $options->{capped}) if exists $options->{capped};
    $cmd->Push('size' => $options->{size}) if exists $options->{size};
    $cmd->Push('max' => $options->{max}) if exists $options->{max};
    db_run_command($cmd);
}



sub db_insert {
    croak 'context_collection not defined,forget(use_collection?)' unless _collection;
    _collection->insert(@_);
}



sub db_find {
    croak 'context_collection not defined,forget(use_collection?)' unless _collection;
    _collection->find(@_);
}


sub db_find_all {
    my $cursor = db_find(@_);
    return unless $cursor;
    $cursor->all;
}


sub db_count {
    croak 'context_collection not defined,forget(use_collection?)' unless _collection;
    _collection->count(@_);
}



sub db_increment {
    my ($query,$field_deltas,$options) = @_;
    db_update($query, { '$inc' => $field_deltas }, $options);
}


sub db_update_set {
    my ($query,$set_obj,$options) = @_;
    $options ||= {};
    db_update($query,{ '$set' => $set_obj },$options);
}


sub db_update {
    croak 'context_collection not defined,forget(use_collection?)' unless _collection;
    _collection->update(@_);
}


sub db_remove {
    croak 'context_collection not defined,forget(use_collection?)' unless _collection;
    _collection->remove(@_);
}


sub db_find_one {
    croak 'context_collection not defined,forget(use_collection?)' unless _collection;
    _collection->find_one(@_);
}


sub db_ensure_index {
    croak 'context_collection not defined,forget(use_collection?)' unless _collection;
    return _collection->ensure_index(@_);
}


sub db_drop_index {
    croak 'context_collection not defined,forget(use_collection?)' unless _collection;
    return _collection->drop_index(@_);
}


sub db_drop_indexes {
    croak 'context_collection not defined,forget(use_collection?)' unless _collection;
    return _collection->drop_indexes(@_);
}


sub db_get_indexes {
    croak 'context_collection not defined,forget(use_collection?)' unless _collection;
    return _collection->get_indexes;
}


sub db_find_by_id {
    my ($id) = @_;
    $id = MongoDB::OID->new(value => "$id") unless ref $id eq 'MongoDB::OID';
    db_find_one {_id => $id};
}

sub db_remove_by_id {
    my ($id) = @_;
    $id = MongoDB::OID->new(value => "$id") unless ref $id eq 'MongoDB::OID';
    db_remove {_id => $id};
}

1;



=pod

=head1 NAME

MongoX::Helper - Helper to invoke MongoDB commands handy.

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    # default import common db_* helpers
    use MongoX::Helper;

    # or admin only command
    use MongoX::Helper ':admin';

    # explicit some command
    use MongoX::Helper qw(db_count,db_find,admin_unlock,admin_shutdown_server);

    # or all commands
    use MongoX::Helper ':all';

=head1 DESCRIPTION

=head1 METHODS

=head2 admin_fsync_lock

    my $ok = admin_fsync_lock;

call fsync_lock on current server.

=head2 admin_unlock

    my $ok = admin_unlock;

call unlock on current server.

=head2 admin_server_status

    my $result = admin_server_status;
    print 'server uptime:',$result->{uptime};

Return current mongoDB server status.

=head2 admin_shutdown_server

    admin_shutdown_server;

Shutdown current mongodb server.

=head2 admin_sharding_state

    $result = admin_sharding_state;

Get sharding state.

=head2 admin_diag_logging

    $result = admin_diag_logging;
    print 'logging level:',$result->{was},"\n";

Get diag logging level.

=head2 db_stats

    my $stats_info = db_stats;

Return current database stats information;

=head2 db_is_master

    $ok = db_is_master;

Return if current server is master.

=head2 db_eval($code,$args?)

    my $result = db_eval 'function(x) { return "hello, "+x; }', ["world"];

Evaluate a JavaScript expression on the Mongo server.

=head2 db_current_op

    my $op = db_current_op;

Return current operation in the db.

=head2 db_filemd5($file_id)

    $md5_hex = db_filemd5 $file_id;

return md5 hex value of the file.

=head2 db_re_index($collection_name?)

    $ok = db_re_index;

rebuild the collection indexes (default collection is context_collection).

=head2 db_distinct

    $result = db_distinct;

Performance a distinct query.

=head2 db_group

    $result = db_group {
        reduce => 'function(doc,prev){ prev[doc.name]++; }',
        key => { key1 => 1,key2 => 1 },
        initial => { counter => 0.0 }
    };
    
    # or
    $result = db_group {
        reduce => 'function(doc,prev){ prev[doc.name]++; }',
        keyf => 'function(doc) { return {"x" : doc.x};',
        initial => {counter => 0.0}
    };

Returns an array of grouped items of current context collection. options:

=over

=item reduce

The reduce function aggregates (reduces) the objects iterated. Typical operations of a reduce function
include summing and counting. reduce takes two arguments:
the current document being iterated over and the aggregation counter object.
In the example above, these arguments are named obj and prev.

=item key

Fields to group by.

=item keyf?

An optional function returning a "key object" to be used as the grouping key. Use this instead of key to specify a key that is not an existing member of the object (or, to access embedded members). Set in lieu of key.

=item initial?

initial value of the aggregation counter object.

    initial => { counter => 0.0 }

B<WARNING: As a known bug, in initial, if you assign a zero numberic value to some attribute, you must defined zero as float format,
meant must be 0.0 but not 0, cause 0 will passed as boolean value, then you will got 'nan' value in retval.>

=item finalize?

An optional function to be run on each item in the result set just before the item is returned.
Can either modify the item (e.g., add an average field given a count and a total)
or return a replacement object (returning a new object with just _id and average fields).

=back

more about group, see: L<http://www.mongodb.org/display/DOCS/Aggregation#Aggregation-Group>.

=head2 db_map_reduce

    $result = db_map_reduce { map => 'javascript function',reduce => 'javascript function' };

map, reduce, and finalize functions are written in JavaScript.

valid options are:

=over

=item map => mapfunction

=item reduce => reducefunction

=item query  => query filter object

=item sort  => sort the query.  useful for optimization

=item limit  => number of objects to return from collection

=item out => output-collection name

=item keeptemp => boolean

=item finalize => finalizefunction

=item scope => object where fields go into javascript global scope

=item verbose => boolean

=back

more about map/reduce, see: L<http://www.mongodb.org/display/DOCS/MapReduce>.

=head2 db_run_command

    my $result = db_run_command {dbstats:1};

Run the command on current database. shortcut of L<MongoDB::Database/run_command>.

=head2 db_list_commands

    my $command_list = db_list_commands;
    foreach my $cmd (keys %{$command_list}) {
        say 'Command name:',$cmd,"\n";
        say 'adminOnly:' => $cmd->{adminOnly};
        say 'help:' => $cmd->{help};
        say 'lockType:' => $cmd->{lockType};
        say 'slaveOk:' => $cmd->{slaveOk};
    }

Get a hash reference of all db commands.

=head2 db_add_user($username,$password,$readonly?)

    $ok = db_add_user('foo','12345');

Add user into current database.

=head2 db_remove_user($username)

    $ok = db_remove_user $username;

Remove given user from current database.

=head2 db_find_and_modify($options)

    my $next_val = db_find_and_modify {
        query => { _id => 'foo'},
        update => { '$inc' => { value => 1 } }
    }
    
    # simply remove the object to be returned
    my $obj = db_find_and_modify({
        query => { _id => 10 },
        remove => 1
    });

MongoDB 1.3+ supports  a "find, modify, and return" command.
This command can be used to atomically modify a document (at most one) and return it.
B<Note:that the document returned will not include the modifications made on the update>.
The options can include 'sort' option which is useful when storing queue-like data.

=head3 option parameters

At least one of the update or remove parameters is required; the other arguments are optional.

=over

=item C<query>

A query selector document for matching the desired document. default is {}.

=item C<sort>

if multiple docs match, choose the first one in the specified sort order as the object to manipulate. default is {}.

=item C<remove => boolean>

set to a true to remove the object before returning. default is false.

=item C<update>

a modifier object.  default is undef.

=item C<new => boolean>

set to true if you want to return the modified object rather than the original. Ignored for remove. default is false.

=back

=head2 db_repair_database

    my $result = db_repair_database;
    print 'ok:'.$result->{ok};

Repair current database.

=head2 db_auth($username,$password,$is_digest)

    $ok = db_auth 'pp', 'plain-text';

Attempts to authenticate for use of the current database with $username and $password.
Shortcut of L<MongoDB::Connection/authenticate>.

=head2 db_convert_to_capped($collection_name,$size)

    db_convert_to_capped 'common_collection1',1024*1024*10;

Convert a normal collection to capped collection.

=head2 db_create_collection($name,$options?)

    $result = db_create_collection 'foo',{ capped => 1 };

Explicit create a special (capped) collection.

=head2 db_insert(\%obj)

    db_insert {name => 'ns',workhard => 'mongox' };

Implicit call C<context_collection->insert>.

=head2 db_find($query?,$options?)

    $cursor = db_find {name => 'foo'};

Implicit call C<context_collection->find>.

=head2 db_find_all($query?,$options?)

    @result = db_find_all {age => 30},{limit => 20};

Short of C<db_find()->all>.

=head2 db_count($query?)

    $total = db_count { name => 'foo' };

Implicit call C<context_collection->count>.

=head2 db_increment($query,$increment_values,$options)

    db_increment {name => 2},{ counter => 1, money => 10 },{upsert => 1};

Shortcut of '$inc' command.

=head2 db_update_set(\%criteria,\%set_object,\%options)

    db_update_set {name => 'foo'},{new_location => 'Beijing'},{ upsert => 0 };

Shortcut for '$set' command.

=head2 db_update(\%criteria,\%new_object,\%options?)

    db_update {_id => 5},{name => 'foo'};

Shortcut of L<MongoDB::Collection/update>.

=head2 db_remove(\%criteria?,\%options?)

    db_remove;

Shortcut of L<MongoDB::Collection/remove>.

=head2 db_find_one(\%query?,\%options?)

    $result = db_find_one {_id => 5};

Shortcut of L<MongoDB::Collection/find_one>.

=head2 db_ensure_index(\%keys,\%options?)

    $result = db_ensure_index { foo => 1, name => 1};

Shortcut of L<MongoDB::Collection/ensure_index>.

=head2 db_drop_index($index_name)

    db_drop_index { 'name_1' };

Shortcut of L<MongoDB::Collection/drop_index>.

=head2 db_drop_indexes

    db_drop_indexes;

Shortcut of L<MongoDB::Collection/drop_indexes>.

=head2 db_get_indexes

    db_get_indexes;

Shortcut of L<MongoDB::Collection/get_indexes>.

=head2 db_find_by_id

    my $row = db_find_by_id $oid_or_id_string

Quick find_one by _id.

=head2 db_remove_by_id

    db_remove_by_id $oid_or_id_string

Quick remove by _id.

=head1 SEE ALSO

MongoDB Commands docs: L<http://www.mongodb.org/display/DOCS/Commands>

=head1 AUTHOR

Pan Fan(nightsailer) <nightsailer at gmail dot com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Pan Fan(nightsailer).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

