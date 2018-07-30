package My::Envoy::CachedBase;

    use Moose;
    use My::DB;

    my $schema;

    with 'Model::Envoy' => {
        storage => {
            'DBIC' => {
                schema => sub {
                    $schema ||= My::DB->db_connect();
                }
            },
        },
        cache => {
            'Memory' => {},
        },
    };

1;