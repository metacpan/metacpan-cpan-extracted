package Stance::Vault;
use strict;
use warnings;

our $VERSION = "1.0.0";

use LWP::UserAgent qw//;
use JSON           qw//;
use HTTP::Request  qw//;

sub from_json {
	JSON->new->utf8->decode(@_);
}
sub to_json {
	JSON->new->utf8->encode(@_);
}

sub new {
	my ($class, $vault_addr) = @_;
	$vault_addr ||= $ENV{VAULT_ADDR};
	$vault_addr ||= "http://127.0.0.1:8200";
	$vault_addr =~ s|/$||;

	bless {
		 ua    => LWP::UserAgent->new(agent => __PACKAGE__.'/'.$VERSION),
		 vault => $vault_addr,
		_debug => $ENV{STANCE_VAULT_DEBUG} && $ENV{STANCE_VAULT_DEBUG} eq 'on',
		_error => undef,
	}, $class;
}

sub debug {
	my ($self, $on) = @_;
	$self->{_debug} = !!$on;
}

sub url {
	my ($self, $rel) = @_;
	$rel ||= '/';
	$rel =~ s|^/||;

	return "$self->{vault}/$rel";
}

sub get {
	my ($self, $url) = @_;

	my $req = HTTP::Request->new(GET => $self->url($url))
		or die "unable to create GET $url request: $!\n";
	$req->header('Accept' => 'application/json');
	$req->header('X-Vault-Token', '[REDACTED]')
		if $self->{_token};
	if ($self->{_debug}) {
		print STDERR "=====[ GET $url ]========================\n";
		print STDERR $req->as_string;
		print STDERR "\n\n";
	}
	$req->header('X-Vault-Token', $self->{_token})
		if $self->{_token};

	my $res = $self->{ua}->request($req)
		or die "unable to send GET $url request: $!\n";
	if ($self->{_debug}) {
		print STDERR "-----------------------------------------\n";
		print STDERR $res->as_string;
		print STDERR "\n\n";
	}

	my $body = from_json($res->decoded_content);
	if (!$res->is_success) {
		$self->{_error} = $body;
		return undef;
	}
	return $body;
}

sub post {
	my ($self, $url, $payload) = @_;

	my $req = HTTP::Request->new(POST => $self->url($url))
		or die "unable to create POST $url request: $!\n";
	$req->header('Accept' => 'application/json');
	$req->header('Content-Type', 'application/json');
	$req->header('X-Vault-Token', '[REDACTED]')
		if $self->{_token};
	$req->content(to_json($payload)) if $payload;
	if ($self->{_debug}) {
		print STDERR "=====[ POST $url ]========================\n";
		print STDERR $req->as_string;
		print STDERR "\n\n";
	}
	$req->header('X-Vault-Token', $self->{_token})
		if $self->{_token};

	my $res = $self->{ua}->request($req)
		or die "unable to send POST $url request: $!\n";
	if ($self->{_debug}) {
		print STDERR "-----------------------------------------\n";
		print STDERR $res->as_string;
		print STDERR "\n\n";
	}

	my $body = from_json($res->decoded_content);
	if (!$res->is_success) {
		$self->{_error} = $body;
		return undef;
	}
	return $body;
}

sub last_error {
	my ($self) = @_;
	return $self->{_error};
}

sub authenticate {
	my ($self, $method, $creds) = @_;

	if ($method eq 'token') {
		$self->{_token} = $creds;
		return $self;
	}

	if ($method eq 'app_role') {
		my ($ok, $token) = $self->post('/v1/auth/approle/login', {
			role_id   => $creds->{role_id},
			secret_id => $creds->{secret_id},
		});
		if (!$ok) {
			return undef;
		}

		$self->{_token} = $token->{auth}{client_token};
		$self->{_renew} = $token->{auth}{lease_duration};

		my $pid = fork;
		if ($pid) {
			$self->{pid} = $pid;
			return $self;
		}

		# in child process...
		$self->renew();
	}

	die "unrecognized authentication method '$method'!";
}

sub renew {
	my ($self) = @_;
	while ($self->{_renew}) {
		$self->{_renew} /= 2;
		sleep($self->{_renew});

		my ($ok, $renewal) = $self->post('/v1/auth/token/renew-self', {});
		if ($ok) {
			$self->{_renew} = $renewal->{auth}{lease_duration};
		}
	}
}

sub kv_set {
	my ($self, $path, $data) = @_;
	$path =~ s|^/||;
	return $self->post("/v1/secret/data/$path", {
		options => {
			cas => 0,
		},
		data => $data
	});
}

sub kv_get {
	my ($self, $path) = @_;
	$path =~ s|^/||;
	return $self->get("/v1/secret/data/$path");
}

=head1 NAME

Stance::Vault - A Perl Interface to Hashicorp Vault

=head1 DESCRIPTION

C<Stance::GitHub> provides an object-oriented interface to the Hashicorp Vault API.

=end

1;
