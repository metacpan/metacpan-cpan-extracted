[![Build Status](https://travis-ci.org/cafe01/Net-Moip-V2.svg?branch=master)](https://travis-ci.org/cafe01/Net-Moip-V2) [![Coverage Status](https://img.shields.io/coveralls/cafe01/Net-Moip-V2/master.svg?style=flat)](https://coveralls.io/r/cafe01/Net-Moip-V2?branch=master)
# NAME

Net::Moip::V2 - Perl SDK for the Moip (Money over IP) v2 API.

# SYNOPSIS

    use Net::Moip::V2;

    my $moip = Net::Moip::V2->new(
        token => '...',          # required
        key => '...',            # required
        client_id => '...',      # OAuth app id
        client_secret => '...',  # OAuth app secret
        access_token => '...',   # OAuth access token
    );

    # Working with the 'orders' endpoint
    my $ep_orders = $moip->endpoint('orders');

    # List orders: GET /orders
    my $response = $ep_orders->get;

    # Create new order: POST /orders
    my $new_order = $ep_orders->post(\%params);

    # Fetch order
    my $order = $ep_orders->get($new_order->{id});

    # Get order payments endpoint
    # GET /orders/<order id>/payments
    $response = $moip->endpoint("orders/$order->{id}/payments")->get;

# DESCRIPTION

Net::Moip::V2 is a SDK for Moip (Money Over IP) V2 API. This version of the
module provides only a thin wrapper for the REST API, so you won't find methods
like `create_order()` or `get_orders()`. What this module will do is help you
build the endpoint paths, represented by [Net::Moip::V2::Endpoint](https://metacpan.org/pod/Net::Moip::V2::Endpoint) objects and send
http requests, with authentication handled for you.

Higher level methods exists for requesting OAuth authorization and access token.
See ["build\_authorization\_url"](#build_authorization_url) and ["request\_access\_token"](#request_access_token)

Future versions can include a 'Client' class implementing a higher level of
abstraction like the methdos cited above. Pull requests are welcome! :)

For now, this 'wrapper' approach not only does the job, but also avoids me to
invent another API and you to learn it. All you have to do is follow the
[official documentation](https://dev.moip.com.br/v2.0/reference), build the
equivalent endpoint objects, and send your requests.

# METHDOS

## build\_authorization\_url($redirect\_uri, \\@scope) :Str $url

Builds the URL used to connect the user account to your Moip (OAuth) app. Usually
used in a web app controller to redirect the user's browser to the authorization
page.

`$redirect_uri` is the URL the user will be redirected back to you app after
authorization.

`\@scope` is the list of permssions you are asking authorization for.
See [https://dev.moip.com.br/v2.0/reference#oauth-moip-connect](https://dev.moip.com.br/v2.0/reference#oauth-moip-connect) for the list of
valid permissions.

    # example of a Mojolicious controller redirecting the browser
    # to the "moip connect" page, where the user authorizes or declines the
    # permissions you requested
    sub moip_connect {
        my $c = shift;

        my $moip = Net::Moip::V2->new( ... );
        my $callback_url = $c->url_for('moip-callback'); #
        my $url = $moip->build_authorization_url(
            'http://myapp.com/moip-callback',
            ['RECEIVE_FUNDS', 'REFUND']
        );

        $c->redirect_to($url);
    }

## request\_access\_token($redirect\_uri, $code) :Hashref $response

After the user has allowed the permissions you requested via the authorization url,
his browser will be redirected back to your app, with the url parameter `code`
containing the code you need to request the actual access token that you keep
for future requests on behalf of your user.

    # example of Mojolicious controller receiving the code after user
    # has authorized the permissions and connected his account to your app
    sub moip_callback {
        my $c = shift;

        my $moip = Net::Moip::V2->new( ... );
        my $code = $c->req->param('code');
        my $response = $moip->request_access_token(
            'http://myapp.com/moip-callback',       # must be the same passed to build_authorization_url()
            $code
        );

        if ($response->{error}) {
            # show error page and return
            ...
            return;
        }

        # all good, $response contains the information you need to associate
        # to the user account in you app: access token, moip account id,
        # refresh token and token expiration date
        ...
    }

## endpoint($path)

Returns a new endpoint object for sending requests to $path.

    my $orders_ep = $moip->endpoint('orders');
    my $single_order_payments_ep = $moip->endpoint("orders/ORD-123456789012/payments");

See [Net::Moip::V2::Endpoint](https://metacpan.org/pod/Net::Moip::V2::Endpoint).

## get($endpoint \[, @args\])

Shortcut for `$moip->endpoint('foo')->get(@args)`.

## post($endpoint \[, @args\])

Shortcut for `$moip->endpoint('foo')->post(@args)`.

# ACKNOWLEDGMENTS

The development of this software is supported by the brazilian startup
[Zoom Dentistas](http://www.zoomdentistas.com.br).

# LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Carlos Fernando Avila Gratz <cafe@kreato.com.br>
