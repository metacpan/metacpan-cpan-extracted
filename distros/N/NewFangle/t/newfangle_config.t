use Test2::V0 -no_srand => 1;
use NewFangle;
use YAML qw( Dump );

$ENV{NEWRELIC_LICENSE_KEY} = 'a' x 40;

my $config = NewFangle::Config->new;
isa_ok $config, 'NewFangle::Config';
note Dump($config->to_perl);

like(
    dies {
        local $ENV{NEWRELIC_LICENSE_KEY} = 'a' x 39;
        NewFangle::Config->new;
    },
    qr/Error creating NewFangle::Config, bad license key/,
    'constructor dies when create_app_config returns NULL pointer',
);

done_testing;
