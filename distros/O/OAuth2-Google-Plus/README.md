## OAuth2::Google::Plus

Perl module that implements the OAuth2 API from google.

## SYNOPSIS

    use OAuth2::Google::Plus;

    my $plus = OAuth2::Google::Plus->new(
        client_id       => 'CLIENT ID',
        client_secret   => 'CLIENT SECRET',
        redirect_uri    => 'http://my.app.com/authorize',
    );

    # generate the link for signup
    my $uri = $plus->authorization_uri( redirect_url => $url_string )

    # callback returns with a code in url
    my $access_token = $plus->authorize( $request->param('code') );

    # store $access_token somewhere safe...

    # use $authorization_token
    my $info = OAuth2::Google::Plus::UserInfo->new( access_token => $access_token );

## INSTALLATION

This is a Dist::Zilla package. run `dzil install` to install this package.
Alternatively, install the dependencies and include this in your codebase somewhere

    $ dzil listdeps | cpanm

## DEMO

You need to create a `client_id` and a `client_secret` in google's api console for a **web application**
on https://code.google.com/apis/console

Allow the `redirect_uri` for http://localhost:5000
Run this simple demo to see the thing in action.

Install required cpan modules for plack:

```bash
    $ cpanm Plack::Builder Plack::Request Plack::Response
```

Run the plack app

```bash
    $ client_id=$CLIENT_ID client_secret=$CLIENT_SECRET plackup bin/demo.pl
```

Point your browser to http://localhost:5000


## TODO

Currently this module only implements the userinfo endpoint.
