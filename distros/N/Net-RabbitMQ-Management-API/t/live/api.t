use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Most;
use Data::Dumper;

BEGIN {
    use_ok('Net::RabbitMQ::Management::API');
    use_ok('Net::RabbitMQ::Management::API::Result');
}

my $a = Net::RabbitMQ::Management::API->new( url => $ENV{TEST_URI} || 'http://localhost:55672/api' );

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_overview;

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        ok $r->content->{management_version}, 'Attribute exists in response: management_version';
        ok $r->content->{queue_totals},       'Attribute exists in response: queue_totals messages';
        ok $r->content->{node},               'Attribute exists in response: node';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_nodes;

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        ok scalar @{ $r->content }, 'Response is arrayref: nodes exist';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_node } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_node( name => 'foo123' );

    is $r->success, '', 'Node foo123 does not exist';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_extensions;

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        ok scalar @{ $r->content }, 'Response is arrayref: extensions exist';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_configuration;

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        ok $r->content->{rabbit_version}, 'Attribute exists in response: rabbit_version';

        is ref $r->content->{users},       'ARRAY', 'Attribute exists in response: users';
        is ref $r->content->{permissions}, 'ARRAY', 'Attribute exists in response: permissions';
        is ref $r->content->{exchanges},   'ARRAY', 'Attribute exists in response: exchanges';
        is ref $r->content->{queues},      'ARRAY', 'Attribute exists in response: queues';
        is ref $r->content->{bindings},    'ARRAY', 'Attribute exists in response: bindings';
        is ref $r->content->{vhosts},      'ARRAY', 'Attribute exists in response: vhosts';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->update_configuration } qr{Missing key in parameters: users}, 'Missing parameter users';
    throws_ok { $a->update_configuration( users => 'users' ) } qr{Missing key in parameters: vhosts}, 'Missing parameter vhosts';
    throws_ok { $a->update_configuration( users => 'users', vhosts => 'vhosts' ) } qr{Missing key in parameters: permissions}, 'Missing parameter permissions';
    throws_ok { $a->update_configuration( users => 'users', vhosts => 'vhosts', permissions => 'permissions' ) } qr{Missing key in parameters: queues},
      'Missing parameter queues';
    throws_ok { $a->update_configuration( users => 'users', vhosts => 'vhosts', permissions => 'permissions', queues => 'queues', ) }
    qr{Missing key in parameters: exchanges}, 'Missing parameter exchanges';
    throws_ok { $a->update_configuration( users => 'users', vhosts => 'vhosts', permissions => 'permissions', queues => 'queues', exchanges => 'exchanges' ) }
    qr{Missing key in parameters: bindings}, 'Missing parameter bindings';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_configuration;

    # update configuration with the existing one
    $r = $a->update_configuration( %{ $r->content } );

    is $r->success, 1, 'Succesfully updated existing configuration';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_connections;

    is $r->success, 1, 'Succesfully retrieved list of open connections';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_connection } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_connection( name => 'foo17' );

    is $r->success, '', 'Connection foo17 does not exist';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->delete_connection } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->delete_connection( name => 'foo17' );

    is $r->success, '', 'Connection foo17 does not exist';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_channels;

    is $r->success, 1, 'Succesfully retrieved list of channels';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_channel } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_channel( name => 'foo17' );

    is $r->success, '', 'Channel foo17 does not exist';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_exchanges;

    is $r->success, 1, 'Succesfully retrieved list of exchanges';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_exchanges_in_vhost } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_exchanges_in_vhost( vhost => 'foo123' );

    is $r->success, '', 'No exchanges in vhost foo123';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_exchanges_in_vhost( vhost => '%2f' );

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        ok scalar @{ $r->content }, 'Response is arrayref: exchanges exist in vhost /';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->create_exchange } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->create_exchange( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
    throws_ok { $a->create_exchange( name => 'foo', vhost => 'bar' ) } qr{Missing key in parameters: type}, 'Missing parameter type';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->create_exchange( vhost => '%2f', name => 'bar19', type => 'direct' );

    is $r->success, 1, 'Succesfully created exchange bar19';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_exchange } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->get_exchange( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_exchange( vhost => '%2f', name => 'bar19' );

    is $r->success, 1, 'Succesfully retrieved exchange bar19';

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        is $r->content->{name},  'bar19', 'Attribute exists in response: name';
        is $r->content->{vhost}, '/',     'Attribute exists in response: vhost';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_exchange_bindings_by_source } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->get_exchange_bindings_by_source( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_exchange_bindings_by_source( vhost => '%2f', name => 'bar19' );

    is $r->success, 1, 'Succesfully retrieved bindings by source';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_exchange_bindings_by_destination } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->get_exchange_bindings_by_destination( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_exchange_bindings_by_destination( vhost => '%2f', name => 'bar19' );

    is $r->success, 1, 'Succesfully retrieved bindings by destination';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->publish_exchange_message } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->publish_exchange_message( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
    throws_ok { $a->publish_exchange_message( name => 'foo', vhost => 'bar' ) } qr{Missing key in parameters: properties}, 'Missing parameter properties';
    throws_ok { $a->publish_exchange_message( name => 'foo', vhost => 'bar', properties => 'properties' ) } qr{Missing key in parameters: routing_key},
      'Missing parameter routing_key';
    throws_ok { $a->publish_exchange_message( name => 'foo', vhost => 'bar', properties => 'properties', routing_key => 'routing_key' ) }
    qr{Missing key in parameters: payload}, 'Missing parameter payload';
    throws_ok { $a->publish_exchange_message( name => 'foo', vhost => 'bar', properties => 'properties', routing_key => 'routing_key', payload => 'payload' ) }
    qr{Missing key in parameters: payload_encoding}, 'Missing parameter payload_encoding';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->publish_exchange_message(
        vhost            => '%2f',
        name             => 'bar19',
        properties       => {},
        routing_key      => 'my key',
        payload          => 'my body',
        payload_encoding => 'string'
    );

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content->{routed};

        is $r->content->{routed}, '0', 'Attribute exists in response: routed';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->delete_exchange } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->delete_exchange( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->delete_exchange( vhost => '%2f', name => 'bar19' );

    is $r->success, 1, 'Succesfully deleted exchange bar19';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_queues;

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        is ref $r->content, 'ARRAY', 'Attribute exists in response: queues';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_queues_in_vhost } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_queues_in_vhost( vhost => '%2f' );

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        is ref $r->content, 'ARRAY', 'Response is arrayref: get_queues_in_vhost';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->create_queue } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->create_queue( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->create_queue( vhost => '%2f', name => 'bar123' );

    is $r->success, 1, 'Succesfully created queue bar123';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_queue } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->get_queue( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_queue( vhost => '%2f', name => 'bar123' );

    is $r->success, 1, 'Succesfully retrieved queue bar123';

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        is $r->content->{name},  'bar123', 'Attribute exists in response: name';
        is $r->content->{vhost}, '/',      'Attribute exists in response: vhost';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_queue_bindings } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->get_queue_bindings( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_queue_bindings( vhost => '%2f', name => 'bar123' );

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        ok scalar @{ $r->content }, 'Response is arrayref: extensions exist';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->delete_queue_contents } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->delete_queue_contents( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->delete_queue_contents( vhost => '%2f', name => 'bar123' );

    is $r->success, 1, 'Succesfully deleted content for queue bar123';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_queue_messages } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->get_queue_messages( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
    throws_ok { $a->get_queue_messages( name => 'foo', vhost => 'bar' ) } qr{Missing key in parameters: encoding}, 'Missing parameter encoding';
    throws_ok { $a->get_queue_messages( name => 'foo', vhost => 'bar', encoding => 'auto' ) } qr{Missing key in parameters: count}, 'Missing parameter count';
    throws_ok { $a->get_queue_messages( name => 'foo', vhost => 'bar', encoding => 'auto', count => 0 ) } qr{Missing key in parameters: requeue},
      'Missing parameter requeue';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_queue_messages(
        vhost    => '%2f',
        name     => 'bar123',
        count    => 0,
        requeue  => 'true',
        truncate => 50000,
        encoding => 'auto',
    );

    is $r->success, 1, 'Succesfully retrieved message from queue bar123';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->delete_queue } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->delete_queue( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->delete_queue( vhost => '%2f', name => 'bar123' );

    is $r->success, 1, 'Succesfully deleted queue bar123';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_bindings;

    is $r->success, 1, 'Succesfully retrieved list of bindings';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_bindings_in_vhost } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_bindings_in_vhost( vhost => '%2f' );

    is $r->success, 1, 'Succesfully retrieved list of bindings in a given vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_bindings_between_exchange_and_queue } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
    throws_ok { $a->get_bindings_between_exchange_and_queue( vhost => 'foo' ) } qr{Missing key in parameters: exchange}, 'Missing parameter exchange';
    throws_ok { $a->get_bindings_between_exchange_and_queue( vhost => 'foo', exchange => 'exchange' ) } qr{Missing key in parameters: queue},
      'Missing parameter queue';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_bindings_between_exchange_and_queue( vhost => '%2f', exchange => 'foo1', queue => 'bar23' );

    is $r->success, 1, 'Succesfully retrieved list of bindings between exchange and queue';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->create_bindings_between_exchange_and_queue } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
    throws_ok { $a->create_bindings_between_exchange_and_queue( vhost => 'foo' ) } qr{Missing key in parameters: exchange}, 'Missing parameter exchange';
    throws_ok { $a->create_bindings_between_exchange_and_queue( vhost => 'foo', exchange => 'exchange' ) } qr{Missing key in parameters: queue},
      'Missing parameter queue';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    $a->create_exchange( vhost => '%2f', name => 'bar19', type => 'direct' );
    $a->create_queue( vhost => '%2f', name => 'bar123' );

    my $r = $a->create_bindings_between_exchange_and_queue(
        vhost       => '%2f',
        exchange    => 'bar19',
        queue       => 'bar123',
        routing_key => 'my_routing_key',
    );

    is $r->success, 1, 'Succesfully created a binding between exchange and queue';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->create_binding } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
    throws_ok { $a->create_binding( vhost => 'foo' ) } qr{Missing key in parameters: exchange}, 'Missing parameter exchange';
    throws_ok { $a->create_binding( vhost => 'foo', exchange => 'exchange' ) } qr{Missing key in parameters: queue}, 'Missing parameter queue';
    throws_ok { $a->create_binding( vhost => 'foo', exchange => 'exchange', queue => 'queue' ) } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->create_binding( vhost => '%2f', exchange => 'bar19', queue => 'bar123', name => 'binding123' );

    is $r->success, 1, 'Succesfully created individual binding binding123';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_binding } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
    throws_ok { $a->get_binding( vhost => 'foo' ) } qr{Missing key in parameters: exchange}, 'Missing parameter exchange';
    throws_ok { $a->get_binding( vhost => 'foo', exchange => 'exchange' ) } qr{Missing key in parameters: queue}, 'Missing parameter queue';
    throws_ok { $a->get_binding( vhost => 'foo', exchange => 'exchange', queue => 'queue' ) } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_binding( vhost => '%2f', exchange => 'bar19', queue => 'bar123', name => 'binding123' );

    is $r->success, 1, 'Succesfully retrieved individual binding binding123';

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        is $r->content->{vhost},            '/',          'Attribute exists in response: vhost';
        is $r->content->{source},           'bar19',      'Attribute exists in response: source';
        is $r->content->{destination},      'bar123',     'Attribute exists in response: destination';
        is $r->content->{destination_type}, 'queue',      'Attribute exists in response: destination_type';
        is $r->content->{routing_key},      'binding123', 'Attribute exists in response: routing_key';
        is $r->content->{properties_key},   'binding123', 'Attribute exists in response: properties_key';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->delete_binding } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
    throws_ok { $a->delete_binding( vhost => 'foo' ) } qr{Missing key in parameters: exchange}, 'Missing parameter exchange';
    throws_ok { $a->delete_binding( vhost => 'foo', exchange => 'exchange' ) } qr{Missing key in parameters: queue}, 'Missing parameter queue';
    throws_ok { $a->delete_binding( vhost => 'foo', exchange => 'exchange', queue => 'queue' ) } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->delete_binding( vhost => '%2f', exchange => 'bar19', queue => 'bar123', name => 'binding123' );

    is $r->success, 1, 'Succesfully deleted individual binding binding123';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_vhosts;

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->create_vhost } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->create_vhost( name => 'foo23' );

    is $r->success, 1, 'Succesfully created vhost foo23';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_vhost } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_vhost( name => 'foo23' );

    is $r->success, 1, 'Succesfully retrieved vhost foo23';

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        is $r->content->{name}, 'foo23', 'Attribute exists in response: name';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_vhost_permissions } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_vhost_permissions( name => 'foo23' );

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        is scalar @{ $r->content }, '0', 'No permissions for the newly created vhost foo23';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->delete_vhost } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->delete_vhost( name => 'foo23' );

    is $r->success, 1, 'Succesfully deleted vhost foo23';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_users;

    is $r->success, 1, 'Succesfully retrieved list of users';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->create_user } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->create_user ( name => 'foo' ) } qr{Missing key in parameters: tags}, 'Missing parameter tags';
    throws_ok { $a->create_user( name => 'foo', tags => 'administrator' ) } qr{Missing key in parameters: password or password_hash}, 'Missing parameter password or password_hash';

    lives_ok { $a->create_user( name => 'foo', tags => 'administrator', password => 'password' ) } 'Correct parameters do not throw an exception';
    lives_ok { $a->create_user( name => 'foo', tags => 'administrator', password_hash => 'password_hash' ) } 'Correct parameters do not throw an exception'
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->create_user( name => 'foo12', password_hash => 'ISsWSv7CvZZts2lfN+TJPvUkSdo=', administrator => 'true', tags => 'administrator' );

    is $r->success, 1, 'Succesfully created user foo12';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_user } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_user( name => 'foo12' );

    is $r->success, 1, 'Succesfully retrieved user foo12';

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        is $r->content->{name}, 'foo12', 'Attribute exists in response: name';
        is $r->content->{password_hash}, 'ISsWSv7CvZZts2lfN+TJPvUkSdo=', 'Attribute exists in response: password_hash';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_user_details;

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        is $r->content->{name}, 'guest', 'Attribute exists in response: name';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_user_permissions } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_user_permissions( name => 'foo12' );

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        is scalar @{ $r->content }, '0', 'No permissions for the newly created user foo12';
    }
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->create_user_vhost_permissions } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->create_user_vhost_permissions( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
    throws_ok { $a->create_user_vhost_permissions( name => 'foo', vhost => 'bar' ) } qr{Missing key in parameters: write}, 'Missing parameter write';
    throws_ok { $a->create_user_vhost_permissions( name => 'foo', vhost => 'bar', write => 'write' ) } qr{Missing key in parameters: read},
      'Missing parameter read';
    throws_ok { $a->create_user_vhost_permissions( name => 'foo', vhost => 'bar', write => 'write', read => 'read' ) } qr{Missing key in parameters: configure},
      'Missing parameter configure';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->create_user_vhost_permissions( vhost => '%2f', name => 'foo12', configure => '.*', write => '.*', read => '.*' );

    is $r->success, 1, 'Succesfully created permissions for user foo12 in vhost /';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->get_user_vhost_permissions } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->get_user_vhost_permissions( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_user_vhost_permissions( vhost => '%2f', name => 'foo12' );

    is $r->success, 1, 'Succesfully retrieved permissions for user foo12 in vhost /';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->delete_user_vhost_permissions } qr{Missing key in parameters: name}, 'Missing parameter name';
    throws_ok { $a->delete_user_vhost_permissions( name => 'foo' ) } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->delete_user_vhost_permissions( vhost => '%2f', name => 'foo12' );

    is $r->success, 1, 'Succesfully deleted permissions for user foo12 in vhost /';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->delete_user } qr{Missing key in parameters: name}, 'Missing parameter name';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->delete_user( name => 'foo12' );

    is $r->success, 1, 'Succesfully deleted user foo12';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->get_users_permissions;

    is $r->success, 1, 'Succesfully retrieved list of users permissions';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    throws_ok { $a->vhost_aliveness_test } qr{Missing key in parameters: vhost}, 'Missing parameter vhost';
}

SKIP: {
    skip 'Set TEST_LIVE to true to run these tests', 1 unless $ENV{TEST_LIVE};

    my $r = $a->vhost_aliveness_test( vhost => '%2f' );

    if ( $r->success ) {
        isa_ok $r->response, 'HTTP::Response';

        # warn Dumper $r->content;

        ok $r->content->{status}, 'Attribute exists in response: status';

    }
}

done_testing;
