package Example::Middleware::ApiKey;
use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Response;
use parent 'PAGI::Middleware';

# A guard middleware: require a matching X-Api-Key header or short-circuit with a
# 401, never reaching the handler. It is configured with a key, so it is
# pre-instantiated and scoped to a route ([ ...->new(key => ...) ]) rather than
# named — route-scoped middleware take no constructor args.

sub _init ($self, $config) { $self->{key} = $config->{key} }

sub wrap ($self, $app) {
    my $want = $self->{key};
    return async sub ($scope, $receive, $send) {
        my $given = _header($scope, 'x-api-key');
        if (!defined $given || $given ne $want) {
            my $res = PAGI::Response->json({ error => 'unauthorized' }, status => 401);
            return await $res->respond($send);     # short-circuit; $app never runs
        }
        await $app->($scope, $receive, $send);
    };
}

# Scan the raw scope headers (an arrayref of [lc-name, value] pairs).
sub _header ($scope, $name) {
    for my $pair (@{ $scope->{headers} // [] }) {
        return $pair->[1] if lc($pair->[0]) eq $name;
    }
    return undef;
}

1;
