package Net::Async::Zitadel::Management;

# ABSTRACT: Async client for Zitadel Management API v1

use Moo;
use JSON::MaybeXS qw(encode_json decode_json);
use HTTP::Request;
use MIME::Base64 qw(encode_base64);
use URI;
use Future;
use Net::Async::Zitadel::Error;
use namespace::clean;

our $VERSION = '0.001';

has base_url => (
    is       => 'ro',
    required => 1,
);

has token => (
    is       => 'ro',
    required => 1,
);

has http => (
    is       => 'ro',
    required => 1,
    doc      => 'Net::Async::HTTP instance (shared from parent)',
);

has _api_base => (
    is      => 'lazy',
    builder => sub {
        my $base = $_[0]->base_url;
        $base =~ s{/+$}{};
        "$base/management/v1";
    },
);

sub BUILD {
    my $self = shift;
    die Net::Async::Zitadel::Error::Validation->new(
        message => 'base_url must not be empty',
    ) unless length $self->base_url;
}

sub _require { die Net::Async::Zitadel::Error::Validation->new(message => $_[0]) }

# --- Generic async request methods ---

sub _request_f {
    my ($self, $method, $path, $body) = @_;

    my $url = $self->_api_base . $path;
    my $req = HTTP::Request->new($method => $url);
    $req->header(Authorization => 'Bearer ' . $self->token);
    $req->header(Accept        => 'application/json');

    if ($body) {
        $req->header('Content-Type' => 'application/json');
        $req->content(encode_json($body));
    }

    return $self->http->do_request(request => $req)->then(sub {
        my ($response) = @_;
        my $data;
        if ($response->decoded_content && length $response->decoded_content) {
            eval { $data = decode_json($response->decoded_content) };
        }

        unless ($response->is_success) {
            my $api_msg = $data && $data->{message} ? $data->{message} : undef;
            my $msg = 'API error: ' . $response->status_line;
            $msg .= " - $api_msg" if $api_msg;
            return Future->fail(Net::Async::Zitadel::Error::API->new(
                message     => $msg,
                http_status => $response->status_line,
                api_message => $api_msg,
            ));
        }

        return Future->done($data // {});
    });
}

sub _get_f    { $_[0]->_request_f('GET',    $_[1]) }
sub _post_f   { $_[0]->_request_f('POST',   $_[1], $_[2]) }
sub _put_f    { $_[0]->_request_f('PUT',    $_[1], $_[2]) }
sub _delete_f { $_[0]->_request_f('DELETE', $_[1]) }

# --- Users ---

sub list_users_f {
    my ($self, %args) = @_;
    $self->_post_f('/users/_search', {
        query => {
            offset => $args{offset} // 0,
            limit  => $args{limit}  // 100,
            asc    => $args{asc}    // JSON::MaybeXS::true,
        },
        $args{queries} ? (queries => $args{queries}) : (),
    });
}

sub get_user_f {
    my ($self, $user_id) = @_;
    $user_id or _require('user_id required');
    $self->_get_f("/users/$user_id");
}

sub create_human_user_f {
    my ($self, %args) = @_;
    $self->_post_f('/users/human', {
        userName => $args{user_name}  // _require('user_name required'),
        profile  => {
            firstName   => $args{first_name}   // _require('first_name required'),
            lastName    => $args{last_name}    // _require('last_name required'),
            displayName => $args{display_name} // "$args{first_name} $args{last_name}",
            $args{nick_name}          ? (nickName          => $args{nick_name})          : (),
            $args{preferred_language} ? (preferredLanguage => $args{preferred_language}) : (),
        },
        email => {
            email           => $args{email} // _require('email required'),
            isEmailVerified => $args{email_verified} // JSON::MaybeXS::false,
        },
        $args{phone} ? (phone => {
            phone           => $args{phone},
            isPhoneVerified => $args{phone_verified} // JSON::MaybeXS::false,
        }) : (),
        $args{password} ? (password => $args{password}) : (),
    });
}

sub update_user_f {
    my ($self, $user_id, %args) = @_;
    $user_id or _require('user_id required');
    $self->_put_f("/users/$user_id/profile", {
        $args{first_name}   ? (firstName   => $args{first_name})   : (),
        $args{last_name}    ? (lastName    => $args{last_name})    : (),
        $args{display_name} ? (displayName => $args{display_name}) : (),
        $args{nick_name}    ? (nickName    => $args{nick_name})    : (),
    });
}

sub deactivate_user_f {
    my ($self, $user_id) = @_;
    $user_id or _require('user_id required');
    $self->_post_f("/users/$user_id/_deactivate", {});
}

sub reactivate_user_f {
    my ($self, $user_id) = @_;
    $user_id or _require('user_id required');
    $self->_post_f("/users/$user_id/_reactivate", {});
}

sub delete_user_f {
    my ($self, $user_id) = @_;
    $user_id or _require('user_id required');
    $self->_delete_f("/users/$user_id");
}

# --- Service / machine users ---

sub create_service_user_f {
    my ($self, %args) = @_;
    $self->_post_f('/users/machine', {
        userName    => $args{user_name} // _require('user_name required'),
        name        => $args{name}      // _require('name required'),
        $args{description} ? (description => $args{description}) : (),
    });
}

sub list_service_users_f {
    my ($self, %args) = @_;
    $self->_post_f('/users/_search', {
        query => {
            offset => $args{offset} // 0,
            limit  => $args{limit}  // 100,
            asc    => $args{asc}    // JSON::MaybeXS::true,
        },
        queries => [
            { typeQuery => { type => 'TYPE_MACHINE' } },
            @{ $args{queries} // [] },
        ],
    });
}

sub get_service_user_f {
    my ($self, $user_id) = @_;
    $user_id or _require('user_id required');
    $self->_get_f("/users/$user_id");
}

sub delete_service_user_f {
    my ($self, $user_id) = @_;
    $user_id or _require('user_id required');
    $self->_delete_f("/users/$user_id");
}

# --- Machine keys (JWT auth for service users) ---

sub add_machine_key_f {
    my ($self, $user_id, %args) = @_;
    $user_id or _require('user_id required');
    $self->_post_f("/users/$user_id/keys", {
        type => $args{type} // 'KEY_TYPE_JSON',
        $args{expiration_date} ? (expirationDate => $args{expiration_date}) : (),
    });
}

sub list_machine_keys_f {
    my ($self, $user_id, %args) = @_;
    $user_id or _require('user_id required');
    $self->_post_f("/users/$user_id/keys/_search", {
        query => {
            offset => $args{offset} // 0,
            limit  => $args{limit}  // 100,
        },
    });
}

sub remove_machine_key_f {
    my ($self, $user_id, $key_id) = @_;
    $user_id or _require('user_id required');
    $key_id  or _require('key_id required');
    $self->_delete_f("/users/$user_id/keys/$key_id");
}

# --- Password management ---

sub set_password_f {
    my ($self, $user_id, %args) = @_;
    $user_id or _require('user_id required');
    $self->_post_f("/users/$user_id/password", {
        password        => $args{password} // _require('password required'),
        $args{change_required} ? (changeRequired => $args{change_required}) : (),
    });
}

sub request_password_reset_f {
    my ($self, $user_id) = @_;
    $user_id or _require('user_id required');
    $self->_post_f("/users/$user_id/_reset_password", {});
}

# --- User metadata ---

sub set_user_metadata_f {
    my ($self, $user_id, $key, $value) = @_;
    $user_id       or _require('user_id required');
    $key           or _require('key required');
    defined $value or _require('value required');
    $self->_post_f("/users/$user_id/metadata/$key", {
        value => encode_base64($value, ''),
    });
}

sub get_user_metadata_f {
    my ($self, $user_id, $key) = @_;
    $user_id or _require('user_id required');
    $key     or _require('key required');
    $self->_get_f("/users/$user_id/metadata/$key");
}

sub list_user_metadata_f {
    my ($self, $user_id, %args) = @_;
    $user_id or _require('user_id required');
    $self->_post_f("/users/$user_id/metadata/_search", {
        query => {
            offset => $args{offset} // 0,
            limit  => $args{limit}  // 100,
        },
    });
}

# --- Projects ---

sub list_projects_f {
    my ($self, %args) = @_;
    $self->_post_f('/projects/_search', {
        query => {
            offset => $args{offset} // 0,
            limit  => $args{limit}  // 100,
        },
        $args{queries} ? (queries => $args{queries}) : (),
    });
}

sub get_project_f {
    my ($self, $project_id) = @_;
    $project_id or _require('project_id required');
    $self->_get_f("/projects/$project_id");
}

sub create_project_f {
    my ($self, %args) = @_;
    $self->_post_f('/projects', {
        name => $args{name} // _require('name required'),
        $args{project_role_assertion}   ? (projectRoleAssertion   => $args{project_role_assertion})   : (),
        $args{project_role_check}       ? (projectRoleCheck       => $args{project_role_check})       : (),
        $args{has_project_check}        ? (hasProjectCheck        => $args{has_project_check})        : (),
        $args{private_labeling_setting} ? (privateLabelingSetting => $args{private_labeling_setting}) : (),
    });
}

sub update_project_f {
    my ($self, $project_id, %args) = @_;
    $project_id or _require('project_id required');
    $self->_put_f("/projects/$project_id", {
        name => $args{name} // _require('name required'),
        $args{project_role_assertion}   ? (projectRoleAssertion   => $args{project_role_assertion})   : (),
        $args{project_role_check}       ? (projectRoleCheck       => $args{project_role_check})       : (),
        $args{has_project_check}        ? (hasProjectCheck        => $args{has_project_check})        : (),
        $args{private_labeling_setting} ? (privateLabelingSetting => $args{private_labeling_setting}) : (),
    });
}

sub delete_project_f {
    my ($self, $project_id) = @_;
    $project_id or _require('project_id required');
    $self->_delete_f("/projects/$project_id");
}

# --- Applications (OIDC) ---

sub list_apps_f {
    my ($self, $project_id, %args) = @_;
    $project_id or _require('project_id required');
    $self->_post_f("/projects/$project_id/apps/_search", {
        query => {
            offset => $args{offset} // 0,
            limit  => $args{limit}  // 100,
        },
        $args{queries} ? (queries => $args{queries}) : (),
    });
}

sub get_app_f {
    my ($self, $project_id, $app_id) = @_;
    $project_id or _require('project_id required');
    $app_id     or _require('app_id required');
    $self->_get_f("/projects/$project_id/apps/$app_id");
}

sub create_oidc_app_f {
    my ($self, $project_id, %args) = @_;
    $project_id or _require('project_id required');
    $self->_post_f("/projects/$project_id/apps/oidc", {
        name                  => $args{name}          // _require('name required'),
        redirectUris          => $args{redirect_uris} // _require('redirect_uris required'),
        responseTypes         => $args{response_types} // ['OIDC_RESPONSE_TYPE_CODE'],
        grantTypes            => $args{grant_types}    // ['OIDC_GRANT_TYPE_AUTHORIZATION_CODE'],
        appType               => $args{app_type}       // 'OIDC_APP_TYPE_WEB',
        authMethodType        => $args{auth_method}    // 'OIDC_AUTH_METHOD_TYPE_BASIC',
        $args{post_logout_uris}        ? (postLogoutRedirectUris => $args{post_logout_uris})        : (),
        $args{dev_mode}                ? (devMode                => $args{dev_mode})                : (),
        $args{access_token_type}       ? (accessTokenType        => $args{access_token_type})       : (),
        $args{id_token_role_assertion} ? (idTokenRoleAssertion   => $args{id_token_role_assertion}) : (),
        $args{additional_origins}      ? (additionalOrigins      => $args{additional_origins})      : (),
    });
}

sub update_oidc_app_f {
    my ($self, $project_id, $app_id, %args) = @_;
    $project_id or _require('project_id required');
    $app_id     or _require('app_id required');
    $self->_put_f("/projects/$project_id/apps/$app_id/oidc_config", {
        $args{redirect_uris}           ? (redirectUris            => $args{redirect_uris})           : (),
        $args{response_types}          ? (responseTypes           => $args{response_types})          : (),
        $args{grant_types}             ? (grantTypes              => $args{grant_types})             : (),
        $args{app_type}                ? (appType                 => $args{app_type})                : (),
        $args{auth_method}             ? (authMethodType          => $args{auth_method})             : (),
        $args{post_logout_uris}        ? (postLogoutRedirectUris  => $args{post_logout_uris})        : (),
        $args{dev_mode}                ? (devMode                 => $args{dev_mode})                : (),
        $args{access_token_type}       ? (accessTokenType         => $args{access_token_type})       : (),
        $args{id_token_role_assertion} ? (idTokenRoleAssertion    => $args{id_token_role_assertion}) : (),
        $args{additional_origins}      ? (additionalOrigins       => $args{additional_origins})      : (),
    });
}

sub delete_app_f {
    my ($self, $project_id, $app_id) = @_;
    $project_id or _require('project_id required');
    $app_id     or _require('app_id required');
    $self->_delete_f("/projects/$project_id/apps/$app_id");
}

# --- Organizations ---

sub get_org_f {
    my ($self) = @_;
    $self->_get_f('/orgs/me');
}

sub create_org_f {
    my ($self, %args) = @_;
    $self->_post_f('/orgs', {
        name => $args{name} // _require('name required'),
    });
}

sub list_orgs_f {
    my ($self, %args) = @_;
    $self->_post_f('/orgs/_search', {
        query => {
            offset => $args{offset} // 0,
            limit  => $args{limit}  // 100,
        },
        $args{queries} ? (queries => $args{queries}) : (),
    });
}

sub update_org_f {
    my ($self, %args) = @_;
    $self->_put_f('/orgs/me', {
        name => $args{name} // _require('name required'),
    });
}

sub deactivate_org_f {
    my ($self) = @_;
    $self->_post_f('/orgs/me/_deactivate', {});
}

# --- Roles ---

sub add_project_role_f {
    my ($self, $project_id, %args) = @_;
    $project_id or _require('project_id required');
    $self->_post_f("/projects/$project_id/roles", {
        roleKey     => $args{role_key} // _require('role_key required'),
        displayName => $args{display_name} // $args{role_key},
        $args{group} ? (group => $args{group}) : (),
    });
}

sub list_project_roles_f {
    my ($self, $project_id, %args) = @_;
    $project_id or _require('project_id required');
    $self->_post_f("/projects/$project_id/roles/_search", {
        query => {
            offset => $args{offset} // 0,
            limit  => $args{limit}  // 100,
        },
        $args{queries} ? (queries => $args{queries}) : (),
    });
}

# --- User Grants (role assignments) ---

sub create_user_grant_f {
    my ($self, %args) = @_;
    my $user_id = $args{user_id} // _require('user_id required');
    $self->_post_f("/users/$user_id/grants", {
        projectId => $args{project_id} // _require('project_id required'),
        roleKeys  => $args{role_keys}  // _require('role_keys required'),
    });
}

sub list_user_grants_f {
    my ($self, %args) = @_;
    $self->_post_f('/users/grants/_search', {
        query => {
            offset => $args{offset} // 0,
            limit  => $args{limit}  // 100,
        },
        $args{queries} ? (queries => $args{queries}) : (),
    });
}

# --- Identity Providers (IDPs) ---

sub list_idps_f {
    my ($self, %args) = @_;
    $self->_post_f('/idps/_search', {
        query => {
            offset => $args{offset} // 0,
            limit  => $args{limit}  // 100,
        },
        $args{queries} ? (queries => $args{queries}) : (),
    });
}

sub get_idp_f {
    my ($self, $idp_id) = @_;
    $idp_id or _require('idp_id required');
    $self->_get_f("/idps/$idp_id");
}

sub create_oidc_idp_f {
    my ($self, %args) = @_;
    $self->_post_f('/idps/oidc', {
        name         => $args{name}          // _require('name required'),
        clientId     => $args{client_id}     // _require('client_id required'),
        clientSecret => $args{client_secret} // _require('client_secret required'),
        issuer       => $args{issuer}        // _require('issuer required'),
        scopes       => $args{scopes}        // ['openid', 'profile', 'email'],
        $args{display_name_mapping} ? (displayNameMapping => $args{display_name_mapping}) : (),
        $args{username_mapping}     ? (usernameMapping    => $args{username_mapping})     : (),
        $args{auto_register}        ? (autoRegister       => $args{auto_register})        : (),
    });
}

sub update_idp_f {
    my ($self, $idp_id, %args) = @_;
    $idp_id or _require('idp_id required');
    $self->_put_f("/idps/$idp_id", {
        name => $args{name} // _require('name required'),
        $args{display_name_mapping} ? (displayNameMapping => $args{display_name_mapping}) : (),
        $args{username_mapping}     ? (usernameMapping    => $args{username_mapping})     : (),
        $args{auto_register}        ? (autoRegister       => $args{auto_register})        : (),
    });
}

sub delete_idp_f {
    my ($self, $idp_id) = @_;
    $idp_id or _require('idp_id required');
    $self->_delete_f("/idps/$idp_id");
}

sub activate_idp_f {
    my ($self, $idp_id) = @_;
    $idp_id or _require('idp_id required');
    $self->_post_f("/idps/$idp_id/_activate", {});
}

sub deactivate_idp_f {
    my ($self, $idp_id) = @_;
    $idp_id or _require('idp_id required');
    $self->_post_f("/idps/$idp_id/_deactivate", {});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Zitadel::Management - Async client for Zitadel Management API v1

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::Zitadel;

    my $loop = IO::Async::Loop->new;
    my $z = Net::Async::Zitadel->new(
        issuer => 'https://zitadel.example.com',
        token  => $personal_access_token,
    );
    $loop->add($z);

    my $user = $z->management->create_human_user_f(
        user_name  => 'alice',
        first_name => 'Alice',
        last_name  => 'Smith',
        email      => 'alice@example.com',
    )->get;

=head1 DESCRIPTION

Async client for the Zitadel Management API v1. All methods have the C<_f>
suffix and return L<Future> objects. Mirrors the full API surface of
L<WWW::Zitadel::Management>.

Errors are thrown (or returned as failed Futures) as
L<Net::Async::Zitadel::Error> objects that stringify to their C<message>.

=head1 SEE ALSO

L<Net::Async::Zitadel>, L<WWW::Zitadel::Management>, L<Future>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-zitadel/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
