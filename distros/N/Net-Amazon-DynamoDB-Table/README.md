# NAME

Net::Amazon::DynamoDB::Table - Higher level interface to Net::Amazon::DyamoDB::Lite

# SYNOPSIS

    use Net::Amazon::DynamoDB::Table;

    my $table = Net::Amazon::DynamoDB::Table->new(
        region      => 'us-east-1',  # required
        table       => $table,       # required
        hash_key    => 'planet',     # required
        range_key   => 'species',    # required if table has a range key
        access_key  => ...,          # default: $ENV{AWS_ACCESS_KEY};
        secret_key  => ...,          # default: $ENV{AWS_SECRET_KEY};
    );

    # create or update an item
    $table->put(Item => { planet => 'Mars', ... });

    # get the item with the specified primary key; returns a hashref
    my $item = $table->get(planet => 'Mars');

    # delete the item with the specified primary key
    $table->delete(planet => 'Mars');

    # scan the table for items; returns an arrayref of items
    my $items_arrayref = $table->scan();

    # scan the table for items; returns items as a hash of key value pairs
    my $items_hashref = $table->scan_as_hashref();

# DESCRIPTION

A Net::Amazon::DynamoDB::Table object represents a single table in DynamoDB.
This module provides a simple UI layer on top of Net::Amazon::DynamoDB::Lite.

There are two features which make this class "simpler" than
Net::Amazon::DynamoDB::Lite.  

The first is that you don't need to specify the TableName in every call.

The second is that you don't need to worry about types.  

# METHODS

## new()

Returns a Net::Amazon::DynamoDB::Table object.  Accepts the following
attributes:

        region      => 'us-east-1',  # required
        table       => $table,       # required
        hash_key    => $hash_key,    # required
        range_key   => $range_key,   # required if table has a range key
        access_key  => ...,          # default: $ENV{AWS_ACCESS_KEY};
        secret_key  => ...,          # default: $ENV{AWS_SECRET_KEY};
    

## put()

Creates a new item, or replaces an old item with a new item.  This method
accepts the same parameters as those accepted by the AWS DynamoDB put\_item api
endpoint.  Note however, that you don't need to specify any types.  This module
does that for you.  For example:

    $dynamodb->put((
        Item => {
            a => 1,                  # a Number
            b => "boop",             # a String
            c => [ "hi mom", 23.5 ], # a List composed of a String and Number
            d => {                   # a Map
                chipmunks       => [qw/alvin theodore/], # a List of Strings
                backstreet_boys => [qw/Nick Kevin/],     # a List of Strings
                thing           => 23,                   # a Number
            },
        },
    );

## get()

Returns a hashref representing the item specified by the given primary key.
You can specify the primary key using the HashKey and RangeKey parameters
provided for convenience by this module:

    my $item = $dynamodb->get(
        planet  => 'Mars',
        species => 'green aliens',
    );

Or you can explicitly specify the primary key and types using the Key parameter
like this:

    my $item = $dynamodb->get(
        Key => [ 
            { planet  => { S => 'Mars'         } },
            { species => { N => 'green aliens' } },
        ],
    );

This method also accepts the same parameters as those accepted by the
AWS DynamoDB get\_item api endpoint.  For example:

    my $item = $dynamodb->get(
        planet         => 'Mars',
        species        => 'green aliens',
        ConsistentRead => 1,
    );

## delete()

Deletes a single item from a table using the given primary key.  You can
specify the primary key using the HashKey and RangeKey parameters provided for
convenience by this module:

    my $item = $dynamodb->delete(
        planet  => 'Mars',
        species => 'green aliens',
    );

Or you can explicitly specify the primary key and types using the Key parameter
like this:

    my $item = $dynamodb->get(
        Key => [ 
            { planet  => { S => 'Mars'         } },
            { species => { N => 'green aliens' } },
        ],
    );

This method also accepts the same parameters as those accepted by the
AWS DynamoDB get\_item api endpoint.  For example:

    my $item = $dynamodb->get(
        planet                    => 'Mars',
        species                   => 'green aliens',
        ConditionExpression       => "planet := :p",
        ExpressionAttributeValues => { ':p' => { S => 'Mars' } },
    );

## scan()

This method accepts the same parameters as those accepted by the
AWS DynamoDB scan api endpoint.  It returns an arrayref of item hashrefs.

## scan\_as\_hashref()

This method accepts the same parameters as those accepted by the
AWS DynamoDB scan api endpoint.  It returns the results as a hashref that looks
like this:

    # { $hash_key_value1 => $item1,
    #   $hash_key_value2 => $item2, 
    #   ...,
    # }

# ACKNOWLEDGEMENTS

Thanks to [DuckDuckGo](http://duckduckgo.com) for making this module possible.

# LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Eric Johnson <eric.git@iijo.org>
