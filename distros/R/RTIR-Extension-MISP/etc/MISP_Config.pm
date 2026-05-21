=pod

Replace the URI/ApiKeyAuth with details for your MISP instance.

=cut

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

Set(%CustomFieldGroupings,
    'RT::Ticket' => {
        'Incidents' => {
            'MISP' => ['MISP Event ID', 'MISP Event UUID', 'MISP RTIR Object ID'],
        },
    },
);
