package POE::XUL::SessionManager;

use strict;
use warnings;
use Carp;
use Digest::MD5 qw(md5_base64);
use POE::XUL::Session;

use base 'Exporter';

our @EXPORT = qw(BOOT_REQUEST_TYPE EVENT_REQUEST_TYPE);

use constant {
	BOOT_REQUEST_TYPE  => 'boot',
	EVENT_REQUEST_TYPE => 'event',
};

# public ----------------------------------------------------------------------

sub new {
	my $class = shift;
	my $self = bless({
		sessions => {},
		@_,
	}, $class);
	return $self;
}

sub handle_request {
	my ($self, $request) = @_;
	my $type = delete $request->{type} || croak "no request type";
	my $method = 'handle_request_'.(
		$type eq BOOT_REQUEST_TYPE ? 'boot' :
		$type eq EVENT_REQUEST_TYPE? 'event':
		croak "unknown request type: $type"
	);
	return $self->$method($request);
}

sub timeout_session {
	my ($self, $session_id) = @_;
	my $session = $self->get_session($session_id) ||
		croak "session not found: [$session_id]";
	$session->destroy;
	delete $self->sessions->{$session_id};
}

# request handling ------------------------------------------------------------

sub handle_request_boot {
	my ($self, $request) = @_;
	my $session = POE::XUL::Session->new(apps => $self->{apps});
	my $session_id = $self->make_session_id;
	$request->{session} = $session_id;
	# we 1st boot, so in case of error session is not registered
	my $response = "$session_id\n". $session->handle_boot($request);
	# now we can register session
	$self->sessions->{$session_id} = $session;
	return $response;
}

sub handle_request_event {
	my ($self, $request) = @_;
	my $session_id = $request->{session} || croak "no session ID";
	my $session = $self->get_session($session_id) ||
		croak "session not found: [$session_id]";
	return $session->handle_event($request,$self);
}

# private ---------------------------------------------------------------------

# stolen from CGI::Session::ID::MD5
sub make_session_id {
	my $self = shift;
	my $id = md5_base64($$, time, rand(9999));
	return $id;
}

sub sessions    { shift->{sessions} }
sub get_session { shift->sessions->{pop()} }

1;

