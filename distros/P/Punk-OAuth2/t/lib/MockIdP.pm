package MockIdP;

# A Punk application acting as the identity provider for the client
# tests: authorize, token, jwks, discovery, userinfo, and the GitHub
# user API shape - with misbehavior injection via %MockIdP::MODE.
#
# Modes: bad_iss, wrong_nonce, tamper_sig, no_id_token, expired_code,
# wrong_state, iss_param_wrong, non_json_token, refuse_token.

use 5.024;
use strict;
use warnings;
use Crypt::JWS qw(sign b64url b64url_decode sha256 ct_eq random_bytes);
use Crypt::JWS::Key ();
use File::Raw::JSON ();
use MIME::Base64 ();

our %MODE;
our %CODES;
our %TOKENS;
our $ISSUER = 'http://127.0.0.1';
our $KEY    = Crypt::JWS::Key->generate('ES256');
our $KID    = $KEY->thumbprint;
our ($CLIENT_ID, $CLIENT_SECRET) = ('test-client', 'test-secret');

sub reset_state { %MODE = (); %CODES = (); %TOKENS = () }

my $J = \&File::Raw::JSON::file_json_encode;

sub _json {
    my ($data, $status) = @_;
    my $body = $J->($data);
    return [$status // 200,
            ['Content-Type' => 'application/json',
             'Content-Length' => length $body], [$body]];
}

sub _client_auth_ok {
    my ($c, $form) = @_;
    my $auth = $c->req->header('Authorization') // '';
    if ($auth =~ /\ABasic (.+)\z/) {
        my ($id, $secret) = split /:/,
            MIME::Base64::decode_base64($1), 2;
        return $id eq $CLIENT_ID && ct_eq($secret // '', $CLIENT_SECRET);
    }
    return ($form->{client_id} // '') eq $CLIENT_ID
        && ct_eq($form->{client_secret} // '', $CLIENT_SECRET);
}

sub _parse_form {
    my ($c) = @_;
    my %f;
    for my $pair (split /&/, $c->req->body // '') {
        my ($k, $v) = split /=/, $pair, 2;
        for ($k, $v) {
            next unless defined;
            tr/+/ /;
            s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
        }
        $f{$k} = $v;
    }
    return \%f;
}

sub _id_token {
    my (%claims) = @_;
    my $now = time;
    my $token = sign($KEY, $J->({
        iss   => $MODE{bad_iss} ? 'http://evil.example' : $ISSUER,
        aud   => $CLIENT_ID,
        sub   => 'user-1',
        email => 'alice@example.com',
        email_verified => \1,
        name  => 'Alice',
        iat   => $now,
        exp   => $now + 300,
        %claims,
    }), alg => 'ES256', kid => $KID);
    if ($MODE{tamper_sig}) {
        my ($h, $p, $s) = split /\./, $token;
        my $raw = b64url_decode($s);
        substr($raw, 4, 1) = chr(ord(substr $raw, 4, 1) ^ 1);
        $token = "$h.$p." . b64url($raw);
    }
    return $token;
}

package MockIdP::App;
use Punk;

get '/.well-known/openid-configuration' => sub {
    return {
        issuer                 => $MockIdP::ISSUER,
        authorization_endpoint => "$MockIdP::ISSUER/authorize",
        token_endpoint         => "$MockIdP::ISSUER/token",
        jwks_uri               => "$MockIdP::ISSUER/jwks.json",
        userinfo_endpoint      => "$MockIdP::ISSUER/userinfo",
        authorization_response_iss_parameter_supported => \1,
    };
};

get '/jwks.json' => sub {
    return { keys => [ $MockIdP::KEY->to_jwk(kid => $MockIdP::KID) ] };
};

# auto-approving authorize: validates the shape, mints a code bound to
# everything the token endpoint must re-check, 302s back
get '/authorize' => sub {
    my ($c) = @_;
    my $q = $c->req->query;
    return $c->text('missing params', 400)
        unless ($q->{response_type} // '') eq 'code'
            && ($q->{client_id} // '') eq $MockIdP::CLIENT_ID
            && defined $q->{redirect_uri}
            && defined $q->{state}
            && defined $q->{code_challenge}
            && ($q->{code_challenge_method} // '') eq 'S256';
    my $code = Crypt::JWS::b64url(Crypt::JWS::random_bytes(16));
    $MockIdP::CODES{$code} = {
        challenge    => $q->{code_challenge},
        redirect_uri => $q->{redirect_uri},
        nonce        => $q->{nonce},
        expires      => time + ($MockIdP::MODE{expired_code} ? -1 : 60),
    };
    my $state = $MockIdP::MODE{wrong_state}
        ? 'not-the-state' : $q->{state};
    my $iss = $MockIdP::MODE{iss_param_wrong}
        ? 'http://evil.example' : $MockIdP::ISSUER;
    my $sep = $q->{redirect_uri} =~ /\?/ ? '&' : '?';
    return $c->redirect($q->{redirect_uri} . $sep
        . 'code=' . $code
        . '&state=' . Punk::OAuth2::uri_escape($state)
        . '&iss=' . Punk::OAuth2::uri_escape($iss));
};

post '/token' => sub {
    my ($c) = @_;
    return $c->text('not json', 200) if $MockIdP::MODE{non_json_token};
    my $form = MockIdP::_parse_form($c);
    return MockIdP::_json({ error => 'invalid_client' }, 401)
        unless MockIdP::_client_auth_ok($c, $form);
    return MockIdP::_json({ error => 'access_denied' }, 400)
        if $MockIdP::MODE{refuse_token};

    if (($form->{grant_type} // '') eq 'authorization_code') {
        my $rec = delete $MockIdP::CODES{ $form->{code} // '' };
        return MockIdP::_json({ error => 'invalid_grant' }, 400)
            unless $rec && $rec->{expires} > time
                && ($form->{redirect_uri} // '') eq $rec->{redirect_uri}
                && defined $form->{code_verifier}
                && Crypt::JWS::ct_eq(
                       Crypt::JWS::b64url(Crypt::JWS::sha256(
                           $form->{code_verifier})),
                       $rec->{challenge});
        my $access  = 'at-' . Crypt::JWS::b64url(Crypt::JWS::random_bytes(12));
        my $refresh = 'rt-' . Crypt::JWS::b64url(Crypt::JWS::random_bytes(12));
        $MockIdP::TOKENS{$access} = { sub => 'user-1' };
        my $nonce = $MockIdP::MODE{wrong_nonce}
            ? 'not-the-nonce' : $rec->{nonce};
        return MockIdP::_json({
            access_token  => $access,
            token_type    => 'Bearer',
            expires_in    => 3600,
            refresh_token => $refresh,
            scope         => 'openid email profile',
            ($MockIdP::MODE{no_id_token} ? () :
                (id_token => MockIdP::_id_token(
                    defined $nonce ? (nonce => $nonce) : ()))),
        });
    }
    if (($form->{grant_type} // '') eq 'refresh_token') {
        return MockIdP::_json({ error => 'invalid_grant' }, 400)
            unless ($form->{refresh_token} // '') =~ /\Art-/;
        my $access = 'at-' . Crypt::JWS::b64url(Crypt::JWS::random_bytes(12));
        $MockIdP::TOKENS{$access} = { sub => 'user-1' };
        return MockIdP::_json({
            access_token  => $access,
            token_type    => 'Bearer',
            expires_in    => 3600,
            refresh_token => 'rt-'
                . Crypt::JWS::b64url(Crypt::JWS::random_bytes(12)),
        });
    }
    return MockIdP::_json({ error => 'unsupported_grant_type' }, 400);
};

# RFC 7662 introspection: active for tokens we issued (or a test token
# prefixed 'good-'), with an optional scope.
post '/introspect' => sub {
    my ($c) = @_;
    my $form = MockIdP::_parse_form($c);
    return MockIdP::_json({ error => 'invalid_client' }, 401)
        unless MockIdP::_client_auth_ok($c, $form);
    my $token = $form->{token} // '';
    if ($token =~ /\Agood-(.*)\z/) {
        return MockIdP::_json({
            active => \1, sub => 'user-1', client_id => 'test-client',
            scope => ($1 || 'read'), exp => time + 300,
        });
    }
    return MockIdP::_json({ active => \0 });
};

# the GitHub-shaped user API for the non-OIDC preset
get '/user' => sub {
    my ($c) = @_;
    my $auth = $c->req->header('Authorization') // '';
    return $c->text('unauthorized', 401)
        unless $auth =~ /\ABearer (at-\S+)\z/ && $MockIdP::TOKENS{$1};
    return { id => 7, login => 'alice', name => 'Alice',
             avatar_url => 'http://127.0.0.1/a.png' };
};

get '/user/emails' => sub {
    my ($c) = @_;
    my $auth = $c->req->header('Authorization') // '';
    return $c->text('unauthorized', 401)
        unless $auth =~ /\ABearer (at-\S+)\z/ && $MockIdP::TOKENS{$1};
    return [
        { email => 'alt@example.com',   primary => \0, verified => \1 },
        { email => 'alice@example.com', primary => \1, verified => \1 },
    ];
};

package MockIdP;
require Punk::OAuth2::Util;

sub app { MockIdP::App->to_app }

1;
