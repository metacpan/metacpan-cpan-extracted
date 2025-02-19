package Terse::Plugin::UA;
use 5.006; use strict; use warnings;
our $VERSION = '0.03';
use base 'Terse::Plugin';
use LWP::UserAgent; use URI; use Scalar::Util qw/reftype/;

sub connect {
	my ($self, $t) = @_;
	my $connect = $self->SUPER::new();
	$connect->ua = LWP::UserAgent->new(ssl_opts => {verify_hostname => 0});
	$connect->ua->cookie_jar({});
	$connect->context = $t;
	return $connect;
}

sub post {
	my $self  = shift;
	$self->_request(
		method => 'post',
		'Content-Type' => 'application/json',
		Accept => 'application/json',
		@_
	);
}

sub get {
	my $self = shift;
	$self->_request(
		method => 'get',
		'Content-Type' => 'application/x-www-form-urlencoded;charset=utf-8',
		Accept => 'application/json',
		@_
	);
}

sub _request {
	my ($self, %args) = @_;
	$self->request_cb(\%args) if $self->can('request_cb');
	my $request_parameters = delete $args{params} // {};
	if ($self->context->{session} && $self->context->session->{user}) {
		$request_parameters->{userName} = $self->context->session->user->userName;
		$request_parameters->{hashedUserName} = $self->context->session->user->hashedUserName;
	}
	my $url = URI->new(delete $args{path});
	my $method = delete $args{method};
	my $view = $args{view} && $self->context->view(delete $args{view});
	if ($self->can('params_cb')) {
		$self->req_params = $request_parameters = $self->params_cb($request_parameters,\%args, $view);
	} elsif ($view) {
		$self->req_params = $request_parameters = $view->render($self->context, $request_parameters);
	} else {
		$self->req_params = $request_parameters;
		$request_parameters = $self->req_params->serialize();
	}
	my @args;
	if ($method =~ m/get/i) {
		$url->query_form(%{$self->req_params});
		@args = ( 
			$url,
			%args,
		);
	} else {
		@args = (
			$url,
			%args,
			Content => $request_parameters
		);
	}
	my $res = $self->ua->$method(@args);
	$res->{uri} = $url;
	$self->_parse_response($res, $view);
}

sub _parse_response {
	my ($self, $res, $view) = @_;
	unless ($res->is_success) {
		my $response = eval { $self->graft('response', $res->decoded_content) };
		return $self->_return_error($@ ? undef : $response, $res, $res->code());
	}
	if ($self->can('response_cb')) {
		return $self->response_cb($res);
	} elsif ($view && $view->can('parse')) {
		return $view->parse($self->context, $res);
	} elsif ($res->content_type eq 'application/json') {
		my $response = $self->graft('response', $res->decoded_content);
		return $self->_return_error('Invalid JSON content returned', $res) if !$response;
		return $response
	}
	return $self->_return_error('Invalid UA call', $res);
}

sub _return_error {
	my ($self, $error, $res, $status) = @_;
	$status ||= 500;
	if ($self->can('error_cb')) {
		return $self->error_cb($error, $res, $status);
	}
	$self->context->logError($error || 'PAYMENT API call failed', 500);
	return;
}

1;

__END__

=head1 NAME

Terse::Plugin::UA - Terse LWP::UserAgent plugin.

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	package MyApp::Plugin::UA;

	use base 'Terse::Plugin::UA';

	1;

	...

	package MyApp::Model::Orange;

	use base 'Terse::Model';

	sub one {
		my ($self, $t, $params) = @_;

		return $t->plugin('ua')->post(
			path => $t->plugin('config')->find('path/to/url'),
			params => $params
		);
	}

	sub two {
		my ($self, $t, $params) = @_;

		return $t->plugin('ua')->get(
			path => $t->plugin('config')->find('path/to/other/url'),
			params => $params
		);
	}

	1;

	...

	package MyApp::Controller::Orange;
	
	use base 'Terse::Controller';

	sub demo {
		my ($self, $t) = @_;	

		my $secret_teller = $t->model('orange')->one({
			...
		});
	}

	1;


=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-terse-plugin-ua at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Terse-Plugin-UA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Terse::Plugin::UA

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Terse-Plugin-UA>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Terse-Plugin-UA>

=item * Search CPAN

L<https://metacpan.org/release/Terse-Plugin-UA>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Terse::Plugin::UA
