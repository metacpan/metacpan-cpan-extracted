package TestDataHandler;

use strict;
use warnings;

use parent 'OIDC::Lite::Server::DataHandler';

use String::Random;

use OIDC::Lite::Model::AuthInfo;
use OAuth::Lite2::Model::AccessToken;
use OIDC::Lite::Model::IDToken;
use OAuth::Lite2::Model::ServerState;

my %ID_POD = (
    auth_info    => 0,
    access_token => 0,
    user         => 0,
    server_state => 0,
);

my %AUTH_INFO;
my %ACCESS_TOKEN;
my %DEVICE_CODE;
my %CLIENTS;
my %USERS;
my %SERVER_STATE;

sub clear {
    my $class = shift;
    %AUTH_INFO = ();
    %ACCESS_TOKEN = ();
    %DEVICE_CODE = ();
    %CLIENTS = ();
    %USERS = ();
}

sub gen_next_auth_info_id {
    my $class = shift;
    $ID_POD{auth_info}++;
}

sub gen_next_user_id {
    my $class = shift;
    $ID_POD{user}++;
}

sub gen_next_access_token_id {
    my $class = shift;
    $ID_POD{access_token}++;
}

sub gen_next_server_state_id {
    my $class = shift;
    $ID_POD{server_state}++;
}

sub add_client {
    my ($class, %args) = @_;
    $CLIENTS{ $args{id} } = {
        secret  => $args{secret},
        user_id => $args{user_id} || 0,
        response_type => $args{response_type} || 'id_token',
        redirect_uri => $args{redirect_uri} || '',
        scope => $args{scope} || '',
        server_state => $args{server_state} || '',
    };
}

sub add_user {
    my ($class, %args) = @_;
    $USERS{ $args{username} } = {
        password => $args{password},
    };
}

sub init {
    my $self = shift;
}

sub get_user_id {
    my ($self, $username, $password) = @_;
    return unless ($username && exists $USERS{$username});
    return unless ($password && $USERS{$username}{password} eq $password);
    return $username;
}

sub get_client_user_id {
    my ($self, $client_id) = @_;
    return unless ($client_id && exists $CLIENTS{$client_id});
    return $CLIENTS{$client_id}{user_id};
}

# TODO needed?
sub get_client_by_id {
    my ($self, $client_id) = @_;
    return unless ($client_id && exists $CLIENTS{$client_id});
    return $CLIENTS{$client_id};
}

# called in following flows:
#   - refresh
sub get_auth_info_by_refresh_token {
    my ($self, $refresh_token) = @_;

    for my $id (keys %AUTH_INFO) {
        my $auth_info = $AUTH_INFO{$id};
        return $auth_info if $auth_info->{refresh_token} eq $refresh_token;
    }
    return;
}

sub get_auth_info_by_id {
    my ($self, $auth_id) = @_;

    # for croak test
    if ( $auth_id == 99 ) {
        return q{invalid object};
    }

    return $AUTH_INFO{$auth_id};
}

# called in following flows:
#   - device_token
sub get_auth_info_by_code {
    my ($self, $device_code) = @_;

    # for croak test
    if ( $device_code eq q{code_invalid_croak} ) {
        return q{invalid object};
    }

    for my $id (keys %AUTH_INFO) {
        my $auth_info = $AUTH_INFO{$id};
        return $auth_info if ($auth_info->code && $auth_info->code eq $device_code);
    }
    return;
}

sub create_or_update_auth_info {
    my ($self, %params) = @_;

    my $client_id    = $params{client_id};
    my $user_id      = $params{user_id};
    my $scope        = $params{scope};
    my $code         = $params{code};
    my $redirect_uri = $params{redirect_uri};
    my $server_state = $params{server_state};
    my $id_token     = $params{id_token};

    my $id = ref($self)->gen_next_auth_info_id();
    my $refresh_token = sprintf q{refresh_token_%d}, $id;
    $id_token = sprintf q{id_token_%d}, $id
                    unless($id_token);
    $code = sprintf q{code_%d}, $id
                    unless($code);
    my @claims;
    @claims = (q{user_id}, q{email}) if $scope;

    my %attrs = (
        id              => $id,
        client_id       => $client_id,
        user_id         => $user_id,
        scope           => $scope,
        refresh_token   => $refresh_token,
        id_token        => $id_token,
        userinfo_claims => \@claims,
    );
    # for attribute lacked case
    if ( $code eq q{code_without_optional_attr} ) {
        delete $attrs{scope};
        delete $attrs{refresh_token};
        delete $attrs{id_token};
    }

    my $auth_info = OIDC::Lite::Model::AuthInfo->new(\%attrs);
    $auth_info->code($code) if $code;
    $auth_info->redirect_uri($redirect_uri) if $redirect_uri;
    $auth_info->server_state($server_state) if $server_state;

    $AUTH_INFO{$id} = $auth_info;

    return $auth_info;
}

# called in following flows:
#   - refresh
sub create_or_update_access_token {
    my ($self, %params) = @_;

    my $auth_info = $params{auth_info};
    my $auth_id = $auth_info->id;

    # for croak test
    if ( $auth_info->code eq q{code_for_croak_at} ) {
        return q{invalid object};
    }

    my $id = ref($self)->gen_next_access_token_id();
    my $token = sprintf q{access_token_%d}, $id;

    my %attrs = (
        auth_id    => $auth_id,
        token      => $token,
        expires_in => $params{expires_in} || 3600,
        created_on => time(),
    );

    # for attribute lacked case
    if ( $auth_info->code eq q{code_without_optional_attr} or 
         ($auth_info->scope && $auth_info->scope eq q{no_exp openid})) {
        delete $attrs{expires_in};
    }

    my $access_token = OAuth::Lite2::Model::AccessToken->new(\%attrs);
    $ACCESS_TOKEN{$auth_id} = $access_token;
    return $access_token;
}

sub get_access_token {
    my ($self, $token) = @_;

    # for croak test
    if ( $token eq q{token_for_croak} ) {
        return q{invalid object};
    }

    for my $auth_id ( keys %ACCESS_TOKEN ) {
        my $t = $ACCESS_TOKEN{ $auth_id };
        if ($t->token eq $token) {
            return $t;
        }
    }
    return;
}

sub validate_client {
    my ($self, $client_id, $client_secret, $type) = @_;
    return 0 unless exists $CLIENTS{ $client_id };

    my $client = $CLIENTS{ $client_id };
    return 1 if ( $type eq q{server_state} && $client );

    return 0 unless $client->{secret} eq $client_secret;

    if ($client_id eq 'aaa') {
        if ($type eq 'basic-credentials') {
            return 1;
        } else {
            return 0;
        }
    } else {
        return 1;
    }
}

sub validate_client_by_id {
    my ($self, $client_id) = @_;
    return ($client_id ne 'malformed');
}

sub validate_user_by_id {
    my ($self, $user_id) = @_;
    return ($user_id ne 666);
}

# OIDC additional methods
sub validate_client_for_authorization {
    my ($self, $client_id, $response_type) = @_;
    return 0 unless exists $CLIENTS{ $client_id };
    my $client = $CLIENTS{ $client_id };
    return 0 unless ($response_type && $client->{response_type} );
    return 0 unless $client->{response_type} eq $response_type;
    return 1;
}

sub validate_redirect_uri {
    my ($self, $client_id, $redirect_uri) = @_;
    return 0 unless exists $CLIENTS{ $client_id };
    return 0 unless ($redirect_uri);
    my $client = $CLIENTS{ $client_id };
    return 0 unless ($redirect_uri && $client->{redirect_uri} );
    return 0 unless $client->{redirect_uri} eq $redirect_uri;
    return 1;
}

sub validate_scope{
    my ($self, $client_id, $scope) = @_;
    return 0 unless exists $CLIENTS{ $client_id };
    return 0 unless ($scope);
    my $client = $CLIENTS{ $client_id };
    return 0 unless ($scope && $client->{scope} );
    return 0 unless $client->{scope} eq $scope;
    return 1;
}

sub validate_display{
    my ($self, $display) = @_;
    return (!$display || $display ne "wap");
}

sub validate_prompt{
    my ($self, $prompt) = @_;
    return (!$prompt || $prompt ne "none");
}

sub validate_max_age{
    my ($self, $param) = @_;
    return (!$param->{max_age} || $param->{max_age} > 0);
}

sub validate_ui_locales{
    my ($self, $ui_locales) = @_;
    return (!$ui_locales || $ui_locales ne "invalid");
}

sub validate_claims_locales{
    my ($self, $claims_locales) = @_;
    return (!$claims_locales || $claims_locales ne "invalid");
}

sub validate_id_token_hint{
    my ($self, $param) = @_;
    return (!$param->{id_token_hint} || $param->{id_token_hint} ne "invalid");    
}

sub validate_login_hint{
    my ($self, $param) = @_;
    return (!$param->{login_hint} || $param->{login_hint} ne "invalid");    
}

sub validate_acr_values{
    my ($self, $param) = @_;
    return (!$param->{acr_values} || $param->{acr_values} ne "invalid");    
}

sub validate_request{
    my ($self, $param) = @_;
    return (!$param->{request} || $param->{request} ne "invalid");
}

sub validate_request_uri{
    my ($self, $param) = @_;
    return (!$param->{request_uri} || $param->{request_uri} ne "invalid");
}

sub get_user_id_for_authorization {
    my ($self) = @_;
    return 1;
}

sub create_id_token {
    my ($self) = @_;
    my %header =    (
                        typ =>'JWT',
                        alg => 'HS256',
                    );
    my %payload =   (
                        iss     => 'issstr',
                        user_id => '1',
                        aud     => 'audstr',
                        exp     => 1349257197 + 600,
                        iat     => 1349257197,
                    );
    my $key = q{this_is_shared_secret_key};
    return OIDC::Lite::Model::IDToken->new(
        header  => \%header,
        payload => \%payload,
        key     => $key,
    );
}

sub create_server_state {
    my ($self, %params) = @_;

    my $id = ref($self)->gen_next_server_state_id();
    my %attrs = (
        client_id    => $params{client_id},
        server_state => "server_state_".$id,
        expires_in   => $params{expires_in} || 3600,
        created_on   => time(),
    );

    my $state = OAuth::Lite2::Model::ServerState->new(\%attrs);
    $SERVER_STATE{$state->server_state} = $state;
    return $state;
}

sub validate_server_state {
    my ($self, $server_state, $client_id) = @_;
    my $client = $CLIENTS{ $client_id };
    return 0 unless $client->{server_state};
    return ($client->{server_state} eq $server_state);
}

sub require_server_state {
    my ($self, $scope) = @_;
    return ($scope eq q{require_ss});
}

1;
