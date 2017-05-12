package MongoX;
# ABSTRACT: DSL sugar for MongoDB
use strict;
use warnings;

our $VERSION = '0.05';

use parent qw( Exporter );
use MongoX::Context;

our @EXPORT = qw(
    boot
    add_connection
    use_connection
    use_collection
    use_db
    context_db
    context_connection
    context_collection
    with_context
    for_dbs
    for_collections
    for_connections
);



sub use_connection { MongoX::Context::use_connection(@_) }


sub use_db { MongoX::Context::use_db(@_) }


sub use_collection { MongoX::Context::use_collection(@_) }


sub context_db { MongoX::Context::context_db }


sub context_connection { MongoX::Context::context_connection }



sub context_collection { MongoX::Context::context_collection }


sub add_connection { MongoX::Context::add_connection(@_) }

sub boot { MongoX::Context::boot(@_) }


sub with_context(&@) { MongoX::Context::with_context(@_) }


sub for_dbs(&@) { MongoX::Context::for_dbs(shift,@_) };


sub for_connections(&@) { MongoX::Context::for_connections(shift,@_) };


sub for_collections(&@) { MongoX::Context::for_collections(shift,@_) };

sub import {
    my ( $class,   %options ) = @_;
    $class->export_to_level( 1, $class, @EXPORT );
    boot %options if %options;
}

1;


=pod

=head1 NAME

MongoX - DSL sugar for MongoDB

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    # quick bootstrap, add connection and switch to db:'test'
    use MongoX ( host => 'mongodb://127.0.0.1',db => 'test' );

    # common way
    use MongoX;
    #register default connection;
    add_connection host => '127.0.0.1';
    # switch to default connection;
    use_connection;
    # use database 'test'
    use_db 'test';
    
    #add/register another connection with id "remote2"
    add_connection host => '192.168.1.1',id => 'remote2';
    
    # switch to this connection
    use_connection 'remote2';
    
    #get a collection object (from the db in current context)
    my $foo = get_collection 'foo';
    
    # use 'foo' as default context collection
    use_collection 'foo';
    
    # use context's db/collection
    say 'total rows:',context_collection->count();
    
    my $id = context_collection->insert({ name => 'Pan', home => 'Beijing' });
    my $gridfs = context_db->get_gridfs;
    
    # loop dbs/collections
    for_dbs{
        for_collections {
            db_ensure_index {created_on => 1};
        } context_db->collection_names;
    } 'db1','db2';

=head1 DESCRIPTION

MongoX is a light wrapper to L<MongoDB> driver, it provide a very simple but handy DSL syntax.
It also will provide some usefull helpers like builtin mongoshell, you can quick work with MongoDB.

=head1 OVERVIEW

MongoX takes a set of options for the class construction at compile time
as a HASH parameter to the "use" line.

As a convenience, you can pass the default connection parameters and default database,
then when MongoX import, it will apply these options to L</add_connection> and L</use_db>,
so the following code:

    use MongoX ( host => 'mongodb://127.0.0.1',db => 'test' );

is equivalent to:

    use MongoX;
    add_connection host => 'mongodb://127.0.0.1';
    use_connection;
    use_db 'test';

C<context_connection>,C<context_db>, C<context_collection> are implicit MongoDB::Connection,
MongoDB::Database and MongoDB::Collection.

=head2 Options

=over

=item host => mongodb server, mongodb connection scheme

=item db => default database

=item utf8 => Turn on/off UTF8 flag. default is turn on utf8 flag.

=back

=head2 DSL keywords

=over

=item use_connection

=item use_db

=item use_collection

=item with_context

=back

use_* keywords can make/switch implicit MongoDB object in context.

with_context allow build a sanbox to execute code block and do something,
the context be restored when out the block.

=over

=item for_connections

=item for_dbs

=item for_collections

=back

These are loop keywords, it will switch related context object in the given list and loop run
the code block.

=head1 ATTRIBUTES

=head2 context_db

    my $db = context_db;

Return current L<MongoDB::Database> object in context;

=head2 context_connection

    my $con = context_connection;

Return current L<MongoDB::Connection> object in context.

=head2 context_collection

    my $col = context_collection;

Return current L<MongoDB::Collection> object in context, you can replace the object
with L</use_collection>.

=head1 METHODS

=head2 use_connection

    # create a default connection
    use_connection;
    # use another connection with id:'con2'
    use_connection 'con2';

Switch to given connection, set the context connection to this connection. 

=head2 use_db

    use_db 'foo';

Switch to the database, set the context database to this database;

=head2 use_collection

    use_collection 'user'

Set 'user' collection  as context collection.

=head2 add_connection

    add_connection id => 'default', host => 'mongodb://127.0.0.1:27017'

Register a connnection with the id, if omit, will add as default connection.
All options exclude 'id' will direct pass to L<MongoDB::Connection>.
The host accept standard mongoDB uri scheme:

mongodb://[username:password@]host1[:port1][,host2[:port2],...[,hostN[:portN]]][/database]

More about, see L<http://www.mongodb.org/display/DOCS/Connections>.

=head2 boot

    boot host => 'mongodb://127.0.0.1',db => 'test'
    # same as:
    add_connection host => 'mongodb://127.0.0.1', id => 'default';
    use_connection;
    use_db 'test';

Boot is equivalent to call add_connection,use_connection,use_db.

=head2 with_context BLOCK db => 'dbname', connection => 'connection_id', collection => 'foo'

    # sandbox
    use_db 'test';
    with_context {
        use_db 'tmp_db';
        # now context db is 'tmp_db'
        ...
    };
    # context db auto restor to 'test'
    
    # temp context
    with_context {
        context_collection->do_something;
    } connection => 'id2', db => 'test2', 'collection' => 'user';
    
    # alternate style
    my $db2 = context_connection->get_database('test2');
    with_context {
        # context db is $db2,collection is 'foo'
        print context_collection->count;
    } db => $db2, 'collection' => 'foo';

C<with_context> let you create a temporary context(sandbox) to invoke the code block.
Before execute the code block, current context will be saved, them build a temporary
context to invoke the code, after code executed, saved context will be restored.

You can explicit setup the sandbox context include connection,db,collection,
or just applied from parent container(context).

with_context allow nested, any with_context will build its context sanbox to run
the attached code block.

    use_db 'test';

    with_context {
        # context db is 'db1'
        with_context {
            # context db is 'db2'
        } db => 'db2';
        # context db restore to 'db1'
    } db => 'db1';

    # context db restore to 'test'

with_context options key:

=over

=item connection =>  connection id or L<MongoDB::Connection>

=item db =>  database name or L<MongoDB::Database>

=item collection =>  collection name or L<MongoDB::Collection>

=back

=head2 for_dbs BLOCK, database List 

    for_dbs {
        print context_db->name;
    } 'test1','test2','test3;

    for_dbs {

        print context_db->name;

    } context_connection->database_names;

Evaluates the code BLOCK for each database of the list. In block scope, context_db will
switch to the list value, and $_ is alias of this context_db value.

=head2 for_connections BLOCK connection_id_list

    for_connections {
        for_dbs { map { print $_ } context_db->collection_names } $_->database_names;
    } 'con_id1', 'con_id2'

Evaluates the code BLOCK against each connection of connection id list. In block scope,
context_connection will switch to the list value, and $_ is alais of the current context_connection.

=head2 for_collections BLOCK collection_list

    # print out all collection's count in the db
    for_collections {
        say $_->name, ' count:', db_count;
    } context_db->collection_names;

    # reindex some collections
    for_collections { db_re_index } 'foo','foo2','foo3';

    # alternate
    for_collections { db_re_index } qw(foo foo2 foo3);
    # alternate
    for_collections { db_re_index } ('foo','foo2','foo3');

=head1 Repository

Github: L<http://github.com/nightsailer/mongo-x>

=head1 SEE ALSO

MongoDB manual: L<http://www.mongodb.org/display/DOCS/Manual>

Official MongoDB driver: L<MongoDB> or L<http://github.com/mongodb/mongo-perl-driver>

My fork: L<http://github.com/nightsailer/mongo-perl-driver>

My blog about this project (Chinese only!): L<http://nightsailer.com/mongox>

=head1 AUTHOR

Pan Fan(nightsailer) <nightsailer at gmail dot com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Pan Fan(nightsailer).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

