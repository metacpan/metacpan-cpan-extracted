# NAME

Mojo::UserAgent::Role::Signature - Role for Mojo::UserAgent that automatically
signs request transactions

# SYNOPSIS

    use Mojo::UserAgent;

    my $ua = Mojo::UserAgent->with_roles('+Signature')->new;
    $ua->initialize_signature(SomeService => {%args});
    my $tx = $ua->get('/api/for/some/service');
    say $tx->req->headers->authorization;

# DESCRIPTION

[Mojo::UserAgent::Role::Signature](https://metacpan.org/pod/Mojo%3A%3AUserAgent%3A%3ARole%3A%3ASignature) is a role for the full featured non-blocking
I/O HTTP and WebSocket user agent [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent), that automatically signs
request transactions.

This module modifies the [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent) by wrapping ["around" in Role::Tiny](https://metacpan.org/pod/Role%3A%3ATiny#around)
the ["build\_tx" in Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent#build_tx) method with ["apply\_signature"](#apply_signature) signing the
final built transaction using the object instance set in the ["signature"](#signature)
attribute that is this module adds to the [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent) class.

# ATTRIBUTES

## signature

    $signature = $ua->signature;
    $ua        = $ua->signature(SomeService->new);

If this attribute is not defined, the method modifier provided by this
[role](https://metacpan.org/pod/Role%3A%3ATiny) will have no effect on the transaction being built
by [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent).

## signature\_namespaces

    $namespaces = $ua->signature_namespaces;
    $ua         = $ua->signature_namespaces(['Mojo::UserAgent::Signature']);

Namespaces to load signature from, defaults to `Mojo::UserAgent::Signature`.

    # Add another namespace to load signature from
    push @{$ua->namespaces}, 'MyApp::Signature';

# METHODS

[Mojo::UserAgent::Role::Signature](https://metacpan.org/pod/Mojo%3A%3AUserAgent%3A%3ARole%3A%3ASignature) inherits all methods from [Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) and
implements the following new ones.

## initialize\_signature

    $ua->initialize_signature('some_service');
    $ua->initialize_signature('some_service', foo => 23);
    $ua->initialize_signature('some_service', {foo => 23});
    $ua->initialize_signature('SomeService');
    $ua->initialize_signature('SomeService', foo => 23);
    $ua->initialize_signature('SomeService', {foo => 23});
    $ua->initialize_signature('MyApp::Signature::SomeService');
    $ua->initialize_signature('MyApp::Signature::SomeService', foo => 23);
    $ua->initialize_signature('MyApp::Signature::SomeService', {foo => 23});

Load a signature from the configured namespaces or by full module name and run
init, optional arguments are passed through.

## load\_signature

    my $signature = $ua->load_signature('some_service');
    my $signature = $ua->load_signature('SomeService');
    my $signature = $ua->load_signature('MyApp::Signature::SomeService');

Load a signature from the configured namespaces or by full module name. Will
fallback to [Mojo::UserAgent::Signature::None](https://metacpan.org/pod/Mojo%3A%3AUserAgent%3A%3ASignature%3A%3ANone) if the specified signature
cannot be loaded.

# COPYRIGHT AND LICENSE

Copyright (C) 2020, Stefan Adams.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# SEE ALSO

[https://github.com/stefanadams/mojo-useragent-role-signature](https://github.com/stefanadams/mojo-useragent-role-signature), [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent).
