[![Actions Status](https://github.com/hkoba/perl-Plack-Middleware-Validate_Google_IAP_JWT/actions/workflows/test.yml/badge.svg)](https://github.com/hkoba/perl-Plack-Middleware-Validate_Google_IAP_JWT/actions)
# NAME

Plack::Middleware::Validate\_Google\_IAP\_JWT - Validate JWT from Google IAP

# SYNOPSIS

    use Plack::Builder;

    my $app = sub {
      my $env = shift;
      return [200, [], ["Validated email: ", $env->{"psgix.goog_iap_jwt_email"}]]
    };

    builder {
      enable "Validate_Google_IAP_JWT", want_hd => "example.com"
        , guest_subpath => "/guest/";
      $app;
    };

# DESCRIPTION

Plack::Middleware::Validate\_Google\_IAP\_JWT is a Plack middleware that validates JWT from
[Google Cloud Identity-Aware Proxy(IAP)](https://cloud.google.com/security/products/iap). 
Although Cloud IAP rejects unauthorized access from public networks, 
internal processes on the same network can still spoof the identity.
To protect against such security risks, Cloud IAP provides a special HTTP header, ['x-goog-iap-jwt-assertion'](https://cloud.google.com/iap/docs/signed-headers-howto),
which carries JWT containing the email address of the authenticated end user.
 This middleware protects Plack apps by validating the JWT.

# CONFIGURATION

## want\_hd

Expected hosted domain. See [https://cloud.google.com/iap/docs/signed-headers-howto#verifying\_the\_jwt\_payload](https://cloud.google.com/iap/docs/signed-headers-howto#verifying_the_jwt_payload).

## guest\_subpath

If set, allows guest access for this subpath.

# METHODS

## fetch\_iap\_public\_key

Fetch [https://www.gstatic.com/iap/verify/public\_key-jwk](https://www.gstatic.com/iap/verify/public_key-jwk) and returns decoded json.

# LICENSE

Copyright (C) Kobayasi, Hiroaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kobayasi, Hiroaki <buribullet@gmail.com>
