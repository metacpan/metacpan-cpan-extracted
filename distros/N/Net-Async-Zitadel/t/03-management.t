use strict;
use warnings;

use Test::More;
use Test::Exception;
use JSON::MaybeXS qw(encode_json decode_json);
use Future;
use MIME::Base64 qw(decode_base64);

use Net::Async::Zitadel::Management;
use Net::Async::Zitadel::Error;

# --- Mock helpers ---

{
    package Local::Response;
    sub new { my ($class, %args) = @_; bless \%args, $class }
    sub is_success      { $_[0]->{is_success} }
    sub status_line     { $_[0]->{status_line} }
    sub decoded_content { $_[0]->{decoded_content} // '' }
}

{
    # Intercepts do_request calls and records the HTTP::Request objects.
    package Local::MockHTTP;

    sub new {
        my ($class, @futures) = @_;
        bless { queue => [@futures], requests => [] }, $class;
    }

    sub requests { $_[0]->{requests} }

    sub do_request {
        my ($self, %args) = @_;
        push @{ $self->{requests} }, $args{request};
        my $f = shift @{ $self->{queue} };
        die "No more mock responses\n" unless $f;
        return $f;
    }
}

{
    # Subclass that short-circuits _request_f to just record calls.
    package Local::Recorder;
    use Moo;
    extends 'Net::Async::Zitadel::Management';

    has calls => (is => 'rw', default => sub { [] });

    sub _request_f {
        my ($self, $method, $path, $body) = @_;
        push @{ $self->calls }, [$method, $path, $body];
        return Future->done({ ok => JSON::MaybeXS::true });
    }
}

sub _ok {
    Future->done(Local::Response->new(
        is_success      => 1,
        status_line     => '200 OK',
        decoded_content => encode_json($_[0]),
    ));
}

sub _err {
    my ($status, $body) = @_;
    Future->done(Local::Response->new(
        is_success      => 0,
        status_line     => $status,
        decoded_content => $body // '',
    ));
}

sub _recorder {
    Local::Recorder->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
        http     => bless {}, 'Local::FakeHTTP',
    );
}

# --- _request_f: URL / headers / body encoding ---

{
    my $http = Local::MockHTTP->new(_ok({ ok => 1 }));
    my $mgmt = Net::Async::Zitadel::Management->new(
        base_url => 'https://zitadel.example.com///',
        token    => 'pat-token',
        http     => $http,
    );

    is $mgmt->_api_base, 'https://zitadel.example.com/management/v1',
        '_api_base trims trailing slashes';

    my $res = $mgmt->_post_f('/users/_search', { query => { limit => 1 } })->get;
    is $res->{ok}, 1, '_request_f resolves decoded JSON';

    my $req = $http->requests->[0];
    isa_ok $req, 'HTTP::Request';
    is $req->method, 'POST', 'request method';
    is $req->uri->as_string,
        'https://zitadel.example.com/management/v1/users/_search', 'request URL';
    is $req->header('Authorization'), 'Bearer pat-token', 'Authorization header';
    is $req->header('Accept'), 'application/json', 'Accept header';
    is $req->header('Content-Type'), 'application/json', 'Content-Type header';
    is decode_json($req->content)->{query}{limit}, 1, 'JSON body encoded correctly';
}

# --- Empty 204 response ---

{
    my $http = Local::MockHTTP->new(
        Future->done(Local::Response->new(
            is_success => 1, status_line => '204 No Content', decoded_content => '',
        ))
    );
    my $mgmt = Net::Async::Zitadel::Management->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
        http     => $http,
    );

    my $res = $mgmt->_delete_f('/users/u1')->get;
    is_deeply $res, {}, 'empty response gives empty hashref';
}

# --- API error as typed exception ---

{
    my $http = Local::MockHTTP->new(
        _err('403 Forbidden', encode_json({ message => 'permission denied' }))
    );
    my $mgmt = Net::Async::Zitadel::Management->new(
        base_url => 'https://zitadel.example.com',
        token    => 'pat-token',
        http     => $http,
    );

    my $f = $mgmt->_get_f('/users/x');
    ok $f->is_failed, '_request_f gives failed Future on API error';
    eval { $f->get };
    my $err = $@;
    ok ref $err && $err->isa('Net::Async::Zitadel::Error::API'),
        'API error throws Net::Async::Zitadel::Error::API';
    like "$err", qr/403 Forbidden/, 'API error stringifies with status';
    like "$err", qr/permission denied/, 'API error stringifies with api message';
    is $err->http_status, '403 Forbidden', 'API error http_status attribute';
    is $err->api_message, 'permission denied', 'API error api_message attribute';
}

# --- User operations: paths and payload shapes ---

{
    my $m = _recorder();

    $m->list_users_f(offset => 5, limit => 20);
    $m->create_human_user_f(
        user_name => 'alice', first_name => 'Alice',
        last_name => 'Smith', email => 'alice@example.com',
    );
    $m->get_user_f('u1');
    $m->update_user_f('u1', first_name => 'A', last_name => 'B');
    $m->deactivate_user_f('u1');
    $m->reactivate_user_f('u1');
    $m->delete_user_f('u1');

    my $c = $m->calls;

    is $c->[0][0], 'POST', 'list_users_f uses POST';
    is $c->[0][1], '/users/_search', 'list_users_f path';
    is $c->[0][2]{query}{offset}, 5, 'list_users_f offset';
    is $c->[0][2]{query}{limit}, 20, 'list_users_f limit';

    is $c->[1][1], '/users/human', 'create_human_user_f path';
    is $c->[1][2]{userName}, 'alice', 'create_human_user_f userName';
    is $c->[1][2]{profile}{displayName}, 'Alice Smith', 'create_human_user_f default displayName';

    is_deeply $c->[2], ['GET', '/users/u1', undef], 'get_user_f path';
    is $c->[3][1], '/users/u1/profile', 'update_user_f path';
    is $c->[3][2]{firstName}, 'A', 'update_user_f firstName';
    is_deeply $c->[4], ['POST', '/users/u1/_deactivate', {}], 'deactivate_user_f path';
    is_deeply $c->[5], ['POST', '/users/u1/_reactivate', {}], 'reactivate_user_f path';
    is_deeply $c->[6], ['DELETE', '/users/u1', undef], 'delete_user_f path';

    throws_ok { $m->create_human_user_f(user_name => 'x', first_name => 'X', email => 'x@x') }
        qr/last_name required/, 'create_human_user_f validates last_name';
}

# --- Service users and machine keys ---

{
    my $m = _recorder();

    $m->create_service_user_f(user_name => 'ci', name => 'CI Bot', description => 'pipeline');
    $m->list_service_users_f(limit => 10);
    $m->get_service_user_f('su1');
    $m->delete_service_user_f('su1');

    $m->add_machine_key_f('su1', type => 'KEY_TYPE_JSON', expiration_date => '2030-01-01T00:00:00Z');
    $m->list_machine_keys_f('su1', limit => 5);
    $m->remove_machine_key_f('su1', 'key1');

    my $c = $m->calls;

    is $c->[0][1], '/users/machine', 'create_service_user_f path';
    is $c->[0][2]{userName}, 'ci', 'create_service_user_f userName';
    is $c->[0][2]{description}, 'pipeline', 'create_service_user_f description';

    is $c->[1][1], '/users/_search', 'list_service_users_f path';
    is $c->[1][2]{queries}[0]{typeQuery}{type}, 'TYPE_MACHINE',
        'list_service_users_f filters by TYPE_MACHINE';
    is $c->[1][2]{query}{limit}, 10, 'list_service_users_f limit';

    is_deeply $c->[2], ['GET', '/users/su1', undef], 'get_service_user_f path';
    is_deeply $c->[3], ['DELETE', '/users/su1', undef], 'delete_service_user_f path';

    is $c->[4][1], '/users/su1/keys', 'add_machine_key_f path';
    is $c->[4][2]{type}, 'KEY_TYPE_JSON', 'add_machine_key_f type';
    is $c->[4][2]{expirationDate}, '2030-01-01T00:00:00Z',
        'add_machine_key_f expiration_date -> expirationDate';

    is $c->[5][1], '/users/su1/keys/_search', 'list_machine_keys_f path';
    is $c->[5][2]{query}{limit}, 5, 'list_machine_keys_f limit';

    is_deeply $c->[6], ['DELETE', '/users/su1/keys/key1', undef], 'remove_machine_key_f path';

    throws_ok { $m->create_service_user_f(name => 'Bot') } qr/user_name required/;
    throws_ok { $m->remove_machine_key_f('u1', undef) } qr/key_id required/;
}

# --- Password and metadata ---

{
    my $m = _recorder();

    $m->set_password_f('u1', password => 's3cr3t!', change_required => JSON::MaybeXS::true);
    $m->request_password_reset_f('u1');
    $m->set_user_metadata_f('u1', 'dept', 'engineering');
    $m->get_user_metadata_f('u1', 'dept');
    $m->list_user_metadata_f('u1', limit => 20);

    my $c = $m->calls;

    is $c->[0][1], '/users/u1/password', 'set_password_f path';
    is $c->[0][2]{password}, 's3cr3t!', 'set_password_f password';
    ok $c->[0][2]{changeRequired}, 'set_password_f change_required -> changeRequired';

    is_deeply $c->[1], ['POST', '/users/u1/_reset_password', {}], 'request_password_reset_f path';

    is $c->[2][1], '/users/u1/metadata/dept', 'set_user_metadata_f path';
    is decode_base64($c->[2][2]{value}), 'engineering',
        'set_user_metadata_f value is base64-encoded';

    is_deeply $c->[3], ['GET', '/users/u1/metadata/dept', undef], 'get_user_metadata_f path';

    is $c->[4][1], '/users/u1/metadata/_search', 'list_user_metadata_f path';
    is $c->[4][2]{query}{limit}, 20, 'list_user_metadata_f limit';

    throws_ok { $m->set_password_f(undef, password => 'x') } qr/user_id required/;
    throws_ok { $m->set_password_f('u1') } qr/password required/;
    throws_ok { $m->set_user_metadata_f('u1', undef, 'v') } qr/key required/;
    throws_ok { $m->set_user_metadata_f('u1', 'k', undef) } qr/value required/;
}

# --- Projects ---

{
    my $m = _recorder();

    $m->list_projects_f(limit => 50);
    $m->get_project_f('p1');
    $m->create_project_f(name => 'My App');
    $m->update_project_f('p1', name => 'Renamed');
    $m->delete_project_f('p1');

    my $c = $m->calls;

    is $c->[0][1], '/projects/_search', 'list_projects_f path';
    is $c->[0][2]{query}{limit}, 50, 'list_projects_f limit';
    is_deeply $c->[1], ['GET', '/projects/p1', undef], 'get_project_f path';
    is $c->[2][1], '/projects', 'create_project_f path';
    is $c->[2][2]{name}, 'My App', 'create_project_f name';
    is $c->[3][2]{name}, 'Renamed', 'update_project_f name';
    is_deeply $c->[4], ['DELETE', '/projects/p1', undef], 'delete_project_f path';
}

# --- OIDC apps with camelCase mapping ---

{
    my $m = _recorder();

    $m->create_oidc_app_f('p1',
        name          => 'App',
        redirect_uris => ['https://app.example.com/cb'],
    );

    $m->update_oidc_app_f('p1', 'a1',
        redirect_uris    => ['https://app.example.com/cb'],
        response_types   => ['OIDC_RESPONSE_TYPE_CODE'],
        auth_method      => 'OIDC_AUTH_METHOD_TYPE_BASIC',
        additional_origins => ['https://extra.example.com'],
    );

    my $c = $m->calls;

    is $c->[0][1], '/projects/p1/apps/oidc', 'create_oidc_app_f path';
    is_deeply $c->[0][2]{redirectUris}, ['https://app.example.com/cb'],
        'create_oidc_app_f redirect_uris -> redirectUris';
    is $c->[0][2]{appType}, 'OIDC_APP_TYPE_WEB', 'create_oidc_app_f default appType';

    is $c->[1][1], '/projects/p1/apps/a1/oidc_config', 'update_oidc_app_f path';
    is_deeply $c->[1][2]{redirectUris}, ['https://app.example.com/cb'],
        'update_oidc_app_f redirect_uris -> redirectUris';
    is_deeply $c->[1][2]{responseTypes}, ['OIDC_RESPONSE_TYPE_CODE'],
        'update_oidc_app_f response_types -> responseTypes';
    is $c->[1][2]{authMethodType}, 'OIDC_AUTH_METHOD_TYPE_BASIC',
        'update_oidc_app_f auth_method -> authMethodType';
    is_deeply $c->[1][2]{additionalOrigins}, ['https://extra.example.com'],
        'update_oidc_app_f additional_origins -> additionalOrigins';

    throws_ok { $m->create_oidc_app_f('p1', name => 'App') }
        qr/redirect_uris required/, 'create_oidc_app_f validates redirect_uris';
}

# --- Organizations ---

{
    my $m = _recorder();

    $m->get_org_f;
    $m->create_org_f(name => 'Acme');
    $m->list_orgs_f(limit => 50);
    $m->update_org_f(name => 'Acme Inc');
    $m->deactivate_org_f;

    my $c = $m->calls;

    is_deeply $c->[0], ['GET', '/orgs/me', undef], 'get_org_f path';
    is $c->[1][1], '/orgs', 'create_org_f path';
    is $c->[1][2]{name}, 'Acme', 'create_org_f name';
    is $c->[2][1], '/orgs/_search', 'list_orgs_f path';
    is $c->[3][1], '/orgs/me', 'update_org_f path';
    is $c->[3][2]{name}, 'Acme Inc', 'update_org_f name';
    is_deeply $c->[4], ['POST', '/orgs/me/_deactivate', {}], 'deactivate_org_f path';

    throws_ok { $m->create_org_f } qr/name required/, 'create_org_f validates name';
    throws_ok { $m->update_org_f } qr/name required/, 'update_org_f validates name';
}

# --- Roles and grants ---

{
    my $m = _recorder();

    $m->add_project_role_f('p1', role_key => 'viewer');
    $m->list_project_roles_f('p1', limit => 10);
    $m->create_user_grant_f(user_id => 'u1', project_id => 'p1', role_keys => ['viewer']);
    $m->list_user_grants_f(limit => 3);

    my $c = $m->calls;

    is $c->[0][1], '/projects/p1/roles', 'add_project_role_f path';
    is $c->[0][2]{roleKey}, 'viewer', 'add_project_role_f roleKey';
    is $c->[0][2]{displayName}, 'viewer', 'add_project_role_f displayName defaults to role_key';

    is $c->[1][1], '/projects/p1/roles/_search', 'list_project_roles_f path';
    is $c->[1][2]{query}{limit}, 10, 'list_project_roles_f limit';

    is $c->[2][1], '/users/u1/grants', 'create_user_grant_f path';
    is_deeply $c->[2][2]{roleKeys}, ['viewer'], 'create_user_grant_f roleKeys';

    is $c->[3][1], '/users/grants/_search', 'list_user_grants_f path';
    is $c->[3][2]{query}{limit}, 3, 'list_user_grants_f limit';

    throws_ok { $m->add_project_role_f('p1', display_name => 'V') }
        qr/role_key required/, 'add_project_role_f validates role_key';
    throws_ok { $m->create_user_grant_f(project_id => 'p1', role_keys => ['v']) }
        qr/user_id required/, 'create_user_grant_f validates user_id';
}

# --- Identity Providers ---

{
    my $m = _recorder();

    $m->create_oidc_idp_f(
        name          => 'Google',
        client_id     => 'gid',
        client_secret => 'gsecret',
        issuer        => 'https://accounts.google.com',
        scopes        => ['openid', 'email'],
        auto_register => 1,
    );
    $m->list_idps_f(limit => 5);
    $m->get_idp_f('idp1');
    $m->update_idp_f('idp1', name => 'Google Updated');
    $m->activate_idp_f('idp1');
    $m->deactivate_idp_f('idp1');
    $m->delete_idp_f('idp1');

    my $c = $m->calls;

    is $c->[0][0], 'POST', 'create_oidc_idp_f uses POST';
    is $c->[0][1], '/idps/oidc', 'create_oidc_idp_f path';
    is $c->[0][2]{name}, 'Google', 'create_oidc_idp_f name';
    is $c->[0][2]{clientId}, 'gid', 'create_oidc_idp_f clientId';
    is $c->[0][2]{clientSecret}, 'gsecret', 'create_oidc_idp_f clientSecret';
    is $c->[0][2]{issuer}, 'https://accounts.google.com', 'create_oidc_idp_f issuer';
    is_deeply $c->[0][2]{scopes}, ['openid', 'email'], 'create_oidc_idp_f scopes';
    ok $c->[0][2]{autoRegister}, 'create_oidc_idp_f auto_register -> autoRegister';

    is $c->[1][1], '/idps/_search', 'list_idps_f path';
    is $c->[1][2]{query}{limit}, 5, 'list_idps_f limit';

    is_deeply $c->[2], ['GET', '/idps/idp1', undef], 'get_idp_f path';

    is $c->[3][0], 'PUT', 'update_idp_f uses PUT';
    is $c->[3][1], '/idps/idp1', 'update_idp_f path';
    is $c->[3][2]{name}, 'Google Updated', 'update_idp_f name';

    is_deeply $c->[4], ['POST', '/idps/idp1/_activate',   {}], 'activate_idp_f path';
    is_deeply $c->[5], ['POST', '/idps/idp1/_deactivate', {}], 'deactivate_idp_f path';
    is_deeply $c->[6], ['DELETE', '/idps/idp1', undef],        'delete_idp_f path';

    throws_ok { $m->create_oidc_idp_f(client_id => 'x', client_secret => 'y', issuer => 'z') }
        qr/name required/, 'create_oidc_idp_f validates name';
    throws_ok { $m->create_oidc_idp_f(name => 'n', client_secret => 'y', issuer => 'z') }
        qr/client_id required/, 'create_oidc_idp_f validates client_id';
    throws_ok { $m->get_idp_f(undef) }    qr/idp_id required/, 'get_idp_f validates idp_id';
    throws_ok { $m->delete_idp_f(undef) } qr/idp_id required/, 'delete_idp_f validates idp_id';
    throws_ok { $m->update_idp_f('i1') }  qr/name required/,   'update_idp_f validates name';
}

done_testing;
