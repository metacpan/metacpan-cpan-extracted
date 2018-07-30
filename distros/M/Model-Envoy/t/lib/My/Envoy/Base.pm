package My::Envoy::Base;

    use Moose;
    use My::DB;

    my $schema;

    with 'Model::Envoy' => { storage => {
        'DBIC' => {
            schema => sub {
                $schema ||= My::DB->db_connect();
            }
        }
    } };

1;