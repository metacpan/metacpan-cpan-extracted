use Test::Lib;
use Test::Net::SAML2;

use Net::SAML2::Binding::Redirect;
use File::Slurper qw/read_text/;

my $url = <<LOWERCASE;
https://netsaml2-testapp.local/sls-redirect-response?SAMLRequest=fVLLTsMwELzzFVXuTuJHGsdqIyHgUAk40IoDF7R1NhAptaOsI%2fh83FQ9VKL1xa%2bdnd2ZXREc%2bsE8%2by8%2fhTekwTvCxeZxnXyKogJbNZKh5S0rASsmcQkMlJUCJKAEldwt%2fl3vOFLn3ToRaX4tZkM04cZRABdiYC4EyzXLlzsuTVEYrtOcy49r6Eek0DkIM8t3CAOZLHMYjv0IFuIvDEPaewt9Rj2xEZtuRBvi4dTk1bLcWYadXyevT7vt%2fcuz%2bGwBlVSlgFa2rS7bUldYoJCV2mstGiFFxfdKLVWO0uY2l81xh6oU1tp9UVyj%2bz30jszswjqZRmc8UEfGwQHJBGuO7CaqaIbRB299n9Qx02oWbzyhb%2bOACMejTEl9lokCpT%2bda%2fwPpVGyjGsJWsCe8egtg1bw6HQpWDRZKA6y0mCzVXbinOlPU7MNECaq584unh58g4t36Ce8XRvN0WY7WYtEySKrV9ll6vP9ckDruz8%3d&SigAlg=http%3a%2f%2fwww.w3.org%2f2000%2f09%2fxmldsig%23rsa-sha1&Signature=nwYTXUvc0G8PR9AFTwMP%2fgUbZ47Br%2f8vtA2FIZ1KvLRtKYXqOzpB%2fctbya1ew8ZzgBQdYXsRh5hdEoO5C8aLvk2Qg40iiTiJgjytPptFZkT2nYlJmcNqpwN%2bUMDPXoZ62vAkm2DLlbl46cK7%2f32Rqi7nghslgt4uKKKhHDsgyjLheYf5uiVRR2kO%2b%2bYyoVy%2fuGwZXBWHsEOI7U7hSKbfdzO6kBEc%2fCw8BkqYKX%2fuDYu2ytbEOOiN9DtgLsbvmkf0xtcdLbyM7sqdH7hkRZgxrzaMLSbbVEOKaIoEgI%2bBs45%2flLmr8RTdJ0sDt1A1tpvM6zU3xPGcH%2fgXJ7UZx%2flENA%3d%3d
LOWERCASE

my $redirect = Net::SAML2::Binding::Redirect->new(
    key     => 't/net-saml2-key.pem',
    url     => 'https://netsaml2-testapp.local/sls-redirect-response',
    param   => 'SAMLRequest',
    cert    => read_text('t/net-saml2-cert.pem'),
    sig_hash => 'sha256',
);

my ($request, $relaystate) = $redirect->verify($url);

like($request, qr/NETSAML/,
    "Good Signature because we now don't alter the input with URI anymore");

done_testing();
