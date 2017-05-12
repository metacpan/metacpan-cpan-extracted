use strict; use warnings;
package Plack::Middleware::ProxyMap;
our $VERSION = '0.20';

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(proxymap);
use Plack::App::Proxy ();

use Carp ();

# use XXX -with => 'YAML::XS';

sub call {
    my ($self, $env) = @_;
    my $proxymap = $self->proxymap;
    for my $entry (@$proxymap) {
        my (
            $prefix,
            $remote,
            $preserve_host_header,
            $env_override,
            $debug,
            $backend,
        ) = @{$entry}{qw(
            prefix
            remote
            preserve_host_header
            env
            debug
            backend
        )};
        Carp::croak("'prefix' or 'remote' entry missing in ProxyMap entry")
            unless $prefix and $remote;
        $preserve_host_header ||= 0;
        $env_override ||= {
            PATH_INFO => '',
            QUERY_STRING => '',
            HTTP_COOKIE => '',
        };
        $backend ||= 'AnyEvent::HTTP'; # Plack::App::Proxy's default
        my $request = $env->{REQUEST_URI};
        if ($request =~ s/^\Q$prefix\E//) {
            my $url = "$remote$request";
            warn "Plack::Middleware::Proxymap proxying " .
                "$env->{REQUEST_URI} to $url"
                    if $debug;
            return Plack::App::Proxy->new(
                remote => $url,
                preserve_host_header => $preserve_host_header,
                backend => $backend,
            )->(+{%$env, %$env_override});
        }
    }
    return $self->app->($env);
}

1;
