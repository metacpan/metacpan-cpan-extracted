package Net::NATS::ServerInfo;

use Class::XSAccessor {
    constructors => [ 'new' ],
    accessors => [
        'server_id',
        'version',
        'go',
        'host',
        'port',
        'auth_required',
        'ssl_required',
        'tls_required',
        'max_payload',
    ],
};

1;
