use Test2::V0;
use Net::Silverpeak::Orchestrator;

skip_all "environment variables not set"
    unless (exists $ENV{NET_SILVERPEAK_ORCHESTRATOR_HOSTNAME}
        && exists $ENV{NET_SILVERPEAK_ORCHESTRATOR_API_KEY});

my $orchestrator = Net::Silverpeak::Orchestrator->new(
    server      => 'https://' . $ENV{NET_SILVERPEAK_ORCHESTRATOR_HOSTNAME},
    api_key     => $ENV{NET_SILVERPEAK_ORCHESTRATOR_API_KEY},
    clientattrs => { timeout => 30 },
);

like($orchestrator->get_version, qr/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/,
    'get_version ok');

like(
    dies { $orchestrator->login },
    qr/user and password required/,
    'login throws exception'
);

like(
    dies { $orchestrator->logout },
    qr/user and password required/,
    'logout throws exception'
    );

done_testing();
