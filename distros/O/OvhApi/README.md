# NAME

OvhApi - Official OVH Perl wrapper upon the OVH RESTful API.

# SYNOPSIS

    use OvhApi;

    my $Api    = OvhApi->new(type => OvhApi::OVH_API_EU, applicationKey => $AK, applicationSecret => $AS, consumerKey => $CK);
    my $Answer = $Api->get(path => '/me');

# DESCRIPTION

This module is an official Perl wrapper that OVH provides in order to offer a simple way to use its RESTful API.
`OvhApi` handles the authentication layer, and uses `LWP::UserAgent` in order to run requests.

Answer are retured as instances of [OvhApi::Answer](https://metacpan.org/pod/OvhApi::Answer).

# CLASS METHODS

## Constructor

There is only one constructor: `new`.

Its parameters are:

    Parameter           Mandatory                               Default                 Usage
    ------------        ------------                            ----------              --------
    type                Carp if missing                         OVH_API_EU()            Determine if you'll use european or canadian OVH API (possible values are OVH_API_EU and OVH_API_CA)
    timeout             No                                      10                      Set the timeout LWP::UserAgent will use
    applicationKey      Yes                                     -                       Your application key
    applicationSecret   Yes                                     -                       Your application secret
    consumerKey         Yes, unless for a credential request    -                       Your consumer key

## OVH\_API\_EU

[Constant](https://metacpan.org/pod/constant) that points to the root URL of OVH european API.

## OVH\_API\_CA

[Constant](https://metacpan.org/pod/constant) that points to the root URL of OVH canadian API.

## setRequestTimeout

This method changes the timeout `LWP::UserAgent` uses. You can set that in [new](#constructor) instead.

Its parameters are:

    Parameter           Mandatory
    ------------        ------------
    timeout             Yes

# INSTANCE METHODS

## rawCall

This is the main method of that wrapper. This method will take care of the signature, of the JSON conversion of your data, and of the effective run of the query.

Its parameters are:

    Parameter           Mandatory                               Default                 Usage
    ------------        ------------                            ----------              --------
    path                Yes                                     -                       The API URL you want to request
    method              Yes                                     -                       The HTTP method of the request (GET, POST, PUT, DELETE)
    body                No                                      ''                      The body to send in the query. Will be ignore on a GET
    noSignature         No                                      false                   If set to a true value, no signature will be send

## get

Helper method that wraps a call to:

    rawCall(method => 'get");

All parameters are forwarded to [rawCall](#rawcall).

## post

Helper method that wraps a call to:

    rawCall(method => 'post');

All parameters are forwarded to [rawCall](#rawcall).

## put

Helper method that wraps a call to:

    rawCall(method => 'put');

All parameters are forwarded to [rawCall](#rawcall).

## delete

Helper method that wraps a call to:

    rawCall(method => 'delete');

All parameters are forwarded to [rawCall](#rawcall).

## requestCredentials

This method will request a Consumer Key to the API. That credential will need to be validated with the link returned in the answer.

Its parameters are:

    Parameter           Mandatory
    ------------        ------------
    accessRules         Yes

The `accessRules` parameter is an ARRAY of HASHes. Each hash contains these keys:

- method: an HTTP method among GET, POST, PUT and DELETE. ALL is a special values that includes all the methods;
- path: a string that represents the URLs the credential will have access to. `*` can be used as a wildcard. `/*` will allow all URLs, for example.

### Example

    my $Api = OvhApi->new(type => OvhApi::OVH_API_EU, applicationKey => $AK, applicationSecret => $AS, consumerKey => $CK);
    my $Answer = $Api->requestCredentials(accessRules => [ { method => 'ALL', path => '/*' }]);

    if ($Answer)
    {
        my ($consumerKey, $validationUrl) = @{ $Answer->content}{qw{ consumerKey validationUrl }};

        # $consumerKey contains the newly created  Consumer Key
        # $validationUrl contains a link to OVH website in order to login an OVH account and link it to the credential
    }

# SEE ALSO

The guts of module are using: `LWP::UserAgent`, `JSON`, `Digest::SHA1`.

# COPYRIGHT

Copyright (c) 2013, OVH SAS.
All rights reserved.

This library is distributed under the terms of `LICENSE`.
