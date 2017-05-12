package Plack::Middleware::NewRelic;
$Plack::Middleware::NewRelic::VERSION = '0.0502';
use parent qw(Plack::Middleware);
use Moo;

use 5.010;
use CHI;
use Method::Signatures;
use NewRelic::Agent;
use Plack::Request;
use Plack::Util;

# ABSTRACT: Plack middleware for NewRelic APM instrumentation

has license_key => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_license_key',
);

has app_name => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_app_name',
);

has cache => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_cache',
);

has agent => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_agent',
);

has path_rules => (
    is      => 'ro',
    default => sub { {} },
);

method _build_license_key {
    my $license_key = $ENV{NEWRELIC_LICENSE_KEY};
    die 'Missing NewRelic license key' unless $self->license_key;
    return $license_key;
}

method _build_app_name {
    my $app_name = $ENV{NEWRELIC_APP_NAME};
    die 'Missing NewRelic app name' unless $app_name;
    return $app_name;
}

method _build_cache {
    return CHI->new(
        driver => 'RawMemory',
        global => 1,
    );
}

method _build_agent {
    return $self->cache->compute('agent', '5min', sub {
        my $agent = NewRelic::Agent->new(
            license_key => $self->license_key,
            app_name    => $self->app_name,
        );
        $agent->embed_collector;
        $agent->init;
        return $agent;
    });
}

method call(HashRef $env) {
    $self->begin_transaction($env)
        if $self->agent;

    my $res = $self->app->($env);
 
    if (ref($res) and 'ARRAY' eq ref($res)) {
        $self->end_transaction($env);
        return $res;
    }
 
    Plack::Util::response_cb(
        $res,
        func($res) {
            func($chunk) {
                if (!defined $chunk) {
                    $self->end_transaction($env);
                    return;
                }
                return $chunk;
            }
        }
    );
}

method transform_path(Str $path) {
    while (my ($pattern, $replacement) = each $self->path_rules) {
        next unless $pattern && $replacement;
        $path =~ s/$pattern/$replacement/ee;
    }
    return $path;
}

method begin_transaction(HashRef $env) {
    # Begin the transaction
    my $txn_id = $self->agent->begin_transaction;
    return unless $txn_id >= 0;
    my $req = Plack::Request->new($env);
    $env->{TRANSACTION_ID} = $txn_id;

    # Populate transaction data
    $self->agent->set_transaction_request_url($txn_id, $req->request_uri);
    my $method = $req->method;
    my $path   = $self->transform_path($req->path);
    my $name   = "$method $path";
    $self->agent->set_transaction_name($txn_id, $name);
    for my $key (qw/Accept Accept-Language User-Agent/) {
        my $value = $req->header($key);
        $self->agent->add_transaction_attribute($txn_id, $key, $value)
            if $value;
    }
}

method end_transaction(HashRef $env) {
    if (my $txn_id = $env->{TRANSACTION_ID}) {
        $self->agent->end_transaction($txn_id);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::NewRelic - Plack middleware for NewRelic APM instrumentation

=head1 VERSION

version 0.0502

=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::Middleware::NewRelic;
    my $app = sub { ... } # as usual
    # NewRelic Options
    my %options = (
        license_key => 'asdf1234',
        app_name    => 'REST API',
    );
    builder {
        enable "Plack::Middleware::NewRelic", %options;
        $app;
    };

=head1 DESCRIPTION

With the above in place, L<Plack::Middleware::NewRelic> will instrument your
Plack application and send information to NewRelic, using the L<NewRelic::Agent>
module.

=for markdown [![Build Status](https://travis-ci.org/aanari/Plack-Middleware-NewRelic.svg?branch=master)](https://travis-ci.org/aanari/Plack-Middleware-NewRelic)

B<Parameters>

=over 4

=item - C<license_key>

A valid NewRelic license key for your account.

This value is also automatically sourced from the C<NEWRELIC_LICENSE_KEY> environment variable.

=item - C<app_name>

The name of your application.

This value is also automatically sourced from the C<NEWRELIC_APP_NAME> environment variable.

=item - C<path_rules>

A HashRef containing path replacement rules, containing case-insensitive regex patterns as string keys, and evaluatable strings as replacement values.

Regex capturing groups work as intended, so you can specify something like this in your ruleset:

    # Replaces '/pages/new/asdf' with '/pages/new'
    '(\/pages\/new)\/\S+' => '$1'

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/aanari/Plack-Middleware-NewRelic/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Ali Anari <ali@anari.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ali Anari.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
