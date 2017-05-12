package Norikra::Client;
use 5.008005;
use strict;
use warnings;

use Data::MessagePack;
use MessagePack::RPC::HTTP::Client;

our $VERSION = "0.03";

my $RPC_DEFAULT_PORT = 26571;

sub new {
    my ($this, $host, $port, %opts) = @_;
    $host ||= "localhost";
    $port ||= $RPC_DEFAULT_PORT;
    return bless +{client => MessagePack::RPC::HTTP::Client->new("http://$host:$port/")}, $this;
}

sub client {
    (shift)->{client};
}

sub targets {
    my ($self) = @_;
    $self->client->call("targets");
}

sub open {
    my ($self, $target, $fields, $auto_field) = @_;
    $auto_field = 1 unless defined $auto_field;
    $self->client->call("open", $target, $fields, ($auto_field ? Data::MessagePack::true() : Data::MessagePack::false() ));
}

sub close {
    my ($self, $target) = @_;
    $self->client->call("close", $target);
}

sub modify {
    my ($self, $target, $auto_field) = @_;
    $self->client->call("modify", $target, ($auto_field ? Data::MessagePack::true() : Data::MessagePack::false() ));
}

sub queries {
    my ($self) = @_;
    $self->client->call("queries");
}

sub register {
    my ($self, $query_name, $query_group, $query_expression) = @_;
    $self->client->call("register", $query_name, $query_group, $query_expression);
}

sub deregister {
    my ($self, $query_name) = @_;
    $self->client->call("deregister", $query_name);
}

sub fields {
    my ($self, $target) = @_;
    $self->client->call("fields", $target);
}

sub reserve {
    my ($self, $target, $field, $type) = @_;
    $self->client->call("reserve", $target, $field, $type);
}

sub send {
    my ($self, $target, $events) = @_;
    $self->client->call("send", $target, $events);
}

sub event {
    my ($self, $query_name) = @_;
    $self->client->call("event", $query_name);
}

sub see {
    my ($self, $query_name) = @_;
    $self->client->call("see", $query_name);
}

sub sweep {
    my ($self, $query_group) = @_;
    $self->client->call("sweep", $query_group);
}

1;
__END__

=encoding utf-8

=head1 NAME

Norikra::Client - Client library for Norikra (https://github.com/tagomoris/norikra)

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Norikra::Client is a client library of Norikra, for perl.
This module can send events to norikra, or receive events from norikra.

CLI tools (assumed as "norikra-client.pl") is not written yet.

=head1 LICENSE

Copyright (C) TAGOMORI Satoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

TAGOMORI Satoshi E<lt>tagomoris@gmail.comE<gt>

=cut
