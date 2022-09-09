
package Net::Simplify::Jws;

=head1 NAME

Net::Simplify::Jws - Simplify Commerce module for JWS encoding and decoding.

=head1 SEE ALSO

L<Net::Simplify>, L<http://www.simplify.com>

=head1 VERSION

1.6.0

=head1 LICENSE

Copyright (c) 2013 - 2022 MasterCard International Incorporated
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of 
conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of 
conditions and the following disclaimer in the documentation and/or other materials 
provided with the distribution.
Neither the name of the MasterCard International Incorporated nor the names of its 
contributors may be used to endorse or promote products derived from this software 
without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING 
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

=cut

use 5.006;
use strict;
use warnings FATAL => 'all';

use Time::HiRes qw(gettimeofday);
use Math::Random::Secure qw(irand);
use JSON;
use MIME::Base64 qw(decode_base64 decode_base64url encode_base64url);
use Crypt::Mac::HMAC qw( hmac_b64u  );
use Carp;

our $JWS_NUM_HEADERS        = 7;
our $JWS_ALGORITHM          = 'HS256';
our $JWS_TYPE               = 'JWS';
our $JWS_HDR_UNAME          = 'uname';
our $JWS_HDR_URI            = 'api.simplifycommerce.com/uri';
our $JWS_HDR_TIMESTAMP      = 'api.simplifycommerce.com/timestamp';
our $JWS_HDR_NONCE          = 'api.simplifycommerce.com/nonce';
our $JWS_HDR_TOKEN          = 'api.simplifycommerce.com/token';
our $JWS_TIMESTAMP_MAX_DIFF = 1000 * 60 * 5;   # 5 minutes


sub encode {
    my ($class, $url, $payload, $auth) = @_;

    my $header = {
        'typ' => $JWS_TYPE,
        'alg' => $JWS_ALGORITHM,
        'kid' => $auth->public_key,
        $JWS_HDR_URI => $url,
        $JWS_HDR_TIMESTAMP => int(_now()),
        $JWS_HDR_NONCE => irand()
    };

    my $token = $auth->access_token;
    if (defined $token) {
        $$header{$JWS_HDR_TOKEN} = $token;
    }

    my $p1 = encode_base64url(encode_json $header);

    my $p2 = "";
    $p2 = encode_base64url($payload) if defined $payload;

    my $msg = "${p1}.${p2}";
    my $sig = _sign($msg, $auth->private_key);

    "${msg}.${sig}";
}

sub decode {
    my ($class, $message, $url, $auth) = @_;
 
    # Remove whitespace
    $message =~ s/\s*//g; 
    my @parts = split(/\./, $message);
    my $num_parts = @parts;
    
    if ($num_parts != 3) {
        croak(Net::Simplify::IllegalArgumentException->new("Invalid JWS message"));
    }

    my $header = decode_json(decode_base64url($parts[0]));

    _verify_header($header, $url, $auth->public_key);

    if (!_verify_sig($auth->private_key, @parts)) {
        croak(Net::Simplify::AuthenticationException->new("JWS signature does not match"));
    }

    decode_json(decode_base64url($parts[1]));
}


sub _verify_header {
    my ($header, $url, $public_key) = @_;

    my $n = keys %{$header};
    if ($n != $JWS_NUM_HEADERS) {
        _auth_error("Incorrect number of JWS header parameters - found ${n} required ${JWS_NUM_HEADERS}");
    }

    my $value = $header->{alg};
    if ($value ne $JWS_ALGORITHM) {
        _auth_error("Incorrect algorithm - found ${value} required ${JWS_ALGORITHM}");
    }

    $value = $header->{typ};
    if ($value ne $JWS_TYPE) {
        _auth_error("Incorrect type - found ${value} required ${JWS_TYPE}");
    }

    $value = $header->{kid};
    if (!defined $value) {
        _auth_error("Missing Key ID");
    }
    
    if ($value ne $public_key) {
        if (Net::Simplify::SimplifyApi->is_live_key($public_key)) {
            _auth_error("Invalid Key ID");
        }
    }

    $value = $header->{$JWS_HDR_URI};
    if (!defined $value) {
        _auth_error("Missing URI");
    }
    
    if (defined $url && $url ne $value) {
        _auth_error("Incorrect URL - found ${value} required ${url}");
    }

    $value = $header->{$JWS_HDR_TIMESTAMP};
    if (!defined $value) {
        _auth_error("Missing timestamp");
    }
    
    if (!_verify_timestamp($value)) {
        _auth_error("Invalid timestamp");
    }

    $value = $header->{$JWS_HDR_NONCE};
    if (!defined $value) {
        _auth_error("Missing nonce");
    }
    
    $value = $header->{$JWS_HDR_UNAME};
    if (!defined $value) {
        _auth_error("Missing username header");
    }
}

sub _sign {
    my ($msg, $private_key) = @_;

    my $key = decode_base64($private_key);

    hmac_b64u('SHA256', $key, $msg);
}

sub _verify_sig {
    my ($private_key, @parts) = @_;

    $parts[2] eq _sign($parts[0] . '.' . $parts[1], $private_key);
}

sub _verify_timestamp {
    my ($timestamp) = @_;
    
    abs($timestamp - _now()) < $JWS_TIMESTAMP_MAX_DIFF;
}
    
sub _now {
    gettimeofday() * 1000
}

sub _auth_error {
    my ($msg) = @_;

    croak(Net::Simplify::AuthenticationException->new($msg));
}
