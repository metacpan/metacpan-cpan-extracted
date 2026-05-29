# NAME

Net::STOMP::Client::Wrapper - Stomp Client and RabbitMQ Management API wrapper

# SYNOPSIS

Producer

    use Net::STOMP::Client::Wrapper;
    my $wrapper = Net::STOMP::Client::Wrapper->new(queue_name=>"my_queue");   #ISA Net::STOMP::Client::Wrapper
    my $stomp   = $wrapper->stomp_connect;                                    #ISA Net::STOMP::Client connected
    $wrapper->send(body=>"my_payload");

Consumer

    use Net::STOMP::Client::Wrapper;
    my $wrapper = Net::STOMP::Client::Wrapper->new(queue_name=>"my_queue");   #ISA Net::STOMP::Client::Wrapper
    my $stomp   = $wrapper->stomp_connect_subscribe;                          #ISA Net::STOMP::Client subscribed to queue
    $stomp->wait_for_frames(callback => \&queue_callback);

Monitor

    use Net::STOMP::Client::Wrapper;
    my $wrapper   =  Net::STOMP::Client::Wrapper->new(queue_name=>"my_queue"); #ISA Net::STOMP::Client::Wrapper
    my $result    = $wrapper->management_api_get_queue;                       #ISA Net::RabbitMQ::Management::API::Result
    my $content   = $result->content;                                         #ISA HASH
    my $consumers = $content->{'consumers'} || 0;
    my $messages  = $content->{'messages'}  || 0;
    printf "Consumers: %s, Messages: %s\n", $consumers, $messages;

Super Class

    package My::Wrapper;
    use base qw{Net::STOMP::Client::Wrapper};
    sub host {"my_host"};
    sub queue_name {"my_queue"};

# DESCRIPTION

Net::STOMP::Client::Wrapper is a wrapper of [Net::STOMP::Client](https://metacpan.org/pod/Net%3A%3ASTOMP%3A%3AClient) and [Net::RabbitMQ::Management::API](https://metacpan.org/pod/Net%3A%3ARabbitMQ%3A%3AManagement%3A%3AAPI) with sane defaults.

This package is a wrapper for my typical use case which is a single RabbitMQ server with the Stomp and Management API plugins enabled and a single queue\_name.

    sudo yum install rabbitmq-server
    sudo /usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_stomp
    sudo /usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management
    sudo systemctl enable rabbitmq-server
    sudo systemctl start rabbitmq-server

# Properties

## host

Default: 127.0.0.1

## port

Default: 61613

## login

Default: guest

## passcode

Default: guest

## vhost, vhost\_url\_encoded

Default: /

## queue\_name, destination

Returns the short queue\_name or the formatted destination.

    $wrapper->queue_name("my_queue")
    my $queue_name  = $wrapper->queue_name;
    my $destination = $wrapper->destination; #ISA string formatted as "/queue/{queue_name}"

Default: ''

## subscribe\_id

Default: {uuid}

## subscribe\_ack

Default: client

## subscribe\_prefetch\_count

Default: 1

## management\_api\_url

Default: http://{host}:15672/api

# Methods

## send

Wrapper around \`stomp->send\` with default destination

    $wrapper->send(body=>"my_string"); #destination is defaulted to $wrapper->destination;
    $wrapper->send(destination=>"/queue/another_queue", body=>"my_string");

Note: stomp must be connected before calling send.

## management\_api\_get\_queue

Returns a [Net::RabbitMQ::Management::API::Result](https://metacpan.org/pod/Net%3A%3ARabbitMQ%3A%3AManagement%3A%3AAPI%3A%3AResult) object

# Object Accessors

## stomp\_connect\_subscribe

Returns a [Net::STOMP::Client](https://metacpan.org/pod/Net%3A%3ASTOMP%3A%3AClient) object connection and subscribed to the configured queue

    my $stomp = $wrapper->stomp_connect_subscribe;

Limitations: Only Call once!

## stomp\_connect

Returns a connected [Net::STOMP::Client](https://metacpan.org/pod/Net%3A%3ASTOMP%3A%3AClient) object.

    my $stomp = $wrapper->stomp_connect;

Limitations: Only Call once!

## stomp\_disconnect

Unsubscribes to any subscriptions and disconnects stomp client.

## stomp

Returns the cached [Net::STOMP::Client](https://metacpan.org/pod/Net%3A%3ASTOMP%3A%3AClient) object

## management\_api

Returns a [Net::RabbitMQ::Management::API](https://metacpan.org/pod/Net%3A%3ARabbitMQ%3A%3AManagement%3A%3AAPI) object

# SEE ALSO

[Net::STOMP::Client](https://metacpan.org/pod/Net%3A%3ASTOMP%3A%3AClient), [Net::RabbitMQ::Management::API](https://metacpan.org/pod/Net%3A%3ARabbitMQ%3A%3AManagement%3A%3AAPI)

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

Copyright (C) 2025 by Michael Davis

LICENSE: MIT
