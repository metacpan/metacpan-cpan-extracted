use strict;
use warnings;

use Test::More;
use OIDC::Lite::Model::IDToken;
use OIDC::Lite::Util::JWT;

my $privkeyfile = "t/lib/private_np.pem";
my $privkey;
open(PRIV,$privkeyfile) || die "$privkeyfile: $!";
read(PRIV,$privkey,-s PRIV);
close(PRIV);

my $pubkeyfile = "t/lib/public.pem";
my $pubkey;
open(PUB,$pubkeyfile) || die "$pubkeyfile: $!";
read(PUB,$pubkey,-s PUB);
close(PUB);

TEST_NEW: {

    my $id_token = OIDC::Lite::Model::IDToken->new();
    
    ok($id_token->header);
    ok($id_token->payload);
    is($id_token->key, undef);

    my %header =    (
                        typ =>'JWT',
                        alg => 'none',
                    );
    my %payload =   (
                        foo => 'bar'
                    );
    my $key = q{this_is_shared_secret_key};
    $id_token = OIDC::Lite::Model::IDToken->new(
        header  => \%header,
        payload => \%payload,
        key     => $key,
    );
    is($id_token->header,   \%header);
    is($id_token->payload,  \%payload);
    is($id_token->key,      $key);

    $id_token = OIDC::Lite::Model::IDToken->new({
        header  => \%header,
        payload => \%payload,
        key     => $key,
    });
    is($id_token->header,   \%header);
    is($id_token->payload,  \%payload);
    is($id_token->key,      $key);
};

TEST_GET_TOKEN_STRING: {
    # default
    my %header =    ();
    my %payload =   (
                        foo => 'bar'
                    );
    my $id_token = OIDC::Lite::Model::IDToken->new(
        header  => \%header,
        payload => \%payload,
    );
    my $id_token_string = $id_token->get_token_string();
    my $id_token_header = OIDC::Lite::Util::JWT::header($id_token_string);
    is( $id_token_header->{alg}, q{none});
    is( $id_token_header->{typ}, q{JWT});
    my $id_token_payload = OIDC::Lite::Util::JWT::payload($id_token_string);
    is( $id_token_payload->{foo}, q{bar});

    # alg : none
    %header =    (
                        alg => 'none',
                        typ => 'JWS',
                    );
    %payload =   (
                        foo => 'bar'
                    );
    $id_token = OIDC::Lite::Model::IDToken->new(
        header  => \%header,
        payload => \%payload,
    );
    $id_token_string = $id_token->get_token_string();
    $id_token_header = OIDC::Lite::Util::JWT::header($id_token_string);
    is( $id_token_header->{alg}, q{none});
    is( $id_token_header->{typ}, q{JWS});
    $id_token_payload = OIDC::Lite::Util::JWT::payload($id_token_string);
    is( $id_token_payload->{foo}, q{bar});

    # alg : HS256
    %header =       (
                        alg => 'HS256',
                        typ => 'JWS',
                    );
    %payload =      (
                        foo => 'bar'
                    );
    my $key = q{this_is_shared_secret_key};
    $id_token = OIDC::Lite::Model::IDToken->new(
        header  => \%header,
        payload => \%payload,
        key     => $key,
    );
    $id_token_string = $id_token->get_token_string();
    $id_token_header = OIDC::Lite::Util::JWT::header($id_token_string);
    is( $id_token_header->{alg}, q{HS256});
    is( $id_token_header->{typ}, q{JWS});
    $id_token_payload = OIDC::Lite::Util::JWT::payload($id_token_string);
    is( $id_token_payload->{foo}, q{bar});

    # alg : RS256
    %header =       (
                        alg => 'RS256',
                        typ => 'JWS',
                    );
    %payload =      (
                        foo => 'bar'
                    );
    $id_token = OIDC::Lite::Model::IDToken->new(
        header  => \%header,
        payload => \%payload,
        key     => $privkey,
    );
    $id_token_string = $id_token->get_token_string();
    $id_token_header = OIDC::Lite::Util::JWT::header($id_token_string);
    is( $id_token_header->{alg}, q{RS256});
    is( $id_token_header->{typ}, q{JWS});
    $id_token_payload = OIDC::Lite::Util::JWT::payload($id_token_string);
    is( $id_token_payload->{foo}, q{bar});
};

TEST_HASH: {
    # alg : none
    my %header =    (
                        alg => 'none',
                        typ => 'JWS',
                    );
    my %payload =   (
                        foo => 'bar'
                    );
    my $id_token = OIDC::Lite::Model::IDToken->new(
        header  => \%header,
        payload => \%payload,
    );
    my $access_token = 'access_token_string';
    my $authorization_code = 'authorization_code_string';
    $id_token->access_token_hash($access_token);
    $id_token->code_hash($authorization_code);
    ok( !$id_token->payload->{at_hash} );
    ok( !$id_token->payload->{c_hash} );
    my $id_token_string = $id_token->get_token_string();
    ok( $id_token_string );
    my $id_token_header = OIDC::Lite::Util::JWT::header($id_token_string);
    is( $id_token_header->{alg}, q{none});
    is( $id_token_header->{typ}, q{JWS});
    my $id_token_payload = OIDC::Lite::Util::JWT::payload($id_token_string);
    is( $id_token_payload->{foo}, q{bar});

    $id_token = OIDC::Lite::Model::IDToken->new(
        header  => \%header,
        payload => \%payload,
    );
    $id_token->header->{alg} = undef;
    $id_token->access_token_hash($access_token);
    $id_token->code_hash($authorization_code);
    ok( !$id_token->payload->{at_hash} );
    ok( !$id_token->payload->{c_hash} );

    # alg : HS256
    %header =       (
                        alg => 'HS256',
                        typ => 'JWS',
                    );
    %payload =      (
                        foo => 'bar'
                    );
    my $key = q{this_is_shared_secret_key};
    $id_token = OIDC::Lite::Model::IDToken->new(
        header  => \%header,
        payload => \%payload,
        key     => $key,
    );
    $id_token->access_token_hash($access_token);
    $id_token->code_hash($authorization_code);
    is( $id_token->payload->{foo}, 'bar');
    is( $id_token->payload->{at_hash}, 'JnPXVfC--Wj6h3moc1dyiQ');
    is( $id_token->payload->{c_hash}, 'f0zfwRaKGf53ea5EmauamA');
    $id_token_string = $id_token->get_token_string();
    ok( $id_token_string );
    $id_token_header = OIDC::Lite::Util::JWT::header($id_token_string);
    is( $id_token_header->{alg}, q{HS256});
    is( $id_token_header->{typ}, q{JWS});
    $id_token_payload = OIDC::Lite::Util::JWT::payload($id_token_string);
    is( $id_token_payload->{foo}, q{bar});
};

TEST_LOAD: {
    my $token_string = '';
    my $id_token = OIDC::Lite::Model::IDToken->load($token_string);
    is( $id_token, undef);

    # no header and no payload
    $token_string = 'a.b.';
    $id_token = OIDC::Lite::Model::IDToken->load($token_string);
    is( $id_token, undef);

    # no header
    $token_string = 'a.eyJmb28iOiJiYXIifQ.';
    $id_token = OIDC::Lite::Model::IDToken->load($token_string);
    is( $id_token, undef);

    # no payload
    $token_string = 'eyJhbGciOiJub25lIiwidHlwIjoiSldTIn0.b.';
    $id_token = OIDC::Lite::Model::IDToken->load($token_string);
    is( $id_token, undef);

    $token_string = 'eyJhbGciOiJub25lIiwidHlwIjoiSldTIn0.eyJmb28iOiJiYXIifQ.';
    $id_token = OIDC::Lite::Model::IDToken->load($token_string);
    ok( $id_token );

    my %header =    (
                        alg => 'none',
                        typ =>'JWS',
                    );
    my %payload =   (
                        foo => 'bar'
                    );
    is( %{$id_token->header}, %header);
    is( %{$id_token->payload}, %payload);
};

TEST_VERIFY: {
    my $id_token = OIDC::Lite::Model::IDToken->new;
    ok(!$id_token->verify());

    # alg : none
    my $token_string = 'eyJhbGciOiJub25lIiwidHlwIjoiSldTIn0.eyJmb28iOiJiYXIifQ.';
    $id_token = OIDC::Lite::Model::IDToken->load($token_string);
    ok($id_token->verify());

    $token_string = 'eyJhbGciOiJub25lIiwidHlwIjoiSldTIn0.eyJmb28iOiJiYXIifQ.';
    $id_token = OIDC::Lite::Model::IDToken->load($token_string, '', 'none');
    ok($id_token->verify());

    $token_string = 'eyJhbGciOiJub25lIiwidHlwIjoiSldTIn0.eyJmb28iOiJiYXIifQ.';
    $id_token = OIDC::Lite::Model::IDToken->load($token_string, 'should be ignored', 'none');
    ok($id_token->verify());

    $token_string = 'eyJhbGciOiJub25lIiwidHlwIjoiSldTIn0.eyJmb28iOiJiYXIifQ.';
    $id_token = OIDC::Lite::Model::IDToken->load($token_string, '', 'HS256');
    ok(!$id_token->verify());

    $token_string = 'eyJhbGciOiJub25lIiwidHlwIjoiSldTIn0.eyJmb28iOiJiYXIifQ.INVALID';
    $id_token = OIDC::Lite::Model::IDToken->load($token_string);
    ok(!$id_token->verify());

    # alg : HS256
    $token_string = 'eyJ0eXAiOiJKV1MiLCJhbGciOiJIUzI1NiJ9.eyJmb28iOiJiYXIifQ.Q3cQIgBthdlPPhP5elxuD58iB-Vw2AtxPDPlXng3YaM';
    $id_token = OIDC::Lite::Model::IDToken->load($token_string);
    my $key = q{this_is_shared_secret_key};
    $id_token->key($key);
    ok($id_token->verify());

    $id_token = OIDC::Lite::Model::IDToken->load($token_string, $key);
    ok($id_token->verify());

    $id_token = OIDC::Lite::Model::IDToken->load($token_string, $key, 'HS256');
    ok($id_token->verify());

    $id_token = OIDC::Lite::Model::IDToken->load($token_string, '', 'HS256');
    ok(!$id_token->verify());

    $id_token = OIDC::Lite::Model::IDToken->load($token_string, $key, 'HS384');
    ok(!$id_token->verify());

    $key = q{this_is_invalid_shared_secret_key};
    $id_token = OIDC::Lite::Model::IDToken->load($token_string);
    $id_token->key($key);
    ok(!$id_token->verify());

    $id_token = OIDC::Lite::Model::IDToken->load($token_string, $key);
    ok(!$id_token->verify());

    $id_token = OIDC::Lite::Model::IDToken->load($token_string, $key, 'HS256');
    ok(!$id_token->verify());

    $token_string = 'eyJ0eXAiOiJKV1MiLCJhbGciOiJIUzI1NiJ9.eyJmb28iOiJiYXIifQ.INVALIDSIGNATURE';
    $key = q{this_is_shared_secret_key};
    $id_token = OIDC::Lite::Model::IDToken->load($token_string);
    $id_token->key($key);
    ok(!$id_token->verify());

    $id_token = OIDC::Lite::Model::IDToken->load($token_string, $key);
    ok(!$id_token->verify());

    $id_token = OIDC::Lite::Model::IDToken->load($token_string, $key, 'HS256');
    ok(!$id_token->verify());

    # alg : RS256
    $token_string = 'eyJ0eXAiOiJKV1MiLCJhbGciOiJSUzI1NiJ9.eyJmb28iOiJiYXIifQ.M3bzN8GKhPxFyENIwcnLb7S_ofOHOjJDh1LXfK5X8No60PGCVa5JIgDeHKLC4_g-mnUqq-JEmxVc8so3FpPWea8c4zHWU1tr1n-GLFO4TSAnsIfuPFcvJB8rNVe4iHA4ePKqUE8Z7jb_d0pcg4NpXr0GYPIg_NQbQIPwjpNz789dpNH3_OClJxeY_ELMkWoZAWHO6uTymPnmlg2KK0PlRp60yWhHi9JlgObYrUEItnjfOyOOqL37oL-S4GyENYFbzcdkCicPIFnnK4oFIY-NmO5Fh6g-NaSPSmgcSiJzbOOdaWNeG6HDQINAEcwT18vUHRVwzGqU1AATztDGpF3mVQ';
    $id_token = OIDC::Lite::Model::IDToken->load($token_string);
    $id_token->key($pubkey);
    ok($id_token->verify());

    $id_token = OIDC::Lite::Model::IDToken->load($token_string, $pubkey);
    ok($id_token->verify());

    $id_token = OIDC::Lite::Model::IDToken->load($token_string, $pubkey, 'RS256');
    ok($id_token->verify());

    $id_token = OIDC::Lite::Model::IDToken->load($token_string, $pubkey, 'RS512');
    ok(!$id_token->verify());

    $token_string = 'eyJ0eXAiOiJKV1MiLCJhbGciOiJSUzI1NiJ9.eyJmb28iOiJiYXIifQ.INVALID';
    $id_token = OIDC::Lite::Model::IDToken->load($token_string);
    $id_token->key($pubkey);
    ok(!$id_token->verify());

    $id_token = OIDC::Lite::Model::IDToken->load($token_string, $pubkey);
    ok(!$id_token->verify());

    $id_token = OIDC::Lite::Model::IDToken->load($token_string, $pubkey, 'RS256');
    ok(!$id_token->verify());
};

done_testing;
