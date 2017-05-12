# NAME

Norikra::Client - Client library for Norikra (https://github.com/tagomoris/norikra)

# SYNOPSIS

    use Norikra::Client;
    my $client = Norikra::Client->new("my.norikra.server.local", 26571); # default: "localhost", 26571

    $client->open("my_target");

    $client->send("my_target", [ $event1, $event2 ]); # event: hash of key-value

    $client->event("query1");
    # $VAR1 = [
    #           [
    #             1379519176,
    #             {
    #               'cnt' => 3
    #             }
    #           ],
    #           [
    #             1379519181,
    #             {
    #               'cnt' => 1
    #             }
    #           ],
    #           [
    #             1379519186,
    #             {
    #               'cnt' => 0
    #             }
    #           ]
    #         ];

    $client->see("query1"); # this doesn't delete events on server

    $client->sweep; # or $client->sweep("query_group_name");

    my $targets = $client->targets;

    $client->fields($targets->[0]);
    # $VAR1 = [
    #           {
    #             'type' => 'long',
    #             'optional' => bless( do{\(my $o = 0)}, 'Data::MessagePack::Boolean' ),
    #             'name' => 'hoge'
    #           },
    #           {
    #             'type' => 'long',
    #             'optional' => $VAR1->[0]{'optional'},
    #             'name' => 'pos'
    #           }
    #         ];

    my $queries = $client->queries;
    # $VAR1 = [
    #           {
    #             'targets' => [
    #                            'test1'
    #                          ],
    #             'group' => undef,
    #             'name' => 'q1',
    #             'expression' => 'SELECT count(*) AS cnt FROM test1.win:time_batch(5 sec)'
    #           }
    #         ];

    $client->register("query1", undef, "SELECT count(*) as cnt FROM my_target.win:time_batch(5 sec)");

# DESCRIPTION

Norikra::Client is a client library of Norikra, for perl.
This module can send events to norikra, or receive events from norikra.

CLI tools (assumed as "norikra-client.pl") is not written yet.

# LICENSE

Copyright (C) TAGOMORI Satoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

TAGOMORI Satoshi <tagomoris@gmail.com>
