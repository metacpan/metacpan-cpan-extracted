use lib 't/lib';
use Test::Monitis tests => 3, live => 1;

note 'Action cloudInstances (cloud_instances->get)';

my $response = api->cloud_instances->get;

isa_ok $response, 'HASH', 'JSON response ok';

note 'Action cloudInstanceInfo (cloud_instances->get_info)';

SKIP: {
    my ($type, $id);
    foreach (keys %$response) {
        if (@{$response->{$_}}) {
            $type = $_;
            $id   = $response->{$_}->[0]->{id};
            last;
        }
    }

    skip "At least one instance required for this tests", 2,
      unless $id;

    $response =
      api->cloud_instances->get_info(type => $type, instanceId => $id);

    isa_ok $response, 'HASH', 'JSON response ok';
    is $response->{id}, $id;
}
