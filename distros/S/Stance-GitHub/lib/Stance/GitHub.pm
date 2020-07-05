package Stance::GitHub;
use strict;
use warnings;

our $VERSION = "1.0.0";

use LWP::UserAgent qw//;
use JSON           qw//;
use HTTP::Request  qw//;

use Stance::GitHub::Organization;

sub from_json {
	JSON->new->utf8->decode(@_);
}
sub to_json {
	JSON->new->utf8->encode(@_);
}

sub new {
	my ($class, $github_addr) = @_;
	$github_addr ||= "https://api.github.com";
	$github_addr =~ s|/$||;

	bless {
		 ua     => LWP::UserAgent->new(agent => __PACKAGE__.'/'.$VERSION),
		 github => $github_addr,
		_debug  => $ENV{STANCE_GITHUB_DEBUG} && $ENV{STANCE_GITHUB_DEBUG} eq 'on',
		_error  => undef,
	}, $class;
}

sub debug {
	my ($self, $on) = @_;
	$self->{_debug} = !!$on;
}

sub url {
	my ($self, $rel) = @_;
	if ($rel && $rel =~ m/^https?:/) {
		$rel =~ s/\{.*?\}//g; # remove any leftover templating
		return $rel; # is absolute, probably from a GH response...
	}

	$rel ||= '/';
	$rel =~ s|^/||;

	return "$self->{github}/$rel";
}

sub get {
	my ($self, $url) = @_;

	my $req = HTTP::Request->new(GET => $self->url($url))
		or die "unable to create GET $url request: $!\n";
	$req->header('Accept' => 'application/json');
	$req->header('Authorization', 'token [REDACTED]')
		if $self->{_token};
	if ($self->{_debug}) {
		print STDERR "=====[ GET $url ]========================\n";
		print STDERR $req->as_string;
		print STDERR "\n\n";
	}
	$req->header('Authorization', 'token '.$self->{_token})
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
	$req->header('Authorization', 'token [REDACTED]')
		if $self->{_token};
	$req->content(to_json($payload)) if $payload;
	if ($self->{_debug}) {
		print STDERR "=====[ POST $url ]========================\n";
		print STDERR $req->as_string;
		print STDERR "\n\n";
	}
	$req->header('Authorization', 'token '.$self->{_token})
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

	die "unrecognized authentication method '$method'!";
}

sub orgs {
	my ($self) = @_;
	return map { Stance::GitHub::Organization->new($self, $_) } @{ $self->get('/user/orgs') };
}

=head1 NAME

Stance::GitHub - A Perl Interface to GitHub

=head1 DESCRIPTION

C<Stance::GitHub> provides an object-oriented interface to the GitHub v3 API.

=end

1;
