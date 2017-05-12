package Test::App;

use Moose;

use lib qw(lib);

has config => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_config_builder',
);

with 'MooseX::Fastly::Role';

sub _config_builder {
    if ( $ENV{FASTLY_API_KEY} ) {
        return {
            fastly_api_key    => $ENV{FASTLY_API_KEY},
            fastly_service_id => $ENV{FASTLY_SERVICE_ID},
        };
    } else {
        return {};
    }
}

