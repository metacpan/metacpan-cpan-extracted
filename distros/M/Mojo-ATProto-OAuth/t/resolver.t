use Test2::V0;

use Mojo::ATProto::OAuth::Resolver qw//;
use Mojo::JSON qw/true false/;

# Validation rules mirror indigo's AuthServerMetadata.Validate()
# (atproto/auth/oauth/types.go), read directly from source - each
# subtest below corresponds to one of its checks.

my $resolver   = Mojo::ATProto::OAuth::Resolver->new;
my $server_url = 'https://pds.example.com';

sub valid_metadata {
    return {
        issuer                                              => 'https://pds.example.com',
        authorization_endpoint                              => 'https://pds.example.com/oauth/authorize',
        token_endpoint                                       => 'https://pds.example.com/oauth/token',
        response_types_supported                            => ['code'],
        grant_types_supported                               => ['authorization_code', 'refresh_token'],
        code_challenge_methods_supported                    => ['S256'],
        token_endpoint_auth_methods_supported               => ['none', 'private_key_jwt'],
        token_endpoint_auth_signing_alg_values_supported    => ['ES256'],
        scopes_supported                                    => ['atproto', 'transition:email'],
        authorization_response_iss_parameter_supported      => true,
        require_pushed_authorization_requests               => true,
        pushed_authorization_request_endpoint               => 'https://pds.example.com/oauth/par',
        dpop_signing_alg_values_supported                   => ['ES256'],
        client_id_metadata_document_supported               => true,
    };
}

subtest 'a fully valid document passes' => sub {
    ok(lives { $resolver->_validate_auth_server_metadata(valid_metadata(), $server_url) }, 'no exception') or note($@);
};

subtest 'empty issuer is rejected' => sub {
    my $meta = valid_metadata();
    $meta->{issuer} = '';
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/empty issuer/, 'rejected');
};

subtest 'issuer must match the server URL fetched from' => sub {
    my $meta = valid_metadata();
    $meta->{issuer} = 'https://someone-elses-server.example.com';
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/issuer must match request URL/, 'rejected');
};

subtest 'issuer with a path is rejected' => sub {
    my $meta = valid_metadata();
    $meta->{issuer} = 'https://pds.example.com/some/path';
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/issuer URL/, 'rejected');
};

subtest 'non-https authorization_endpoint is rejected' => sub {
    my $meta = valid_metadata();
    $meta->{authorization_endpoint} = 'http://pds.example.com/oauth/authorize';
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/authorization_endpoint/, 'rejected');
};

subtest 'response_types_supported must include code' => sub {
    my $meta = valid_metadata();
    $meta->{response_types_supported} = ['token'];
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/response_types_supported/, 'rejected');
};

subtest 'grant_types_supported must include authorization_code' => sub {
    my $meta = valid_metadata();
    $meta->{grant_types_supported} = ['refresh_token'];
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/authorization_code/, 'rejected');
};

subtest 'grant_types_supported must include refresh_token' => sub {
    my $meta = valid_metadata();
    $meta->{grant_types_supported} = ['authorization_code'];
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/refresh_token/, 'rejected');
};

subtest 'code_challenge_methods_supported must include S256' => sub {
    my $meta = valid_metadata();
    $meta->{code_challenge_methods_supported} = ['plain'];
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/S256/, 'rejected');
};

subtest 'token_endpoint_auth_methods_supported must include none' => sub {
    my $meta = valid_metadata();
    $meta->{token_endpoint_auth_methods_supported} = ['private_key_jwt'];
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/must include 'none'/, 'rejected');
};

subtest 'token_endpoint_auth_methods_supported must include private_key_jwt' => sub {
    my $meta = valid_metadata();
    $meta->{token_endpoint_auth_methods_supported} = ['none'];
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/private_key_jwt/, 'rejected');
};

subtest 'token_endpoint_auth_signing_alg_values_supported must include ES256' => sub {
    my $meta = valid_metadata();
    $meta->{token_endpoint_auth_signing_alg_values_supported} = ['RS256'];
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/token_endpoint_auth_signing_alg_values_supported/, 'rejected');
};

subtest 'scopes_supported must include atproto' => sub {
    my $meta = valid_metadata();
    $meta->{scopes_supported} = ['transition:email'];
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/scopes_supported/, 'rejected');
};

subtest 'authorization_response_iss_parameter_supported must be true' => sub {
    my $meta = valid_metadata();
    $meta->{authorization_response_iss_parameter_supported} = false;
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/authorization_response_iss_parameter_supported/, 'rejected');
};

subtest 'require_pushed_authorization_requests must be true' => sub {
    my $meta = valid_metadata();
    $meta->{require_pushed_authorization_requests} = false;
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/require_pushed_authorization_requests/, 'rejected');
};

subtest 'pushed_authorization_request_endpoint is required' => sub {
    my $meta = valid_metadata();
    delete $meta->{pushed_authorization_request_endpoint};
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/pushed_authorization_request_endpoint/, 'rejected');
};

subtest 'dpop_signing_alg_values_supported must include ES256' => sub {
    my $meta = valid_metadata();
    $meta->{dpop_signing_alg_values_supported} = ['RS256'];
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/dpop_signing_alg_values_supported/, 'rejected');
};

subtest 'require_request_uri_registration=false is rejected, but absent is fine' => sub {
    my $meta = valid_metadata();
    $meta->{require_request_uri_registration} = false;
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/require_request_uri_registration/, 'false is rejected');

    my $meta2 = valid_metadata();
    $meta2->{require_request_uri_registration} = true;
    ok(lives { $resolver->_validate_auth_server_metadata($meta2, $server_url) }, 'true is fine') or note($@);
};

subtest 'client_id_metadata_document_supported must be true' => sub {
    my $meta = valid_metadata();
    $meta->{client_id_metadata_document_supported} = false;
    like(dies { $resolver->_validate_auth_server_metadata($meta, $server_url) }, qr/client_id_metadata_document_supported/, 'rejected');
};

subtest 'resolve_auth_server_url and resolve_auth_server_metadata reject non-public host URLs up front' => sub {
    like(dies { $resolver->resolve_auth_server_url('http://pds.example.com') }, qr/not a valid public host URL/, 'http rejected');
    like(dies { $resolver->resolve_auth_server_url('https://pds.example.com:8080') }, qr/not a valid public host URL/, 'explicit port rejected');
    like(dies { $resolver->resolve_auth_server_metadata('http://pds.example.com') }, qr/not a valid public host URL/, 'http rejected');
};

done_testing;
