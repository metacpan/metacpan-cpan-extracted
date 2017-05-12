package Net::VKontakte::Standalone;

use 5.008000;
use strict;
use warnings;

use URI;
use WWW::Mechanize;
use JSON;
use Carp;

our $VERSION = '0.11';

sub new {
	my $class = shift;
	my $self = bless {},$class;
	$self->{browser} =  WWW::Mechanize::->new(
		agent => __PACKAGE__.$VERSION,
		autocheck => 1,
	);
	if (@_ == 1) {
		$self->{api_id} = $_[0];
	} elsif (@_ % 2 == 0) { # smells like hash
		my %opt = @_;
		for my $key (qw/api_id errors_noauto captcha_handler/) {
			$self->{$key} = $opt{$key} if defined $opt{$key};
		}
	} else {
		croak "wrong number of arguments to constructor";
	}
	croak "api_id is required" unless $self->{api_id};
	return $self;
}

sub _request {
	my ($self, $params, $base) = @_;
	(my $uri = URI::->new($base))->query_form($params);
	return $self->{browser}->get($uri);
}

sub auth { # dirty hack
	my ($self,$login,$password,$scope) = @_;
	@{$self}{"login","password","scope"} = ($login, $password, $scope); # reuse in case of reauth
	$self->{browser}->get($self->auth_uri($scope));
	$self->{browser}->submit_form(
		with_fields => {
			email => $login,
			pass => $password,
		},
	); # log in
	$self->{browser}->submit unless $self->{browser}->uri =~ m|^https://oauth.vk.com/blank.html|; # allow access if requested to
	return $self->redirected($self->{browser}->uri);
}

sub auth_uri {
	my ($self, $scope, $display) = @_;
	(my $uri = URI::->new("https://api.vkontakte.ru/oauth/authorize"))->query_form(
		{
			client_id => $self->{api_id},
			redirect_uri => "blank.html",
			scope => $scope,
			response_type => "token",
			display => $display,
		}
	);
	return $uri->canonical;
}

sub redirected {
	my ($self, $uri) = @_;
	my %params = map { split /=/,$_,2 } split /&/,$1 if $uri =~ m|https://oauth.vk.com/blank.html#(.*)|;
	croak "No access_token returned (wrong login/password?)" unless defined $params{access_token};
	$self->{access_token} = $params{access_token};
	croak "No token expiration time returned" unless $params{expires_in};
	$self->{auth_time} = time;
	$self->{expires_in} = $params{expires_in};
	return $self;
}


sub api {
	my ($self,$method,$params) = @_;
	croak "Cannot make API calls unless authentificated" unless defined $self->{access_token};
	if (time - $self->{auth_time} > $self->{expires_in}) {
		if ($self->{login} && $self->{password} && $self->{scope}) {
			$self->auth($self->{"login","password","scope"});
		} else {
			if ($self->{errors_noauto}) {
				$self->{error} = "access_token expired";
					if (ref $self->{errors_noauto} and ref $self->{errors_noauto} eq "CODE") {
						$self->{errors_noauto}->({error_code => "none", error_msg => "access_token expired"});
					}
				return;
			} else {
				croak "access_token expired";
			}
		}
	}
	$params->{access_token} = $self->{access_token};
	REQUEST: {
		my $response = decode_json $self->_request($params,"https://api.vk.com/method/$method")->decoded_content;
		if ($response->{response}) {
			return $response->{response};
		} elsif ($response->{error}) {
			if ($self->{errors_noauto}) {
				$self->{error} = $response->{error};
				if (ref $self->{errors_noauto} and ref $self->{errors_noauto} eq "CODE") {
					$self->{errors_noauto}->($response->{error});
				}
				return;
			} else {
				if (6 == $response->{error}{error_code}) { # Too many requests per second. 
					sleep 1;
					redo REQUEST;
				} elsif (14 == $response->{error}{error_code}) { # Captcha is needed
					if ($self->{captcha_handler}) {
						$params->{captcha_key} = $self->{captcha_handler}->($response->{error}{captcha_img});
						$params->{captcha_sid} = $response->{error}{captcha_sid};
						redo REQUEST;
					} else {
						croak "Captcha is needed and no captcha handler specified";
					}
				} else {
					croak "API call returned error ".$response->{error}{error_msg};
				}
			}
		} else {
			croak "API call didn't return response or error".
				$Carp::Verbose ? eval { require Data::Dumper; Data::Dumper::Dumper($response) }
				: "";
		}
	}
}

sub captcha_handler {
	my ($self, $handler) = @_;
	croak "\$handler is not a subroutine reference" unless ref $handler eq "CODE";
	$self->{captcha_handler} = $handler;
	return $self;
}

sub error {
	return shift->{error};
}

sub errors_noauto {
	my ($self, $noauto) = @_;
	$self->{errors_noauto} = $noauto; # whatever this means
	return $self;
}

1;
__END__

=head1 NAME

Net::VKontakte::Standalone - Perl extension for creating standalone Vkontakte API applications

=head1 SYNOPSIS

  use Net::VKontakte::Standalone;
  my $vk = new Net::VKontakte::Standalone:: "12345678";
  my $auth_uri = $vk->auth_uri("wall,messages");

  # make the user able to enter login and password at this URI
  
  $vk->redirected($where);
  $vk->api("activity.set",{text => "playing with VK API"});


=head1 DESCRIPTION

This module is just a wrapper for some JSON parsing and WWW::Mechanize magic, not much else.

=head1 CONSTRUCTOR METHODS

=over 4

=item $vk = Net::VKontakte::Standalone::->new($api_id);

=item $vk = Net::Vkontalte::Standalone::->new( key => value );

This creates the main object, sets the API ID variable (which can be got from the application
management page) and creates the WWW::Mechanize object.

Possible keys:

=over 8

=item api_id

API ID of the application, required.

=item errors_noauto

If true, return undef instead of automatic error handling (which includes limiting requests per second, asking for captcha and throwing exceptions). If this is a coderef, it will be called with the {error} subhash as the only argument. In both cases the error will be stored and will be accessible via $vk->error method.

=item captcha_handler

Should be a coderef to be called upon receiving {error} requiring CAPTCHA. The coderef will be called with the CAPTCHA URL as the only argument and should return the captcha answer (decoded to characters if needed). Works only when errors_noauto is false.

=back

=back 

=head1 METHODS

=begin comment

=item $vk->auth($login,$password,$scope)

This method should be called first. It uses OAuth2 to authentificate the user at the vk.com server
and accepts the specified scope (seen at L<https://vk.com/developers.php?oid=-17680044&p=Application_Access_Rights>).
After obtaining the access token is saved for future use.

=end comment

=over

=item $vk->auth_uri($scope)

This method should be called first. It returns the URI of the login page to show to the user
(developer should call a browser somehow, see L<https://vk.com/developers.php?oid=-17680044&p=Authorizing_Client_Applications>
for more info).

=item $vk->redirected($uri)

This method should be called after a successful authorisation with the URI user was redirected
to. Then the expiration time and the access token are retreived from this URI and stored in
the $vk object.

=item $vk->api($method,{parameter => "value", parameter => "value" ...})

This method calls the API methods on the server, as described on L<https://vk.com/developers.php?oid=-17680044&p=Making_Requests_to_API>.
Resulting JSON is parsed and returned as a hash reference.

=item $vk->captcha_handler($sub)

Sets the sub to call when CAPTCHA needs to be entered. Works only when errors_noauto is false.

=item $vk->error

Returns the last {error} subhash received (if errors_nonfatal is true).

=item $vk->errors_noauto

If true, return undef instead of automatic handling API error. If this is a coderef, it will be called with the {error} subhash as the only argument. In both cases the error will be stored and will be accessible via $vk->error method.

=back 

=head1 BUGS

Probably many. Feel free to report my mistakes and propose changes.

Currently there is no test suite.

=head1 SEE ALSO

L<https://vk.com/developers.php> for the list of methods and how to use them.

=head1 AUTHOR

Krylov Ivan, E<lt>krylov.r00t@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Krylov Ivan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
