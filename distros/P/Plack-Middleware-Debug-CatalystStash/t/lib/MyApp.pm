package MyApp;
use Moose;

use Catalyst;

__PACKAGE__->config(
    'psgi_middleware', [
        'Debug' => {panels => [qw/CatalystStash/]},
    ],
);

__PACKAGE__->setup;
