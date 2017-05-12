use Plack::Builder;

use lib '../lib';

use RPC::ExtDirect::Config;

# This will work with Perl > 5.12
use RPC::ExtDirect::Demo::Profile;
use RPC::ExtDirect::Demo::TestAction;
use RPC::ExtDirect::Demo::PollProvider;

builder {
    enable 'Static',    path => qr{(gif|jpg|png|js|css|html)$},
                        root => './htdocs/';

    # The examples were taken from Ext JS distribution and have
    # PHP script names hardcoded in HTML. Instead of fixing the
    # URIs, we just pretend we're running PHP here. Huh huh.
    my $config = RPC::ExtDirect::Config->new(
        api_path           => 'php/api.php',
        router_path        => 'php/router.php',
        poll_path          => 'php/poll.php',
        verbose_exceptions => 1,
    );

    enable 'ExtDirect', config => $config;

    sub {[ 301,
         [
            'Content-Type' => 'text/plain',
            'Location'     => 'http://localhost:5000/index.html',
         ],
         [ 'Moved permanently' ]
         ]};
}

