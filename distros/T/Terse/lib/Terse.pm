package Terse;
our $VERSION = '0.110';
use 5.006;
use strict;
use warnings;
use Plack::Request;
use Plack::Response;
use JSON;
use Scalar::Util qw/reftype/;
use Time::HiRes qw(gettimeofday);
use Want qw/want/;
use Digest::SHA;

our ($JSON, %PRIVATE);
BEGIN {
	$JSON = JSON->new->utf8->canonical(1)->allow_blessed->convert_blessed;
	%PRIVATE = (
		map { $_ => 1 } 
		qw/new run logger logInfo logError delayed_response content_type raiseError graft pretty serialize DESTROY TO_JSON AUTOLOAD/
	);
}

sub new {
	my ($pkg, %args) = @_;
       
	if (delete $args{private}) {
		for my $key (keys %args) {
			if ($key !~ m/^_/) {
	       			$args{"_$key"} = delete $args{$key};
			}
		}
	} 

	return bless \%args, $pkg;
}

sub run {
	my ($pkg, %args) = @_;

	my $j = $pkg->new(
		private => 1,
		login => 'login',
		logout => 'logout',
		auth => 'auth',
		insecure_session => 0,
		content_type => 'application/json',
		%args
	);

	$j->request = Plack::Request->new($args{plack_env});
	$j->response = $pkg->new(
		authenticated => \0,
		error => \0,
		errors => [],
	);

	if (! $j->{_application}) {
		$j->response->raiseError('No application passed to run', 500);
		return $j->_response($j->response);
	}

	$j->{_application}->build_terse($j) if $j->{_application}->can('build_terse');

	$j->{_application_has_dispatcher} = !! $j->{_application}->can('dispatch');
	$j->{_application_has_response_handler} = !! $j->{_application}->can('response_handle');
	$j->{_application_has_delayed_response_handler} = !! $j->{_application}->can('delayed_response_handle');
	
	my $content_type = $j->request->content_type;
	if ($content_type && $content_type =~ m/application\/json/) {
		$j->graft('params', $j->request->raw_body || "{}");
	} else {
		$j->params = {%{$j->request->parameters || {}}};
	}

	unless ((reftype($j->params) || "") eq 'HASH') {
		$j->response->raiseError('Invalid parameters', 400);
		return $j->_response($j->response);
	}

	$j->sid = $j->request->cookies->{sid};
	
	unless ($j->sid) {
		my $h = Digest::SHA->new(256);
		my @us = gettimeofday;
		push @us, map { $j->request->env->{$_} } grep {
			$_ =~ /^HTTP(?:_|$)/;
		} keys %{ $j->request->env };
		$h->add(@us);
		$j->sid = $h->hexdigest;
	}

	$j->sid = {
		value => $j->is_logout ? "" : $j->sid,
		path  => $j->request->uri,
		secure => !$j->{_insecure_session},
	};

	my $auth = $j->{_auth};
	my ($session) = $j->_dispatch($auth, $pkg->new());
	my $req = $j->params->req;
	$req =~ /^([a-z][0-9a-zA-Z_]{1,31})$/; $req = $1 // '';
	$req = $j->{_application}->preprocess_req($req, $j) if $j->{_application}->can('preprocess_req');
	if (!$req || !$session || $PRIVATE{$req}) {
		$j->response->raiseError('Invalid request', 400);
		return $j->_response($j->response);
	}

	$j->response->authenticated = \1;
	$j->session = $session;

	$j->sid->expires = (ref $j->session && $j->session->expires) || (time + 24 * 60 * 60) 
		if (!$j->sid->expires);

	($j->is_login, $j->is_logout) = (
		$j->{_login} eq $req,
		$j->{_logout} eq $req
	);

	my ($out) = $j->_dispatch($req); 
	
	return $j->_response($j->response) if $j->response->error;

	$j->session = $out if ( $j->is_login || $j->is_logout );

	($j->session) = $j->_dispatch($auth, $j, $j->session)  if $j->response->authenticated;

	if ((!$j->response->authenticated || !$j->session) && !($j->is_login || $j->is_logout)) {
		$j->response->raiseError('Unauthenticated during the request', 400);
		return $j->_response($j->response);
	}

	return $j->_response($j->response, $j->content_type, $j->sid);
}

sub _build_response {
	my ($self, $sid, $content, $status) = @_;
	my $res = $self->request->new_response($self->response->{status_code} ||= $status);
	$res->cookies($self->cookies) if $self->cookies;
	$res->headers($self->headers) if $self->headers;
	$res->cookies->{sid} = $sid if $sid;
	$res->content_type($content);
	return $res;
}

sub delayed_response {
	my ($self, $response, $sid, $ct, $status) = @_;
	$sid ||= $self->sid;
	$status ||= 200;
	$ct ||= 'application/json';
	return $self->{_application}->delayed_response_handle(
		$self, $response, $sid, $ct, $status
	) if $self->{_application_has_delayed_response_handler};
	$self->{_delayed_response} = sub {
		my $responder = shift;
		my $res = $self->_build_response($sid, $ct, $status);
		$res = [splice @{$res->finalize}, 0, 2];
		my $writer = $responder->($res);
		$response = eval { $response->($writer); };
		if ($@ || $self->response->error) {
			$res->[0] = $self->response->status_code || 500;
			$self->raiseError($@) if $@;
			push @{$res}, [$self->response->serialize];
			return $responder->($res);
		}
		elsif ($response) {
			$writer->write($response->serialize);
		}
		$writer->close;
	};
	return $self;
}

sub content_type { 
	$_[0]->{_content_type} = $_[1] if $_[1];
	return $_[0]->{_content_type};
}

sub _response {
	my ($self, $response_body, $sid, $ct, $status) = @_;
	return $self->{_application}->response_handle(@_) if $self->{_application_has_response_handler};
	$ct ||= 'application/json';
	my $res = $self->{_delayed_response};
	return $res if ($res); 
	$res = $self->_build_response($sid, $ct, $status);
	$res->body($response_body->serialize());
	return $res->finalize;
}

sub _dispatch {
	my ($self, $method, @params) = @_;
	my @out = $self->{_application_has_dispatcher} ? eval {
		$self->{_application}->dispatch($method, $self, @params)
	} : eval {
		unless ($self->{_application}->can($method)) {
			$self->response->raiseError('Invalid request', 400);
			return;
		}
		$self->{_application}->$method($self, @params);
	};
	if ($@) {
		$self->response->raiseError(['Error while dispatching the request', $@], 400);
		return;
	}
	return @out;
}

sub logger {
	my ($self, $logger) = @_;
	$self->{_logger} = $logger if ($logger);
	return $self->{_logger};
}

sub logError {
	my ($self, $message, $status) = @_;
	$self->{_application} 
		? $self->response->raiseError($message, $status) 
		: $self->raiseError($message, $status);
	$message = { message => $message } if (!ref $message);
	$message = $self->{_application}->_logError($message, $status)
		if ($self->{_application} && $self->{_application}->can('_logError'));
	$self->{_logger}->err($message) if $self->{_logger};
	return $self;
}

sub logInfo {
	my ($self, $message) = @_;
	$message = { message => $message } if (!ref $message);
	$message = $self->{_application}->_logInfo($message)
		if ($self->{_application} && $self->{_application}->can('_logInfo'));
	$self->{_logger}->info($message) if $self->{_logger};
}

sub raiseError {
	my ($self, $message, $code) = @_;
	return $self->response->raiseError($message, $code) if $self->{_application};
	$self->{error} = \1;
	if ((reftype($message) || '') eq 'ARRAY') {
		push @{$self->{errors}}, @{$message};
	} else {
		push @{$self->{errors}}, $message;
	}
	$self->{status_code} = $code if ($code);
	return $self;
}

sub graft {
	my ($self, $name, $json) = @_;

	$self->{$name} = eval {
		$JSON->decode($json);
	};

	return 0 if $@;

	return $self->_bless_tree($self->{$name});
}

sub pretty { $_[0]->{_pretty} = 1; $_[0]; }

sub serialize {
	my ($self, $die) = @_;
	my $pretty = !!(reftype $self eq 'HASH' && $self->{_pretty});
	my $out = eval {
		$JSON->pretty($pretty)->encode($self);
	};
	die $@ if ($@ && $die);
	return $out || $@;
}

sub _bless_tree {
	my ($self, $node) = @_;
	my $refnode = ref $node;
	return unless $refnode eq 'HASH' || $refnode eq 'ARRAY';
	bless $node, ref $self;
	if ($refnode eq 'HASH'){
		$self->_bless_tree($node->{$_}) for keys %$node;
	}
	if ($refnode eq 'ARRAY'){
		$self->_bless_tree($_) for @$node;
	}
	$node;
}

sub TO_JSON {
	my $self = shift;
	return [@$self] if reftype $self eq 'ARRAY';
	return 'cannot stringify application object' if $self->{_application};
	my $output = {};
	my $nodebug = ! $self->{_debug};
	for(keys %$self){
		my $skip;
		$skip++ if $_ =~ /^_/ && $nodebug;
		next if $skip;
		$output->{$_} = $self->{$_};
	}
	return $output;
}

sub DESTROY {}

sub AUTOLOAD : lvalue {
	my $classname =  ref $_[0];
	my $validname = '[a-zA-Z][a-zA-Z0-9_]*';
	our $AUTOLOAD =~ /^${classname}::($validname)$/;
	my $key = $1;
	die "illegal key name, must be of $validname form\n$AUTOLOAD" unless $key;
	my $miss = Want::want('REF OBJECT') ? {} : '';
	my $retval = $_[0]->{$key};
	return $retval->(@_) if (ref $retval eq 'CODE');
	my $isBool = Want::want('SCALAR BOOL') && ((reftype($retval) // '') eq 'SCALAR');
	return $$retval if $isBool;
	$_[0]->{$key} = $_[1] // $retval // $miss;
	$_[0]->_bless_tree($_[0]->{$key}) if ref $_[0]->{$key} eq 'HASH' || ref $_[0]->{$key} eq 'ARRAY';
	$_[0]->{$key};
}

1;

__END__

=head1 NAME

Terse - Lightweight Web Framework

=head1 VERSION

Version 0.110

=cut

=head1 SYNOPSIS

	package MyAPI;

	use base 'Terse';

	sub auth {
		my ($self, $t, $session) = @_;
		return 0 if $t->params->not;
		return $session;
	}

	sub hello_world {
		my ($self, $t) = @_;
	
		if ($t->params->throw_error) {
			$t->logError('throw 500 error which is also logged', 500);
			return;
		}

		$t->response->hello = "world";
	}

	sub delayed_hello_world {
		my ($self, $t) = @_;
		$t->delayed_response(sub {
			if ($t->params->throw_error) {
				$t->logError('throw 500 error which is also logged', 500);
				return;
			}

			... do something which takes a long time ...

			$t->response->hello = "world";
			return $t->response;
		});
	}

	.... MyAPI.psgi ...

	use Terse;
	use MyAPI;
	our $api = MyAPI->new();

	sub {
		my ($env) = (shift);
		Terse->run(
			plack_env => $env,
			application => $api,
			logger => Terse->new(
				info => sub { 
					say "info log line: " . $_[1]->{message};
				}, 
				err => sub { 
					say "err log line: " . $_[1]->{message}; 
				} 
			)
		);
	};

	....

	plackup MyAPI.psgi

	GET http://localhost:5000/?req=delayed_hello_world
	# {"authenticated":1,"error":false,"errors":[],"hello":"world","status_code":200}
	GET http://localhost:5000/?req=hello_world&not=1 
	# {"authenticated":0,"error":true,"errors":["Invalid request"],"status_code":400}
	GET http://localhost:5000/?req=hello_world&throw_error=1 
	# {"authenticated":1,"error":true,"errors":["throw 500 error which is also logged"],"status_code":500}

=cut

=head1 Description

Alot of the inspiration, and some code, for this module came from L<JSONP> - which is a module to quickly build JSON/JSONP web services, providing also some syntactic sugar acting a bit like a sort of DSL (domain specific language) for JSON. ( thanks Anselmo Canfora L<ACANFORA>! )

There are several key differences between Terse and L<JSONP>, the main being Terse uses Plack and not CGI. Terse also makes it simpler to provision the data which should be returned from the API (and what should not), finally it adds logging support.

=cut

=head1 Methods

=cut

=head2 new

Instantiate a new Terse object.

	my $object = Terse->new(%params);

=cut

=head2 run

Run terse as a plack application.

	Terse->run(
		login => 'login',
		logout => 'logout',
		auth => 'auth',
		insecure_session => 0,
		application => Terse->new(
			auth => sub { ... },
			login => sub { ... },
			logout => sub { ... }
		),
		plack_env => $env
	);

The "application" does not need to be a "Terse application", the only requirment is it implements the auth, login and logout methods (go crazy!).

=cut

=head2 params

Retrieve params for the request.

	$terse->params;

=cut

=head2 request

Returns the Plack::Request.

	$terse->request;

=cut


=head2 session

Retrieve current session data, set in your auth or login methods

	$terse->session;

=cut

=head2 response

Set the response body data.

	$terse->response->foo = { ... };

=cut

=head2 logger

Set or Retrieve the logger for the application.

	$terse->logger($logger);
	$terse->logger->info();
	$terse->logger->err();

=cut

=head2 logError

Log and raise an error message.

	$terse->logError('this is an error message', 404);

=cut

=head2 logInfo

Log an info message.

	$terse->logInfo('this an info message');

=cut

=head2 raiseError

Raise an error message.

	$terse->raiseError('this is an error message', 404);

=cut

=head2 graft

Decode a JSON string.

	$terse->response->graft('config', "{...}");

=cut

=head2 pretty

Set JSON to pretty print mode.

	$terse->pretty(1);

=cut

=head2 serialize

Encode a perl struct as a JSON string.

	$terse->serialize({ ... });

=cut

=head2 delayed_response

Delay the response for non-blocking I/O based server streaming or long-poll Comet push technology.

	$terse->delayed_response(sub {
		$terse->response->test = 'okay';
		return $terse->response;
	});

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-terse at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Terse>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Terse


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Terse>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Terse>

=item * Search CPAN

L<https://metacpan.org/release/Terse>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Terse
