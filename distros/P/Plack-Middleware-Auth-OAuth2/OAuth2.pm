package Plack::Middleware::Auth::OAuth2;

use base qw(Plack::Middleware);
use strict;
use warnings;

use English;
use Error::Pure qw(err);
use JSON::XS;
use LWP::Authen::OAuth2;
use Plack::Response;
use Plack::Session;
use Plack::Util::Accessor qw(app_login app_login_url client_id client_secret
	logout_path lwp_user_agent redirect_path scope service_provider);

our $VERSION = 0.01;

sub call {
	my ($self, $env) = @_;

	my $session = Plack::Session->new($env);
	my $path_info = $env->{'PATH_INFO'};

	# Check.
	$self->_check_run($env);

	# Create OAuth2 object if doesn't exist.
	$self->_create_oauth2_object($env);

	# Auth page.
	if ($path_info eq '/'.$self->redirect_path) {
		return $self->_app_auth_code->($env);
	}

	# Logout page.
	if ($path_info eq '/'.$self->logout_path) {
		return $self->_app_logout->($env);
	}

	# Check authorized.
	my $authorized = $self->_authorized($env);

	# Application after authorization.
	if ($authorized) {
		return $self->app->($env);

	# Unauthorized page.
	} else {
		$self->app_login_url->($self->app_login,
			$session->get('oauth2.obj')->authorization_url);
		return $self->app_login->to_app->($env);
	}
}

sub prepare_app {
	my $self = shift;

	if (! defined $self->client_id) {
		err "No OAuth2 'client_id' setting.";
	}

	if (! defined $self->client_secret) {
		err "No OAuth2 'client_secret' setting.";
	}

	if (! defined $self->app_login) {
		err 'No login application.';
	}

	if (! defined $self->app_login_url) {
		err 'No login url call.';
	}

	if (! defined $self->redirect_path) {
		err 'No redirect path.';
	}

	if (! defined $self->service_provider) {
		err 'No service provider.';
	}

	if (! defined $self->logout_path) {
		$self->logout_path('logout');
	}

	return;
}

sub _app_auth_code {
	return sub {
		my $env = shift;

		my $req = Plack::Request->new($env);

		my $session = Plack::Session->new($env);

		# Process token string.
		my $oauth2_code = $req->parameters->{'code'};
		if (! defined $oauth2_code) {
			return [
				400,
				['Content-Type' => 'text/plain'],
				['No OAuth2 code.'],
			];
		}
		$session->get('oauth2.obj')->request_tokens('code' => $oauth2_code);

		my $token_string_json = $session->get('oauth2.obj')->token_string;
		my $token_string_hr = JSON::XS->new->decode($token_string_json);
		$session->set('oauth2.token_string', $token_string_hr);

		# Redirect.
		my $res = Plack::Response->new;
		$res->redirect('/');

		return $res->finalize;
	};
}

sub _app_logout {
	return sub {
		my $env = shift;

		my $session = Plack::Session->new($env);

		# Delete token string.
		if (defined $session->get('oauth2.token_string')) {
			$session->remove('oauth2.token_string');
		}

		# Redirect.
		my $res = Plack::Response->new;
		$res->redirect('/');

		return $res->finalize;
	};
}

sub _authorized {
	my ($self, $env) = @_;

	my $session = Plack::Session->new($env);

	# No token string.
	if (! defined $session->get('oauth2.token_string')) {
		return 0;
	}

	# No OAuth2 object.
	if (! defined $session->get('oauth2.obj')) {
		return 0;
	}

	return 1;
}

sub _check_run {
	my ($self, $env) = @_;

	if (! defined $env->{'psgix.session'}) {
		err "No Plack::Middleware::Session present.";
	}

	return;
}

# Create OAuth2 object in session.
sub _create_oauth2_object {
	my ($self, $env) = @_;

	my $session = Plack::Session->new($env);

	# Object is created in session.
	if (defined $session->get('oauth2.obj')) {
		return;
	}

	# XXX Automatically https?
	my $redirect_uri = 'https://'.$env->{'HTTP_HOST'};
	if (! defined $redirect_uri) {
		err 'Missing host.'
	}
	my $redirect_path = $self->redirect_path;
	$redirect_uri .= '/'.$redirect_path;

	# Create object.
	my $oauth2 = eval {
		LWP::Authen::OAuth2->new(
			'client_id' => $self->client_id,
			'client_secret' => $self->client_secret,
			'redirect_uri' => $redirect_uri,
			$self->scope ? ('scope' => $self->scope) : (),
			'service_provider' => $self->service_provider,
		);
	};
	if ($EVAL_ERROR) {
		err "Cannot create OAuth2 object.",
			'Error', $EVAL_ERROR,
		;
	}
	if ($self->lwp_user_agent) {
		$oauth2->set_user_agent($self->lwp_user_agent);
	}
	$session->set('oauth2.obj', $oauth2);

	# Save service provider to session.
	$session->set('oauth2.service_provider', $self->service_provider);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Plack::Middleware::Auth::OAuth2 - Plack OAuth2 middleware.

=head1 SYNOPSIS

 use Plack::Builder;
 use Plack::App::Env;
 use Plack::App::Login;

 my $app = Plack::App::Env->new;
 builder {
         enable 'Session';
         enable 'Auth::OAuth2',
                'client_id' => '__CLIENT_ID__',
                'client_secret => '__CLIENT_SECRET__',
                'app_login' => Plack::App::Login->new,
                'app_login_url' => sub { $_[0]->login_link($_[1]); },
                'logout_path' => 'logout',
                'provider' => 'Google',
                'redirect_path' => 'code',
                'scope' => 'email',
         ;
         $app;
 };

=head1 DESCRIPTION

This middleware provides OAuth2 authentication for web application. Uses
L<LWP::Authen::OAuth2> for implementation.

Prerequisity is use of Plack session management and result is saved to session.

=head1 ACCESSORS

=head2 C<app_login>

Plack application to login.

It's required.

=head2 C<app_login_url>

Callback to set URL from OAuth2 provider to C<app_login()> Plack application.

First argument is C<app_login()> application.
Second argument is C<$url> variable from OAuth2 provider.

It's required.

=head2 C<client_id>

OAuth2 client id.

It's required.

=head2 C<client_secret>

OAuth2 client secret.

It's required.

=head2 C<logout_path>

Logout path for creating of endpoint, which logout from OAuth2.

Default value is 'logout' (/logout).

=head2 C<lwp_user_agent>

Explicit L<LWP::UserAgent> instance.

Default value is L<LWP::UserAgent> instance inside of L<LWP::Authen::OAuth2>.

=head2 C<redirect_path>

Redirect path for creating of endpoint, which is created for service provider
use to set authentication.

It's required.

=head2 C<scope>

OAuth2 scopes in string.

Requirement is defined by provider. It's optional.

=head2 C<service_provider>

Service provider.

Possible providers:

=over

=item Dwolla

Via module L<LWP::Authen::OAuth2::ServiceProvider::Dwolla>.

=item Google

Via module L<LWP::Authen::OAuth2::ServiceProvider::Google>.

=item Line

Via module L<LWP::Authen::OAuth2::ServiceProvider::Line>.

=item MediaWiki

Via module L<LWP::Authen::OAuth2::ServiceProvider::MediaWiki>.

=item Strava

Via module L<LWP::Authen::OAuth2::ServiceProvider::Strava>.

=item Wikimedia

Via module L<LWP::Authen::OAuth2::ServiceProvider::Wikimedia>.

=item Withings

Via module L<LWP::Authen::OAuth2::ServiceProvider::Withings>.

=item Yahoo

Via module L<LWP::Authen::OAuth2::ServiceProvider::Yahoo>.

=back

=head1 ENDPOINTS

=head2 Logout

Logout endpoint is defined inside of this module by setting C<logout_path>
(/__LOGOUT_PATH__).

=head2 Redirect

Redirect endpoint is defined inside of this module by setting C<redirect_path>
(/__REDIRECT_PATH__).

=head1 SESSION VARIABLES

=head2 oauth2.obj

Value is instance of LWP::Authen::OAuth2 used for authentization.

=head2 oauth2.service_provider

Value is authenticated service provider.

=head2 oauth2.token_string

Value is token string.

=head1 ERRORS

 prepare_app():
         No OAuth2 'client_id' setting.
         No OAuth2 'client_secret' setting.
         No login application.
         No login url call.
         No redirect path.
         No service provider.

=head1 DEPENDENCIES

L<English>,
L<Error::Pure>,
L<JSON::XS>,
L<LWP::Authen::OAuth2>,
L<Plack::Middleware>,
L<Plack::Response>,
L<Plack::Session>,
L<Plack::Util::Accessor>.

=head1 SEE ALSO

=over

=item L<LWP::Authen::OAuth2>

Make requests to OAuth2 APIs.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Plack-Middleware-Auth-OAuth2>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
