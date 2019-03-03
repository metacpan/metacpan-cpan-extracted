# NAME

Starch::Store::Amazon::DynamoDB - Starch storage backend using Amazon::DynamoDB.

# SYNOPSIS

    my $starch = Starch->new(
        store => {
            class => '::Amazon::DynamoDB',
            ddb => {
                implementation => 'Amazon::DynamoDB::LWP',
                version        => '20120810',
                
                access_key   => 'access_key',
                secret_key   => 'secret_key',
                # or you specify to use an IAM role
                use_iam_role => 1,
                
                host  => 'dynamodb.us-east-1.amazonaws.com',
                scope => 'us-east-1/dynamodb/aws4_request',
                ssl   => 1,
            },
        },
    );

# DESCRIPTION

This [Starch](https://metacpan.org/pod/Starch) store uses [Amazon::DynamoDB](https://metacpan.org/pod/Amazon::DynamoDB) to set and get state data.

# SERIALIZATION

State data is stored in DynamoDB in an odd fashion in order to bypass
some of DynamoDB's and [Amazon::DynamoDB](https://metacpan.org/pod/Amazon::DynamoDB)'s design limitations.

- Empty strings are stored with the value `__EMPTY__` as DynamoDB does
not support empty string values.
- References are serialized using the ["serializer"](#serializer) and prefixed
with `__SERIALIZED__:`.  DynamoDB supports array and hash-like
data types, but [Amazon::DynamoDB](https://metacpan.org/pod/Amazon::DynamoDB) does not.
- Undefined values are serialized as `__UNDEF__`, because
DynamoDB does not support undefined or null values.

This funky serialization is only visibile if you look at the raw
DynamoDB records.  As an example, here's what the
["data" in Starch::State](https://metacpan.org/pod/Starch::State#data) would look like:

    {
        this => 'that',
        thing => { goose=>3 },
        those => [1,2,3],
        name => '',
        age => undef,
        biography => '    ',
    }

And here's what the record would look like in DynamoDB:

    this: 'that'
    thing: '__SERIALIZED__:{"goose":3}'
    those: '__SERIALIZED__:[1,2,3]'
    name: '__EMPTY__'
    age: '__UNDEF__'
    biography: '    '

# REQUIRED ARGUMENTS

## ddb

This must be set to either hash ref arguments for [Amazon::DynamoDB](https://metacpan.org/pod/Amazon::DynamoDB)
or a pre-built object (often retrieved using a method proxy).

When configuring Starch from static configuration files using a
[method proxy](https://metacpan.org/pod/Starch#METHOD-PROXIES)
is a good way to link your existing [Amazon::DynamoDB](https://metacpan.org/pod/Amazon::DynamoDB) object
constructor in with Starch so that starch doesn't build its own.

# OPTIONAL ARGUMENTS

## consistent\_read

When `true` this sets the `ConsistentRead` flag when calling
[get\_item](https://metacpan.org/pod/get_item) on the ["ddb"](#ddb).  Defaults to `true`.

## serializer

A [Data::Serializer::Raw](https://metacpan.org/pod/Data::Serializer::Raw) for serializing the state data for storage
when a field's value is a reference.  Can be specified as string containing
the serializer name, a hashref of Data::Serializer::Raw arguments, or as a
pre-created Data::Serializer::Raw object.  Defaults to `JSON`.

Consider using the `JSON::XS` or `Sereal` serializers for speed.

## table

The DynamoDB table name where states are stored. Defaults to `starch_states`.

## key\_field

The field in the ["table"](#table) where the state ID is stored.
Defaults to `__STARCH_KEY__`.

## expiration\_field

The field in the ["table"](#table) which will hold the epoch
time when the state should be expired.  Defaults to `__STARCH_EXPIRATION__`.

## connect\_on\_create

By default when this store is first created it will issue a ["get"](#get).
This initializes all the LWP and other code so that, in a forked
environment (such as a web server) this initialization only happens
once, not on every child's first request, which otherwise would add
about 50 to 100 ms to the firt request of every child.

Set this to false if you don't want this feature, defaults to `true`.

# METHODS

## create\_table\_args

Returns the appropriate arguments to use for calling `create_table`
on the ["ddb"](#ddb) object.  By default it will look like this:

    {
        TableName => 'starch_states',
        ReadCapacityUnits => 10,
        WriteCapacityUnits => 10,
        AttributeDefinitions => { key => 'S' },
        KeySchema => [ 'key' ],
    }

Any arguments you pass will override those in the returned arguments.

## create\_table

Creates the ["table"](#table) by passing any arguments to ["create\_table\_args"](#create_table_args)
and issuing the `create_table` command on the ["ddb"](#ddb) object.

## set

Set ["set" in Starch::Store](https://metacpan.org/pod/Starch::Store#set).

## get

Set ["get" in Starch::Store](https://metacpan.org/pod/Starch::Store#get).

## remove

Set ["remove" in Starch::Store](https://metacpan.org/pod/Starch::Store#remove).

# SUPPORT

Please submit bugs and feature requests to the
Starch-Store-Amazon-DynamoDB GitHub issue tracker:

[https://github.com/bluefeet/Starch-Store-Amazon-DynamoDB/issues](https://github.com/bluefeet/Starch-Store-Amazon-DynamoDB/issues)

# AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
