#!/usr/bin/perl -w

# NAME: Redis CappedCollection demonstration

use 5.010;
use strict;
use warnings;

#-- Common ---------------------------------------------------------------------
use Redis::CappedCollection qw(
    $DEFAULT_SERVER
    $DEFAULT_PORT

    $E_NO_ERROR
    $E_MISMATCH_ARG
    $E_DATA_TOO_LARGE
    $E_NETWORK
    $E_MAXMEMORY_LIMIT
    $E_MAXMEMORY_POLICY
    $E_COLLECTION_DELETED
    $E_REDIS
    $E_DATA_ID_EXISTS
    $E_OLDER_THAN_ALLOWED
    );

my $server = $DEFAULT_SERVER.":".$DEFAULT_PORT;   # the Redis Server

sub exception {
    my $coll    = shift;
    my $err     = shift;

    die $err unless $coll;
    if ( $coll->last_errorcode == $E_NO_ERROR )
    {
        # For example, to ignore
        return unless $err;
    }
    elsif ( $coll->last_errorcode == $E_MISMATCH_ARG )
    {
        # Necessary to correct the code
    }
    elsif ( $coll->last_errorcode == $E_DATA_TOO_LARGE )
    {
        # You must use the control data length
    }
    elsif ( $coll->last_errorcode == $E_NETWORK )
    {
        # For example, sleep
        #sleep 60;
        # and return code to repeat the operation
        #return 'to repeat';
    }
    elsif ( $coll->last_errorcode == $E_MAXMEMORY_LIMIT )
    {
        # For example, return code to restart the server
        #return 'to restart the redis server';
    }
    elsif ( $coll->last_errorcode == $E_MAXMEMORY_POLICY )
    {
        # Correct Redis server 'maxmemory-policy' setting
    }
    elsif ( $coll->last_errorcode == $E_COLLECTION_DELETED )
    {
        # For example, return code to ignore
        #return "to ignore $err";
    }
    elsif ( $coll->last_errorcode == $E_REDIS )
    {
        # Independently analyze the $err
    }
    elsif ( $coll->last_errorcode == $E_DATA_ID_EXISTS )
    {
        # For example, return code to reinsert the data
        #return "to reinsert with new data ID";
    }
    elsif ( $coll->last_errorcode == $E_OLDER_THAN_ALLOWED )
    {
        # Independently analyze the situation
    }
    else
    {
        # Unknown error code
    }
    die $err if $err;
}

my ( $id, $coll, @data );

eval {
    $coll = Redis::CappedCollection->create(
        redis   => $server,
        name    => 'Some name', # Create a collection with the specified name
        );
};
exception( $coll, $@ ) if $@;
print "'", $coll->name, "' collection created.\n";

#-- Producer -------------------------------------------------------------------
#-- New data

eval {
    $id = $coll->insert(
        'Some_unique_id',
        123,                # data id
        'Some data stuff',
        );
    print "Added data in a list with '", $id, "' id\n";

    if ( $coll->update( $id, 0, 'Some new data stuff' ) )
    {
        print "Data updated successfully\n";
    }
    else
    {
        print "The data is not updated\n";
    }
};
exception( $coll, $@ ) if $@;

#-- Consumer -------------------------------------------------------------------
#-- Fetching the data

eval {
    @data = $coll->receive( $id );
    print "List '$id' has '$_'\n" foreach @data;

# or
    while ( my ( $id, $data ) = $coll->pop_oldest )
    {
        print "List '$id' had '$data'\n";
    }
};
exception( $coll, $@ ) if $@;

#-- Utility --------------------------------------------------------------------
#-- Getting statistics

my ( $lists, $items );
eval {
    my $info = $coll->collection_info;
    print 'An existing collection uses: ',
        $info->{items}, ' items are placed in ',
        $info->{lists}, ' lists', "\n";

    print "The collection has '$id' list\n" if $coll->list_exists( 'Some_id' );

    print "Collection '", $coll->name, "' has '$_' list\n" foreach $coll->lists;
};
exception( $coll, $@ ) if $@;

#-- Closes and cleans up -------------------------------------------------------

eval {
    $coll->quit;

# Before use, make sure that the collection is not being used by other customers
#    $coll->drop_collection;
};
exception( $coll, $@ ) if $@;

exit;
