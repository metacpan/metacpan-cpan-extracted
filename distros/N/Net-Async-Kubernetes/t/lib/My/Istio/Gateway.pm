package My::Istio::Gateway;
# Stand-in for Istio's Gateway (networking.istio.io). Shares its Kind name with
# the Gateway API's Gateway (My::GatewayApi::Gateway) - two resources, one
# Kind name. Used by t/27-mock-ensure-group-kind.t (karr k45).

use IO::K8s::APIObject
    api_version     => 'networking.istio.io/v1',
    resource_plural => 'gateways';

with 'IO::K8s::Role::Namespaced';

k8s spec => { Str => 1 };

1;
