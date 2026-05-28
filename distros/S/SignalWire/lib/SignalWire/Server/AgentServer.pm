package SignalWire::Server::AgentServer;
# Copyright (c) 2025 SignalWire
# Licensed under the MIT License.

use strict;
use warnings;
use Moo;
use JSON qw(encode_json decode_json);
use Carp qw(croak);
use File::Spec;

has host      => (is => 'rw', default => sub { '0.0.0.0' });
has port      => (is => 'rw', default => sub { $ENV{PORT} || 3000 });
has log_level => (is => 'rw', default => sub { 'info' });
has agents    => (is => 'rw', default => sub { {} });

# SIP routing
has _sip_routing_enabled  => (is => 'rw', default => sub { 0 });
has _sip_username_mapping => (is => 'rw', default => sub { {} });

# Static file routes: { route => directory }
has _static_routes => (is => 'rw', default => sub { {} });

sub register {
    my ($self, $agent, $route) = @_;

    $route //= $agent->route;
    $route = "/$route" unless $route =~ m{^/};
    $route =~ s{/+$}{} unless $route eq '/';

    if (exists $self->agents->{$route}) {
        croak("Route '$route' is already registered");
    }

    $agent->route($route);
    $self->agents->{$route} = $agent;
    return $self;
}

sub unregister {
    my ($self, $route) = @_;
    $route = "/$route" unless $route =~ m{^/};
    $route =~ s{/+$}{} unless $route eq '/';
    delete $self->agents->{$route};
    return $self;
}

sub list_agents {
    my ($self) = @_;
    return [ sort keys %{ $self->agents } ];
}

sub get_agent {
    my ($self, $route) = @_;
    return $self->agents->{$route};
}

sub serve_static_files {
    my ($self, $directory, $route) = @_;

    croak("serve_static_files requires a directory") unless defined $directory;
    croak("serve_static_files requires a route")     unless defined $route;
    croak("Static directory '$directory' does not exist") unless -d $directory;

    $route = "/$route" unless $route =~ m{^/};
    $route =~ s{/+$}{} unless $route eq '/';

    # Resolve the directory to an absolute path for security
    $self->_static_routes->{$route} = File::Spec->rel2abs($directory);
    return $self;
}

sub psgi_app {
    my ($self) = @_;
    return $self->_build_psgi_app;
}

sub _build_psgi_app {
    my ($self) = @_;
    require Plack::Request;

    my $server = $self;

    # MIME type mapping for static files
    my %mime_types = (
        html => 'text/html',
        htm  => 'text/html',
        css  => 'text/css',
        js   => 'application/javascript',
        json => 'application/json',
        png  => 'image/png',
        jpg  => 'image/jpeg',
        jpeg => 'image/jpeg',
        gif  => 'image/gif',
        svg  => 'image/svg+xml',
        ico  => 'image/x-icon',
        txt  => 'text/plain',
        pdf  => 'application/pdf',
        xml  => 'application/xml',
        woff => 'font/woff',
        woff2 => 'font/woff2',
        ttf  => 'font/ttf',
        eot  => 'application/vnd.ms-fontobject',
    );

    # Build a plain PSGI app with route dispatch
    my $core_app = sub {
        my $env = shift;
        my $path = $env->{PATH_INFO} // '/';
        $path =~ s{/+$}{} unless $path eq '/';

        # Health/ready (no auth)
        if ($path eq '/health') {
            my @agent_names = map { $server->agents->{$_}->name }
                              sort keys %{ $server->agents };
            return [200, ['Content-Type' => 'application/json'],
                [encode_json({ status => 'healthy', agents => \@agent_names })]];
        }
        if ($path eq '/ready') {
            return [200, ['Content-Type' => 'application/json'],
                [encode_json({ status => 'ready' })]];
        }

        # Check static file routes (longest prefix match)
        for my $static_route (sort { length($b) <=> length($a) } keys %{ $server->_static_routes }) {
            my $prefix = $static_route eq '/' ? '' : $static_route;
            if ($path eq $static_route || index($path, "$prefix/") == 0 || ($static_route eq '/' && $path =~ m{^/})) {
                next if $static_route eq '/' && $path eq '/';
                my $rel_path = substr($path, length($prefix));
                $rel_path =~ s{^/}{};

                # Path traversal protection: reject ".." components
                if ($rel_path =~ m{(?:^|/)\.\.(?:/|$)}) {
                    return [403, [
                        'Content-Type'            => 'text/plain',
                        'X-Content-Type-Options'  => 'nosniff',
                        'X-Frame-Options'         => 'DENY',
                        'Cache-Control'           => 'no-store',
                    ], ['Forbidden']];
                }

                my $base_dir = $server->_static_routes->{$static_route};
                my $file_path = File::Spec->catfile($base_dir, split(m{/}, $rel_path));

                # Resolve to absolute and verify it's within the base directory
                my $abs_path = File::Spec->rel2abs($file_path);
                unless (index($abs_path, $base_dir) == 0) {
                    return [403, [
                        'Content-Type'            => 'text/plain',
                        'X-Content-Type-Options'  => 'nosniff',
                        'X-Frame-Options'         => 'DENY',
                        'Cache-Control'           => 'no-store',
                    ], ['Forbidden']];
                }

                if (-f $abs_path && -r $abs_path) {
                    # Determine MIME type from extension
                    my ($ext) = ($abs_path =~ /\.(\w+)$/);
                    $ext = lc($ext // '');
                    my $content_type = $mime_types{$ext} // 'application/octet-stream';

                    open my $fh, '<:raw', $abs_path or
                        return [500, ['Content-Type' => 'text/plain'], ['Internal Server Error']];
                    local $/;
                    my $content = <$fh>;
                    close $fh;

                    return [200, [
                        'Content-Type'            => $content_type,
                        'Content-Length'           => length($content),
                        'X-Content-Type-Options'  => 'nosniff',
                        'X-Frame-Options'         => 'DENY',
                        'Cache-Control'           => 'no-store',
                    ], [$content]];
                }

                # Static route matched but file not found - fall through
            }
        }

        # Find matching agent by longest prefix
        my $matched_route;
        for my $route (sort { length($b) <=> length($a) } keys %{ $server->agents }) {
            if ($route eq '/') {
                $matched_route = $route;
                last;
            }
            if ($path eq $route || index($path, "$route/") == 0) {
                $matched_route = $route;
                last;
            }
        }

        if (defined $matched_route) {
            my $agent     = $server->agents->{$matched_route};
            my $agent_app = $agent->psgi_app;
            return $agent_app->($env);
        }

        return [404, ['Content-Type' => 'application/json'],
            [encode_json({ error => 'Not Found' })]];
    };

    # Wrap with security headers
    return sub {
        my $env = shift;
        my $res = $core_app->($env);
        if (ref $res eq 'ARRAY') {
            push @{ $res->[1] },
                'X-Content-Type-Options' => 'nosniff',
                'X-Frame-Options'        => 'DENY',
                'Cache-Control'          => 'no-store';
        }
        return $res;
    };
}

sub run {
    my ($self, %opts) = @_;
    my $app  = $self->psgi_app;
    my $host = $opts{host} // $self->host;
    my $port = $opts{port} // $self->port;

    require Plack::Runner;
    my $runner = Plack::Runner->new;
    $runner->parse_options(
        '--host'   => $host,
        '--port'   => $port,
        '--server' => 'HTTP::Server::PSGI',
    );
    $runner->run($app);
}

1;
