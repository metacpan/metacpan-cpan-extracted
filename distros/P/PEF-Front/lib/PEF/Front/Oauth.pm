package PEF::Front::Oauth;

use strict;
use warnings;
use URI;
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;
use PEF::Front::Config;
use PEF::Front::Session;

my $coro_ae_lwp;

BEGIN {
	if ($INC{'Coro/AnyEvent.pm'}) {
		eval "use AnyEvent::HTTP::LWP::UserAgent";
		$coro_ae_lwp = ($@) ? 0 : 1;
	} else {
		$coro_ae_lwp = 0;
	}
}

sub _authorization_server {
	die 'unimplemented base method';
}

sub _token_request {
	die 'unimplemented base method';
}

sub _get_user_info_request {
	die 'unimplemented base method';
}

sub _parse_user_info {
	die 'unimplemented base method';
}

sub _required_redirect_uri {0}
sub _required_state        {1}
sub _returns_state         {1}

sub _decode_token {
	decode_json($_[1]);
}

sub user_info_scope {
	my ($self) = @_;
	cfg_oauth_scopes($self->{service})->{user_info};
}

sub authorization_server {
	my ($self, $scope, $redirect_uri) = @_;
	my $uri = URI->new($self->_authorization_server);
	$self->{state} = PEF::Front::Session::_secure_value;
	$self->{session}->data->{oauth_state}{$self->{state}} = $self->{service};
	my @extra = ();
	if (defined $scope) {
		@extra = (scope => $scope);
	}
	if (defined $redirect_uri) {
		my $uri = URI->new($redirect_uri);
		$uri->query_form($uri->query_form, state => $self->{state}) unless $self->_returns_state;
		push @extra, (redirect_uri => $uri->as_string);
		$self->{session}->data->{oauth_redirect_uri}{$self->{service}} = $uri->as_string;
	} elsif ($self->_required_redirect_uri) {
		die {
			result      => 'OAUTHERR',
			answer      => 'Oauth $1 requires redirect_uri',
			answer_args => [$self->{service}]
		};
	}
	push @extra, (state => $self->{state}) if $self->_required_state;
	$uri->query_form(
		response_type => 'code',
		client_id     => cfg_oauth_client_id($self->{service}),
		@extra
	);
	$uri->as_string;
}

sub exchange_code_to_token {
	my ($self, $request) = @_;
	if ($request->{code}) {
		my $token_answer;
		delete $self->{session}->data->{oauth_state};
		$self->{session}->store;
		my $exception;
		if ($coro_ae_lwp && $Coro::main != $Coro::current) {
			my $lwp_user_agent = AnyEvent::HTTP::LWP::UserAgent->new;
			$lwp_user_agent->timeout(cfg_oauth_connect_timeout());
			my $request  = $self->_token_request($request->{code});
			my $response = $lwp_user_agent->request($request);
			$exception = "timeout" if !$response or !$response->decoded_content;
		} else {
			eval {
				local $SIG{ALRM} = sub {die "timeout"};
				alarm cfg_oauth_connect_timeout();
				my $lwp_user_agent = LWP::UserAgent->new;
				my $request        = $self->_token_request($request->{code});
				my $response       = $lwp_user_agent->request($request);
				die if !$response or !$response->decoded_content;
				$token_answer = $self->_decode_token($response->decoded_content);
			};
			$exception = $@;
			alarm 0;
		}
		delete $self->{session}->data->{oauth_redirect_uri}{$self->{service}};
		if ($exception) {
			$self->{session}->data->{oauth_error} = $exception;
			die {
				result => 'OAUTHERR',
				answer => 'Oauth timeout'
			} if $exception =~ /timeout/;
			die {
				result => 'OAUTHERR',
				answer => 'Oauth connect error'
			};
		}
		if ($token_answer->{error} || !$token_answer->{access_token}) {
			$self->{session}->data->{oauth_error}
				= $token_answer->{error_description} || $token_answer->{error} || 'no access token';
			die {
				result      => 'OAUTHERR',
				answer      => 'Oauth error: $1',
				answer_args => [$self->{session}->data->{oauth_error}]
			};
		}
		$self->{session}->load;
		delete $self->{session}->data->{oauth_error};
		$self->{session}->data->{oauth_access_token}{$self->{service}} = $token_answer->{access_token};
		$self->{session}->store;
	} else {
		my $message = $request->{error_description} || $request->{error} || 'Internal Oauth error';
		die {
			result => 'OAUTHERR',
			answer => $message
		};
	}

}

sub get_user_info {
	my ($self) = @_;
	my $info;
	$self->{session}->store;
	my $exception;
	if ($coro_ae_lwp && $Coro::main != $Coro::current) {
		my $lwp_user_agent = AnyEvent::HTTP::LWP::UserAgent->new;
		$lwp_user_agent->timeout(cfg_oauth_connect_timeout());
		my $response = $lwp_user_agent->request($self->_get_user_info_request);
		if ($response && $response->decoded_content) {
			$info = eval {decode_json $response->decoded_content};
			$exception = $@;
		} else {
			$exception = "timeout";
		}
	} else {
		eval {
			local $SIG{ALRM} = sub {die "timeout"};
			alarm cfg_oauth_connect_timeout();
			my $lwp_user_agent = LWP::UserAgent->new;
			my $response       = $lwp_user_agent->request($self->_get_user_info_request);
			die if !$response or !$response->decoded_content;
			$info = decode_json $response->decoded_content;
		};
		$exception = $@;
		alarm 0;
	}
	if ($exception) {
		$self->{session}->data->{oauth_error} = $exception;
		die {
			result => 'OAUTHERR',
			answer => 'Oauth timeout'
		} if $exception =~ /timeout/;
		die {
			result => 'OAUTHERR',
			answer => 'Oauth connect error'
		};
	}
	if ($info->{error}) {
		$self->{session}->data->{oauth_error} = $info->{error_description} || $info->{error};
		die {
			result      => 'OAUTHERR',
			answer      => 'Oauth error: $1',
			answer_args => [$self->{session}->data->{oauth_error}]
		};
	}
	$self->{session}->load;
	delete $self->{session}->data->{oauth_error};
	$self->{session}->data->{oauth_info_raw}{$self->{service}} = $info;
	$self->{session}->data->{oauth_info} = [] if !$self->{session}->data->{oauth_info};
	my $oi = $self->{session}->data->{oauth_info};
	for (my $i = 0; $i < @$oi; ++$i) {
		if ($oi->[$i]->{service} eq $self->{service}) {
			splice @$oi, $i, 1;
			last;
		}
	}
	my $parsed_info = $self->_parse_user_info;
	$parsed_info->{service} = $self->{service};
	unshift @$oi, $parsed_info;
	$self->{session}->store;
	$parsed_info;
}

sub load_module {
	my ($auth_service) = @_;
	my $module = $auth_service;
	$module =~ s/[-_]([[:lower:]])/\u$1/g;
	$module = ucfirst($module);
	my $module_file = "PEF/Front/Oauth/$module.pm";
	eval {require $module_file};
	if ($@) {
		die {
			result      => 'INTERR',
			answer      => 'Unknown oauth service $1',
			answer_args => [$auth_service]
		};
	}
	return "PEF::Front::Oauth::$module";
}

sub new {
	my ($class, $auth_service, $session) = @_;
	my $module = load_module($auth_service);
	$auth_service =~ tr/-/_/;
	$module->new(
		{   session => $session,
			service => $auth_service,
		}
	);
}

1;

__END__

=head1 NAME
 
PEF::Front::Oauth - This is an implementation of OAuth2 API 
for several popular services.

=head1 SYNOPSIS

  package MyApp::Local::Oauth;
  use PEF::Front::Config;
  use PEF::Front::Oauth;
  use PEF::Front::Session;
  use strict;
  use warnings;

  sub make_url {
    my ($req, $context) = @_;
    my $session = PEF::Front::Session->new($req);
    my $oauth   = PEF::Front::Oauth->new($req->{service}, $session);
    my $expires = demo_login_expires();
    $session->data->{oauth_return_url} = $context->{headers}->get_header('Referer') || '/';
    return {
        result  => "OK",
        url     => $oauth->authorization_server($oauth->user_info_scope),
        auth    => $session->key,
        expires => $expires,
        service => $req->{service},
    };
  }

  sub callback {
    my ($req, $context) = @_;
    my $session = PEF::Front::Session->new($req);
    my $back_url = $session->data->{oauth_return_url} || '/';
    delete $session->data->{oauth_return_url};
    unless ($req->{state} && $req->{code}) {
        delete $session->data->{oauth_state};
        return {
            result => "OAUTHERR",
            answer => $req->{error_description}
        };
    }
    my $service = $session->data->{oauth_state}{$req->{state}};
    return {
        result => "OAUTHERR",
        answer => 'Unknoen oauth state'
    } unless $service;
    my $oauth = PEF::Front::Oauth->new($service, $session);
    $oauth->exchange_code_to_token($req);
    my $info = $oauth->get_user_info();
    $session->data->{name}      = $info->{name};
    $session->data->{is_author} = 0;
    $session->data->{is_oauth}  = 1;
    return {
        result   => "OK",
        back_url => $back_url,
        %$info
    };
  }

=head1 DESCRIPTION

This module implements Oauth2 user authorization and gets some info
about authorized user. It loads specific Oauth2 implementor class for
given service. There're following supported services:

=over

=item B<Facebook>

=item B<GitHub>

=item B<Google>

=item B<LinkedIn>

=item B<Msn>

=item B<Paypal>

=item B<VKontakte>

=item B<Yandex>

=back

=head1 USAGE

First, you has to register your application by required services and 
get your C<client id>-s and C<client secret>-s from them. Probably
you have to register some patterns for return URLs also. 
C<Client id>-s and C<client secret>-s are configured with
B<cfg_oauth_client_id($service)> and B<cfg_oauth_client_secret($service)>.

Second, your application has to make return url which will be used by
B<Oauth2 service> to pass authorization code to your application.

Third, your server exchanges this authorization code for an access token.

Fourth, using this access token your application access desired 
information or action.

B<PEF::Front::Oauth> stores some information in user session data.

=head2 new ($auth_service, $session)

This function loads implementor class for given C<$auth_service> and
pass C<PEF::Front::Session> object to it.

=head2 authorization_server($scope, [$redirect_uri])

Returns full URL with required parameters for authorization server for
given B<scope>. B<Google>, B<LinkedIn>, B<Msn>, B<Paypal> and B<VKontakte>
services can work only when you pass them previously registered 
B<redirect uri>.

This method stores in session following keys: 
C<oauth_state>, C<oauth_redirect_uri>.

=head2 exchange_code_to_token($req)

When Oauth2 service calls your site back, your application has to 
exchange code to access token. This method stores in session C<oauth_error>
key when token exchange was not successful.

=head2 get_user_info()

This method returns some basic user information that is obtained from 
the service. It returns hash like this: 
  {
   name  => $username,
   email => $email,
   login => $login,
   avatar => [],
  }

C<avatar> is array of user pictures when service returns it.

This method stores in session following keys: 
C<oauth_info_raw> and C<oauth_info>.

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

