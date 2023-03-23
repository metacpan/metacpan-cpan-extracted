# NAME

Net::MQTT::Simple::One\_Shot\_Loader - Perl package to add one\_shot method to Net::MQTT::Simple

# SYNOPSIS

    require Net::MQTT::Simple::One_Shot_Loader;
    use Net::MQTT::Simple; #or Net::MQTT::Simple::SSL
    my $mqtt  = Net::MQTT::Simple->new($host);
    my $obj   = $mqtt->one_shot($topic_sub, $topic_pub, $message_pub, $timeout_seconds); #isa Net::MQTT::Simple::One_Shot_Loader::Response
    my $value = $obj->message;

# DESCRIPTION

This package loads the `one_shot` method into the [Net::MQTT::Simple](https://metacpan.org/pod/Net::MQTT::Simple) name space to provide a well tested remote procedure call (RPC) via MQTT.  Many IoT devices only support MQTT as a protocol so, in order to query state or settings these properties need to be requested by sending a message on one queue and receiving a response on another queue.

Due to the way [Net::MQTT::Simple::SSL](https://metacpan.org/pod/Net::MQTT::Simple::SSL) was implemented as a super class of [Net::MQTT::Simple](https://metacpan.org/pod/Net::MQTT::Simple) and since the author of [Net::MQTT::Simple](https://metacpan.org/pod/Net::MQTT::Simple) did not want to implement this method in his package (ref [GitHub](https://github.com/Juerd/Net-MQTT-Simple/pull/22#pullrequestreview-1340685240)), we implemented this method in a method loader package.

# METHODS

## one\_shot

Returns an object representing the first message that matches the subscription topic after publishing the message on the message topic.  Returns an object with the error set to a true value on error like timeout.

    my $response = $mqtt->one_shot($topic_sub, $topic_pub, $message_pub, $timeout_seconds);

    if (not $response->error) {
      my $message  = $response->message;
    }

# SEE ALSO

[Net::MQTT::Simple](https://metacpan.org/pod/Net::MQTT::Simple)

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2023 Michael R. Davis
