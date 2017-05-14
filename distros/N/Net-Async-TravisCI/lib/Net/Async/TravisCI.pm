package Net::Async::TravisCI;
# ABSTRACT: API support for travis-ci.com and travis-ci.org

use strict;
use warnings;

our $VERSION = '0.002';

use parent qw(IO::Async::Notifier);

=head1 NAME

Net::Async::TravisCI - interact with the Travis CI API

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Does things to Travis. Terrible, nasty things, most of which are sadly not yet documented.

=cut

no indirect;

use Future;
use Dir::Self;
use URI;
use URI::Template;
use JSON::MaybeXS;
use Syntax::Keyword::Try;

use File::ShareDir ();
use Log::Any qw($log);
use Path::Tiny ();

use Net::Async::Pusher;

use Net::Async::TravisCI::Account;
use Net::Async::TravisCI::Annotation;
use Net::Async::TravisCI::Branch;
use Net::Async::TravisCI::Commit;
use Net::Async::TravisCI::Config;
use Net::Async::TravisCI::Job;
use Net::Async::TravisCI::Build;

my $json = JSON::MaybeXS->new;

=head2 configure

Applies configuration, which at the moment would involve zero or more of the following
named parameters:

=over 4

=item * token - a L<TravisCI token|https://blog.travis-ci.com/2013-01-28-token-token-token>

=back

=cut

sub configure {
	my ($self, %args) = @_;
	for my $k (grep exists $args{$_}, qw(token)) {
		$self->{$k} = delete $args{$k};
	}
	$self->SUPER::configure(%args);
}

=head2 endpoints

Returns the hashref of API endpoints, loading them on first call from the C<share/endpoints.json> file.

=cut

sub endpoints {
	my ($self) = @_;
	$self->{endpoints} ||= do {
        my $path = Path::Tiny::path(__DIR__)->parent(3)->child('share/endpoints.json');
        $path = Path::Tiny::path(
            File::ShareDir::dist_file(
                'Net-Async-TravisCI',
                'endpoints.json'
            )
        ) unless $path->exists;
        $json->decode($path->slurp_utf8)
    };
}

=head2 endpoint

Processes the given endpoint as a template, using the named parameters
passed to the method.

=cut

sub endpoint {
	my ($self, $endpoint, %args) = @_;
	URI::Template->new($self->endpoints->{$endpoint . '_url'})->process(%args);
}

=head2 http

Returns the HTTP instance used for communicating with Travis.

Currently autocreates a L<Net::Async::HTTP> instance.

=cut

sub http {
	my ($self) = @_;
	$self->{http} ||= do {
		require Net::Async::HTTP;
		$self->add_child(
			my $ua = Net::Async::HTTP->new(
				fail_on_error            => 1,
				max_connections_per_host => 2,
				pipeline                 => 1,
				max_in_flight            => 8,
				decode_content           => 1,
				timeout                  => 30,
				user_agent               => 'Mozilla/4.0 (perl; https://metacpan.org/pod/Net::Async::TravisCI; TEAM@cpan.org)',
			)
		);
		$ua
	}
}

=head2 auth_info

Returns authentication info as parameters suitable for the L</http> methods.

=cut

sub auth_info {
	my ($self) = @_;
	if(my $key = $self->api_key) {
		return (
			user => $self->api_key,
			pass => '',
		);
	} elsif(my $token = $self->token) {
		return (
			headers => {
				Authorization => 'token "' . $token . '"'
			}
		)
	}
	return;
}

=head2 api_key

Github API key.

=cut

sub api_key { shift->{api_key} }

=head2 token

Travis token.

=cut

sub token { shift->{token} }

=head2 mime_type

MIME type to use for requests. Hardcoded default to C<travis-ci.2+json>.

=cut

sub mime_type { shift->{mime_type} //= 'application/vnd.travis-ci.2+json' }

=head2 base_uri

Base URI for Travis requests.

Hardcoded to the B<private> Travis CI server, L<https://api.travis-ci.com>.

=cut

sub base_uri { shift->{base_uri} //= URI->new('https://api.travis-ci.com') }

=head2 http_get

Issues an HTTP GET request.

=cut

sub http_get {
	my ($self, %args) = @_;
	my %auth = $self->auth_info;

	if(my $hdr = delete $auth{headers}) {
		$args{headers}{$_} //= $hdr->{$_} for keys %$hdr
	}
	$args{headers}{Accept} //= $self->mime_type;
	$args{$_} //= $auth{$_} for keys %auth;

    my $uri = delete $args{uri};
	$log->tracef("GET %s { %s }", "$uri", \%args);
    $self->http->GET(
        $uri,
		%args
    )->then(sub {
        my ($resp) = @_;
        return { } if $resp->code == 204;
        return { } if 3 == ($resp->code / 100);
        try {
			$log->tracef('HTTP response for %s was %s', "$uri", $resp->as_string("\n"));
            return Future->done($json->decode($resp->decoded_content))
        } catch {
            $log->errorf("JSON decoding error %s from HTTP response %s", $@, $resp->as_string("\n"));
            return Future->fail($@ => json => $resp);
        }
    })->else(sub {
        my ($err, $src, $resp, $req) = @_;
        $src //= '';
        if($src eq 'http') {
            $log->errorf("HTTP error %s, request was %s with response %s", $err, $req->as_string("\n"), $resp->as_string("\n"));
        } else {
            $log->errorf("Other failure (%s): %s", $src // 'unknown', $err);
        }
        Future->fail(@_);
    })
}

=head2 http_post

Performs an HTTP POST request.

=cut

sub http_post {
	my ($self, %args) = @_;
	my %auth = $self->auth_info;

	if(my $hdr = delete $auth{headers}) {
		$args{headers}{$_} //= $hdr->{$_} for keys %$hdr
	}
	$args{headers}{Accept} //= $self->mime_type;
	$args{$_} //= $auth{$_} for keys %auth;

	my $content = delete $args{content};
	$content = $json->encode($content) if ref $content;

	$log->tracef("POST %s { %s }", ''. $args{uri}, $content, \%args);
    $self->http->POST(
        (delete $args{uri}),
		$content,
		content_type => 'application/json',
		%args
    )->then(sub {
        my ($resp) = @_;
        return Future->done({ }) if $resp->code == 204;
        return Future->done({ }) if 3 == ($resp->code / 100);
        try {
			warn "have " . $resp->as_string("\n");
            return Future->done($json->decode($resp->decoded_content))
        } catch {
            $log->errorf("JSON decoding error %s from HTTP response %s", $@, $resp->as_string("\n"));
            return Future->fail($@ => json => $resp);
        }
    })->else(sub {
        my ($err, $src, $resp, $req) = @_;
        $src //= '';
        if($src eq 'http') {
            $log->errorf("HTTP error %s, request was %s with response %s", $err, $req->as_string("\n"), $resp->as_string("\n"));
        } else {
            $log->errorf("Other failure (%s): %s", $src // 'unknown', $err);
        }
        Future->fail(@_);
    })
}

=head2 github_token

Sets the github token.

=cut

sub github_token {
	my ($self, %args) = @_;
	$self->http_post(
		uri => URI->new($self->base_uri . '/auth/github'),
		content => {
			github_token => delete $args{token}
		}
	)->transform(
		done => sub { shift->{access_token} },
	)
}

=head2 accounts

Retrieves accounts.

=cut

sub accounts {
	my ($self, %args) = @_;
	$self->http_get(
		uri => URI->new($self->base_uri . '/accounts'),
	)->transform(
		done => sub { map Net::Async::TravisCI::Account->new(%$_), @{ shift->{accounts} } },
	)
}

=head2 users

Retrieves users.

=cut

sub users {
	my ($self, %args) = @_;
	$self->http_get(
		uri => URI->new($self->base_uri . '/users'),
#	)->transform(
#		done => sub { map Net::Async::TravisCI::Account->new(%$_), @{ shift->{accounts} } },
	)
}

=head2 jobs

Retrieves jobs.

=cut

sub jobs {
	my ($self, %args) = @_;
	$self->http_get(
		uri => URI->new($self->base_uri . '/jobs'),
	)->transform(
		done => sub { map Net::Async::TravisCI::Job->new(%$_), @{ shift->{jobs} } },
	)
}

=head2 cancel_job

Cancels a specific job by ID.

=cut

sub cancel_job {
	my ($self, $job, %args) = @_;
	$self->http_post(
		uri => URI->new($self->base_uri . '/jobs/' . $job->id . '/cancel'),
		content => { },
	)->transform(
		done => sub { },
	)
}

=head2 pusher_auth

Deals with pusher auth, used for tailing logs.

=cut

sub pusher_auth {
	my ($self, %args) = @_;
	$self->pusher->then(sub {
		my ($conn) = @_;
		$conn->connected->then(sub {
			$log->tracef("Pusher socket ID is %s", $conn->socket_id);
			Future->done($conn->socket_id)
		})
	})->then(sub {
		$args{socket_id} = shift or die "need a socket ID";
		$self->http_post(
			uri => URI->new($self->base_uri . '/pusher/auth'),
			content => \%args
		)
	})->transform(done => sub {
		shift->{channels}
	})
}

=head2 pusher

Handles the pusher instance.

=cut

sub pusher {
	my ($self) = @_;
	$self->{pusher} //= $self->config->then(sub {
		my $key = shift->pusher->{key};
		$self->add_child(
			my $pusher = Net::Async::Pusher->new
		);
		$pusher->connect(
			key => $key,
		)
	});
}

=head2 config

Applies Travis config.

=cut

sub config {
	my ($self, %args) = @_;
	$self->{config} //= $self->http_get(
		uri => URI->new($self->base_uri . '/config'),
	)->transform(
		done => sub { map Net::Async::TravisCI::Config->new(%$_), shift->{config} },
	)
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2015-2017. Licensed under the same terms as Perl itself.
