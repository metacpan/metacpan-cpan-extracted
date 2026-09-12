# NAME

PayProp::API::Public::Client - (DEPRECATED) PayProp API client.

# SYNOPSIS

## APIkey

        use PayProp::API::Public::Client;
        use PayProp::API::Public::Client::Authorization::APIKey;

        my $Client = PayProp::API::Public::Client->new(
                scheme => 'https',
                domain => 'https://staging-api.payprop.com', # relevant PayProp API domain

                authorization => PayProp::API::Public::Client::Authorization::APIKey->new(
                        token => 'API_KEY_HERE'
                ),
        );

        # export beneficiaries example
        my $export = $Client->export;
        my $beneficiaries_export = $export->beneficiaries;

        $beneficiaries_export
                ->list_p
                ->then( sub {
                        my ( \@beneficiaries ) = @_;
                        ...;
                } )
                ->wait
        ;

## OAuth v2.0 Client (access token)

        use PayProp::API::Public::Client;
        use PayProp::API::Public::Client::Authorization::ClientCredentials;
        use PayProp::API::Public::Client::Authorization::Storage::Memcached;

        my $Client = PayProp::API::Public::Client->new(
                scheme => 'https',
                domain => 'API_DOMAIN.com',                                                        # relevant PayProp API domain

                authorization => PayProp::API::Public::Client::Authorization::ClientCredentials->new(
                        scheme => 'https',
                        domain => 'API_DOMAIN.com',                                                     # use relevant PayProp API domain

                        client => 'YourPayPropClientID',
                        secret => 'your-payprop-oauth2-client-id-secret',
                        application_user_id => '123',

                        storage => PayProp::API::Public::Client::Authorization::Storage::Memcached->new(
                                servers => [ qw/ memcached:11211 / ],                                       # Required: List of memcached servers.
                                encryption_secret => 'your-optional-encryption-key',
                                throw_on_storage_unavailable => 1,
                        ),
                ),
        );

        # export beneficiaries example
        my $Export = $Client->export;
        my $beneficiaries_export = $Export->beneficiaries;

        $beneficiaries_export
                ->list_p
                ->then( sub {
                        my ( \@beneficiaries ) = @_;
                        ...;
                } )
                ->wait
        ;

# DESCRIPTION

**This module is deprecated.** A new version of the PayProp API is in development that will break the
authentication flow this module currently relies on. Development on this module has halted, as it is no
longer used internally and there is no further incentive to extend its functionality. Aside from a fix
already applied for a TLS certificate verification CVE, no further work is planned. Do not use it in new code.

The PayProp API Public Module is a standalone module that will allow you to interact with the PayProp API,
through a normalised interface. This interface abstracts authentication methods, request and response building and more.

This module **should** be used to access various API requests as defined in `PayProp::API::Public::Client::Request::*`.

# ATTRIBUTES

`PayProp::API::Public::Client` implements the following attributes.

## export

        my $Export = $Client->export;
        my $beneficiaries_export = $Export->beneficiaries;

See [PayProp::API::Public::Client::Request::Export](https://metacpan.org/pod/PayProp%3A%3AAPI%3A%3APublic%3A%3AClient%3A%3ARequest%3A%3AExport) for available attributes.

## entity

        my $Entity = $Client->entity;
        my $payment_entity = $Entity->payment;

See [PayProp::API::Public::Client::Request::Entity](https://metacpan.org/pod/PayProp%3A%3AAPI%3A%3APublic%3A%3AClient%3A%3ARequest%3A%3AEntity) for available attributes.

## tags

        my $Tags = $Client->tags;
        my $Promise = $Entity->list_p;

See [PayProp::API::Public::Client::Request::Tags](https://metacpan.org/pod/PayProp%3A%3AAPI%3A%3APublic%3A%3AClient%3A%3ARequest%3A%3ATags) for available methods.

# AUTHOR

Yanga Kandeni <yangak@cpan.org>

Valters Skrupskis <malishew@cpan.org>

# COPYRIGHT

Copyright 2023- PayProp

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

[https://github.com/Humanstate/api-client-public-module](https://github.com/Humanstate/api-client-public-module)
