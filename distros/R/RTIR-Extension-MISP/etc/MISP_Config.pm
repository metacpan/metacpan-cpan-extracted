=pod

This is an example configuration for a MISP feed. Replace the
URI/ApiKeyAuth with the MISP instance you want to query.

Set(%ExternalFeeds,
    'MISP' => [
        {   Name        => 'MISP',
            URI         => 'https://mymisp.example.com',
            Description => 'My MISP Feed',
            DaysToFetch => 5,
            ApiKeyAuth  => 'API SECRET KEY',
        },
    ],
);

=cut
