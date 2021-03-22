package Net::Async::Github;

use strict;
use warnings;

our $VERSION = '0.009';
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use parent qw(IO::Async::Notifier);

no indirect;
use utf8;

=encoding utf8

=head1 NAME

Net::Async::Github - support for the L<https://github.com> REST API with L<IO::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::Github;
 my $loop = IO::Async::Loop->new;
 $loop->add(
  my $gh = Net::Async::Github->new(
   token => '...',
  )
 );
 # Give 'secret_team' pull access to all private repos
 $gh->repos(visibility => 'private')
    ->grant_team(secret_team => 'pull')
    ->await;

=head1 DESCRIPTION

This is a basic wrapper for Github's API.

=cut

no indirect;

use Future;
use Dir::Self;
use Path::Tiny;
use File::ShareDir;
use URI;
use URI::QueryParam;
use URI::Template;
use JSON::MaybeXS;
use Time::Moment;
use Syntax::Keyword::Try;

use Cache::LRU;

use Ryu::Async;
use Ryu::Observable;
use Net::Async::WebSocket::Client;

use Log::Any qw($log);

use Net::Async::Github::Branch;
use Net::Async::Github::User;
use Net::Async::Github::Team;
use Net::Async::Github::Plan;
use Net::Async::Github::PullRequest;
use Net::Async::Github::Repository;
use Net::Async::Github::RateLimit;

my $json = JSON::MaybeXS->new;

=head1 METHODS

=head2 current_user

Returns information about the current user.

 my $user = $gh->current_user->get;
 printf "User [%s] has %d public repos and was last updated on %s%s\n",
  $user->login, $user->public_repos, $user->updated_at->to_string

Resolves to a L<Net::Async::Github::User> instance.

=cut

sub current_user {
    my ($self, %args) = @_;
    $self->validate_args(%args);
    $self->http_get(
        uri => $self->endpoint('current_user')
    )->transform(
        done => sub {
            Net::Async::Github::User->new(
                %{$_[0]},
                github => $self,
            )
        }
    )
}

=head2 configure

Accepts the following optional named parameters:

=over 4

=item * C<token> - the Github API token

=item * C<endpoints> - hashref of L<RFC6570|https://tools.ietf.org/html/rfc6570>-compliant URL mappings

=item * C<http> - an HTTP client compatible with the L<Net::Async::HTTP> API

=item * C<mime_type> - the MIME type to use as the C<Accept> header for requests

=item * C<page_cache_size> - number of GET responses to cache. Defaults to 1000, set to 0 to disable.

=item * C<timeout> - How long in seconds to wait before giving up on a request. Defaults to 60. If set to 0, then no timeout will take place.

=back

B< You probably just want C<token> >, defaults should be fine for the
other settings.

If you're creating a large number of instances, you can avoid
some disk access overhead by passing C<endpoints> from an existing
instance to the constructor for a new instance.

=cut

sub configure {
    my ($self, %args) = @_;
    for my $k (grep exists $args{$_}, qw(token endpoints api_key http base_uri mime_type page_cache_size timeout)) {
        $self->{$k} = delete $args{$k};
    }
    $self->SUPER::configure(%args);
}

=head2 reopen

Reopens the given PR.

Expects the following named parameters:

=over 4

=item * owner - which user or organisation owns this PR

=item * repo - which repo it's for

=item * id - the pull request ID

=back

Resolves to the current status.

=cut

sub reopen {
    my ($self, %args) = @_;
    die "needs $_" for grep !$args{$_}, qw(owner repo id);
    $self->validate_args(%args);
    my $uri = URI->new($self->base_uri);
    $uri->path(
        join '/', 'repos', $args{owner}, $args{repo}, 'pulls', $args{id}
    );
    $self->http_patch(
        uri => $uri,
        data => {
            state => 'open',
        },
    )
}

=head2 pull_request

Returns information about the given PR.

Expects the following named parameters:

=over 4

=item * owner - which user or organisation owns this PR

=item * repo - which repo it's for

=item * id - the pull request ID

=back

Resolves to the current status.

=cut

sub pull_request {
    my ($self, %args) = @_;
    die "needs $_" for grep !$args{$_}, qw(owner repo id);
    $self->validate_args(%args);
    my $uri = $self->base_uri;
    $uri->path(
        join '/', 'repos', $args{owner}, $args{repo}, 'pulls', $args{id}
    );
    $log->tracef('Check Github pull request via URI %s', "$uri");
    $self->http_get(
        uri => $uri,
    )->transform(
        done => sub {
            $log->tracef('Github PR data was ', $_[0]);
            Net::Async::Github::PullRequest->new(
                %{$_[0]},
                github => $self,
            )
        }
    )
}

# Provide an alias for anyone relying on previous name
*pr = *pull_request;

=head2 pull_requests

Returns information of all PRs of given repository.

Expects the following named parameters:

=over 4

=item * C<owner> - which user or organisation owns this PR

=item * C<repo> - the repository this pull request is for

=back

Returns a L<Ryu::Source> instance, this will emit a L<Net::Async::Github::PullRequest>
instance for each found repository.

=cut

sub pull_requests {
    my ($self, %args) = @_;
    $self->validate_args(%args);
    $self->api_get_list(
        endpoint => 'pull_request',
        endpoint_args => {
            owner => $args{owner},
            repo => $args{repo},
        },
        class => 'Net::Async::Github::PullRequest'
    );
}

# Provide an alias for anyone relying on previous name
*prs = *pull_requests;

sub teams {
    my ($self, %args) = @_;
    $self->validate_args(%args);
    $self->api_get_list(
        uri   => $self->endpoint('team', org => $args{organisation}),
        class => 'Net::Async::Github::Team',
    )
}

sub Net::Async::Github::Repository::branches {
    my ($self, %args) = @_;
    my $gh = $self->github;
    $gh->validate_args(%args);
    $gh->api_get_list(
        uri   => $self->branches_url->process,
        class => 'Net::Async::Github::Branch',
    )
}

sub Net::Async::Github::Repository::grant_team {
    my ($self, %args) = @_;
    my $gh = $self->github;
    $gh->validate_args(%args);
    $self->github->http_put(
        uri => $self->github->endpoint(
            'team_repo',
            team  => $args{team},
            owner => $self->owner->{login},
            repo  => $self->name,
        ),
        data => {
            permission => $args{permission},
        },
    )
}

=head2 create_branch

Creates a new branch.

Takes the following named parameters:

=over 4

=item * C<owner> - which organisation owns the target repository

=item * C<repo> - the repository to raise the PR against

=item * C<branch> - new branch name that will be created

=item * C<sha> - the SHA1 value for this branch

=back

=cut

sub create_branch {
    my ($self, %args) = @_;
    $self->validate_args(%args);
    $self->http_post(
        uri => $self->endpoint(
            'git_refs_create',
            owner => $args{owner},
            repo  => $args{repo},
        ),
        data => {
            ref => "refs/heads/$args{branch}",
            sha => $args{sha}
        },
    )
}


=head2 update_ref

Update a reference to a new commit

Takes the following named parameters:

=over 4

=item * C<owner> - which organisation owns the target repository

=item * C<repo> - the repository to raise the PR against

=item * C<ref> - ref name that we are updating.

=item * C<sha> - the SHA1 value of comment that the ref will point to

=item * C<force> - force update ref even if it is not fast-forward if it is true.

=back

=cut

sub update_ref {
    my ($self, %args) = @_;
    $self->validate_args(%args);
    $self->http_patch(
        uri => $self->endpoint(
            'git_refs',
            owner => $args{owner},
            repo  => $args{repo},
            category => 'heads',
            ref => $args{ref},
        ),
        data => {
            sha => $args{sha},
            force => ($args{force} ? JSON->true : JSON->false)
        },
    )
}

=head2 create_pr

Creates a new pull request.

Takes the following named parameters:

=over 4

=item * C<owner> - which organisation owns the target repository

=item * C<repo> - the repository to raise the PR against

=item * C<head> - head commit starting point, typically the latest commit on your fork's branch

=item * C<base> - base commit this PR applies changes to typically you'd want the target repo C<master>

=back

=cut

sub create_pr {
    my ($self, %args) = @_;
    $self->validate_args(%args);
    $self->http_post(
        uri => $self->endpoint(
            'pull_request',
            owner => $args{owner},
            repo  => $args{repo},
        ),
        data => {
            head => $args{head},
            base => $args{base},
            title => $args{title},
            $args{body} ? (body => $args{body}) : (),
        },
    )
}

=head2 create_commit

Creates an empty commit. Can be used to simulate C<git commit --allow-empty>
or to create a merge commit from multiple heads.

Takes the following named parameters:

=over 4

=item * C<owner> - which organisation owns the target repository

=item * C<repo> - the repository to raise the PR against

=item * C<message> - The commit message

=item * C<tree> - The SHA of tree object that commit will point to

=item * C<parents> - Arrayref that include the parents of the commit

=back

=cut

sub create_commit {
    my ($self, %args) = @_;
    $self->validate_args(%args);
    $self->http_post(
        uri => $self->endpoint(
            'commits',
            owner => $args{owner},
            repo  => $args{repo},
        ),
        data => {
            message => $args{message},
            tree => $args{tree},
            parents => $args{parents},
        },
    )
}

# Example:
#
# $repo->protect_branch(
#  branch => 'master',
#  required_status_checks => {
#   strict => 1,
#   contexts => [
#    '',
#   ]
#  },
#  enforce_admins => 0,
#  restrictions => {
#   teams => [
#    'WRITE-Admin',
#   ]
#  }
sub Net::Async::Github::Repository::protect_branch {
    my ($self, %args) = @_;
    my $gh = $self->github;
    $gh->validate_args(%args);

    # Coërce the true/false values into something appropriate for JSON
    $args{required_status_checks} = { %{$args{required_status_checks}} };
    $_->{strict} = $_->{strict} ? JSON->true : JSON->false for $args{required_status_checks};
    $args{enforce_admins} = $args{enforce_admins} ? JSON->true : JSON->false;
    $args{required_pull_request_reviews} //= undef;
    if($args{restrictions} //= undef) {
        $args{restrictions}{users} ||= [];
        $args{restrictions}{teams} ||= [];
    }

    $self->github->http_put(
        uri => $self->github->endpoint(
            'branch_protection',
            owner => $self->owner->{login},
            repo  => $self->name,
            branch  => ($args{branch} // die 'need a branch'),
        ),
        data => {
            map {;
                $_ => $args{$_}
            } grep {
                exists $args{$_}
            } qw(
                required_status_checks
                enforce_admins
                required_pull_request_reviews
                restrictions
            )
        },
    )
}

sub Net::Async::Github::Repository::branch_protection {
    my ($self, %args) = @_;
    my $gh = $self->github;
    $gh->validate_args(%args);
    $self->github->http_get(
        uri => $self->github->endpoint(
            'branch_protection',
            owner => $self->owner->{login},
            repo  => $self->name,
            branch  => ($args{branch} // die 'need a branch'),
        ),
    )
}

sub Net::Async::Github::Repository::get_file {
    my ($self, %args) = @_;
    my $gh = $self->github;
    $gh->validate_args(%args);
    $self->github->http_get(
        uri => $self->github->endpoint(
            'contents',
            owner => $self->owner->{login},
            repo  => $self->name,
            path  => ($args{path} // die 'need a path'),
            (exists $args{branch} ? (branch  => $args{branch}) : ()),
        ),
    )->transform(
        done => sub {
            my ($result) = @_;
            if($result->{encoding} eq 'base64') {
                return MIME::Base64::decode_base64($result->{content})
            } else {
                return $result->{content}
            }
        }
    )
}

sub Net::Async::Github::PullRequest::owner { shift->{base}{repo}{owner}{login} }
sub Net::Async::Github::PullRequest::repo { shift->{base}{repo}{name} }
sub Net::Async::Github::PullRequest::branch_name { shift->{head}{ref} }

sub Net::Async::Github::PullRequest::merge {
    my ($self, %args) = @_;
    my $gh = $self->github;
    $gh->validate_args(%args);
    die 'invalid owner' if ref $self->owner;
    die 'invalid repo' if ref $self->repo;
    die 'invalid id' if ref $self->id;
    my $uri = $gh->endpoint(
        'pull_request_merge',
        owner => $args{owner} // $self->owner,
        repo  => $args{repo} // $self->repo,
        id    => $args{id} // $self->number,
    );
    $log->infof('URI for PR merge is %s', "$uri");
    $gh->http_put(
        uri => $uri,
        data => {
            sha => $self->{head}{sha},
            map { $_ => $args{$_} } grep { exists $args{$_} } qw(
                commit_title
                commit_message
                sha
                merge_method
                admin_override
            )
        }
    )
}

sub Net::Async::Github::PullRequest::cleanup {
    my ($self, %args) = @_;
    my $gh = $self->github;
    $gh->validate_args(%args);
    die 'invalid owner' if ref $self->owner;
    die 'invalid repo' if ref $self->repo;
    die 'invalid id' if ref $self->id;
    my $uri = $gh->endpoint(
        'git_refs',
        category => 'heads',
        owner    => $args{owner} // $self->{head}{repo}{owner}{login},
        repo     => $args{repo} // $self->{head}{repo}{name},
        ref      => $args{ref} // $self->branch_name,
    );
    $log->infof('URI for PR delete is %s', "$uri");
    $gh->http_delete(
        uri => $uri,
    )
}

sub repos {
    my ($self, %args) = @_;
    if(my $user = delete $args{owner}) {
        $self->validate_owner_name($user);
        $self->api_get_list(
            endpoint => 'user_repositories',
            endpoint_args => {
                user => $user,
                visibility => $args{visibility} // 'all',
            },
            class => 'Net::Async::Github::Repository',
        )
    } else {
        $self->api_get_list(
            endpoint => 'current_user_repositories',
            endpoint_args => {
                visibility => $args{visibility} // 'all',
            },
            class => 'Net::Async::Github::Repository',
        )
    }
}

sub repo {
    my ($self, %args) = @_;
    die 'need an owner name' unless my $owner = delete $args{owner};
    die 'need a repo name' unless my $repo_name = delete $args{name};
    $self->validate_owner_name($owner);
    $self->validate_repo_name($repo_name);
    $self->http_get(
        uri => $self->endpoint(
            repository => (
                owner => $owner,
                repo => $repo_name,
            )
        ),
    )->transform(
        done => sub {
            $log->tracef('Github repo data was %s', $_[0]);
            Net::Async::Github::Repository->new(
                %{$_[0]},
                github => $self,
            )
        }
    )
}

=head2 user

Returns information about the given user.

=cut

sub user {
    my ($self, $user, %args) = @_;
    $self->validate_owner_name($user);
    $self->http_get(
        uri => $self->endpoint(
            'user',
            user => $user
        ),
    )->transform(
        done => sub {
            Net::Async::Github::User->new(
                %{$_[0]},
                github => $self,
            )
        }
    )
}

=head2 users

Iterates through all users. This is a good way to exhaust your 5000-query
ratelimiting quota.

=cut

sub users {
    my ($self, %args) = @_;
    $self->validate_args(%args);
    $self->api_get_list(
        uri   => '/users',
        class => 'Net::Async::Github::User',
    )
}

=head2 head

Identifies the head version for this branch.

Requires the following named parameters:

=over 4

=item * owner - which organisation or person owns the repo

=item * repo - the repository name

=item * branch - which branch to check

=back

=cut

sub head {
    my ($self, %args) = @_;
    die "needs $_" for grep !$args{$_}, qw(owner repo branch);
    $self->validate_args(%args);
    my $uri = $self->base_uri;
    $uri->path(
        join '/', 'repos', $args{owner}, $args{repo}, qw(git refs heads), $args{branch}
    );
    $self->http_get(
        uri => $uri
    )
}

=head2 update

=cut

sub update {
    my ($self, %args) = @_;
    die "needs $_" for grep !$args{$_}, qw(owner repo branch head);
    $self->validate_branch_name($args{branch});
    my $uri = $self->base_uri;
    $uri->path(
        join '/', 'repos', $args{owner}, $args{repo}, qw(merges)
    );
    $self->http_post(
        uri => $uri,
        data => {
            head           => $args{head},
            base           => $args{branch},
            commit_message => "Merge branch 'master' into " . $args{branch},
        },
    )
}

=head2 core_rate_limit

Returns a L<Net::Async::Github::RateLimit::Core> instance which can track rate limits.

=cut

sub core_rate_limit {
    my ($self) = @_;
    $self->{core_rate_limit} //= do {
        use Variable::Disposition qw(retain_future);
        use namespace::clean qw(retain_future);
        my $rl = Net::Async::Github::RateLimit::Core->new(
            limit     => Ryu::Observable->new(undef),
            remaining => Ryu::Observable->new(undef),
            reset     => Ryu::Observable->new(undef),
        );
        retain_future(
            $self->http_get(
                uri => $self->endpoint('rate_limit')
            )->on_done(sub {
                my $data = shift;
                $log->tracef("Github rate limit response was %s", $data);
                $rl->reset->set_numeric($data->{resources}{core}{reset});
                $rl->limit->set_numeric($data->{resources}{core}{limit});
                $rl->remaining->set_numeric($data->{resources}{core}{remaining});
            })
        );
        $rl;
    }
}

=head2 rate_limit

=cut

sub rate_limit {
    my ($self) = @_;
    $self->http_get(
        uri => $self->endpoint('rate_limit')
    )->transform(
        done => sub {
            Net::Async::Github::RateLimit->new(
                %{$_[0]}
            )
        }
    )
}

=head1 METHODS - Internal

The following methods are used internally. They're not expected to be
useful for external callers.

=head2 api_key

=cut

sub api_key { shift->{api_key} }

=head2 token

=cut

sub token { shift->{token} }

=head2 endpoints

Returns an accessor for the endpoints data. This is a hashref containing URI
templates, used by L</endpoint>.

=cut

sub endpoints {
    my ($self) = @_;
    $self->{endpoints} ||= do {
        my $path = Path::Tiny::path(__DIR__)->parent(3)->child('share/endpoints.json');
        $path = Path::Tiny::path(
            File::ShareDir::dist_file(
                'Net-Async-Github',
                'endpoints.json'
            )
        ) unless $path->exists;
        $json->decode($path->slurp_utf8)
    };
}

=head2 endpoint

Expands the selected URI via L<URI::Template>. Each item is defined in our C< endpoints.json >
file.

Returns a L<URI> instance.

=cut

sub endpoint {
    my ($self, $endpoint, %args) = @_;
    URI::Template->new(
        $self->endpoints->{$endpoint . '_url'}
    )->process(%args);
}

=head2 http

Accessor for the HTTP client object. Will load and instantiate a L<Net::Async::HTTP> instance
if necessary.

Actual HTTP implementation is not guaranteed, and the default is likely to change in future.

=cut

sub http {
    my ($self) = @_;
    $self->{http} ||= do {
        require Net::Async::HTTP;
        $self->add_child(
            my $ua = Net::Async::HTTP->new(
                fail_on_error            => 1,
                max_connections_per_host => $self->connections_per_host,
                pipeline                 => 1,
                max_in_flight            => 4,
                decode_content           => 1,
                user_agent               => 'Mozilla/4.0 (perl; Net::Async::Github; TEAM@cpan.org)',
                (
                    $self->timeout
                    ? (timeout => $self->timeout)
                    : ()
                ),
            )
        );
        $ua
    }
}

sub update_limiter {
    my ($self) = @_;
    unless($self->{update_limiter}) {
        # Any modification should wait for this to resolve first
        $self->{update_limiter} = $self->loop->delay_future(
            after => 1
        )->on_ready(sub {
            delete $self->{update_limiter}
        });
        # Limit the next request - not this one
        return Future->done;
    }
    return $self->{update_limiter};
}

# Github ratelimit guidelines suggest max 1 request in parallel
# per user, with 1s between any state-modifying calls. Since this
# is part of their defined API, we don't expose this in L</configure>.
sub connections_per_host { 4 }

# Like connections, but for data modification - POST, PUT, PATCH etc.
sub updates_per_host { 1 }

=head2 timeout

The parameter that will be used when create Net::Async::HTTP object. If it is undef, then a default value
60 seconds will be used. If it is 0, then Net::Async::HTTP will never timeout.

=cut

sub timeout { shift->{timeout} //= 60 }

=head2 auth_info

Returns authentication information used in the HTTP request.

=cut

sub auth_info {
    my ($self) = @_;
    if(my $key = $self->api_key) {
        return (
            user => $key,
            pass => '',
        );
    }
    if(my $token = $self->token) {
        return (
            headers => {
                Authorization => 'token ' . $token
            }
        )
    }

    die "need some form of auth, try passing a token or api_key"
}

=head2 mime_type

Returns the MIME type used for requests. Currently defined by github in
L<https://developer.github.com/v3/media/> as C<application/vnd.github.v3+json>.

=cut

sub mime_type { shift->{mime_type} //= 'application/vnd.github.v3+json' }

=head2 base_uri

The L<URI> for requests. Defaults to L<https://api.github.com>.

=cut

sub base_uri {
    (
        shift->{base_uri} //= URI->new('https://api.github.com')
    )->clone
}

=head2 http_get

Performs an HTTP GET request.

=cut

sub http_get {
    my ($self, %args) = @_;
    my %auth = $self->auth_info;

    if(my $hdr = delete $auth{headers}) {
        $args{headers}{$_} //= $hdr->{$_} for keys %$hdr
    }
    $args{$_} //= $auth{$_} for keys %auth;

    my $uri = delete $args{uri};
    $log->tracef("GET %s { %s }", $uri->as_string, \%args);
    my $cached = $self->page_cache->get($uri->as_string);
    if($cached) {
        $log->tracef("Had cached page data, etag %s and last modified %s", $cached->header('ETag'), $cached->header('Last-Modified'));
        $args{headers}{'If-None-Match'} = $cached->header('ETag') if $cached->header('ETag');
        $args{headers}{'If-Modified-Since'} = $cached->header('Last-Modified') if $cached->header('Last-Modified');
    }
    $self->http->GET(
        $uri,
        %args,
    )->on_fail(sub {
        $log->tracef('Response failed for %s', "$uri");
    })->on_cancel(sub {
        $log->tracef('Request cancelled for %s', "$uri");
    })->on_done(sub {
        $log->tracef('Response received for %s', "$uri");
    })->then(sub {
        my ($resp) = @_;
        $log->tracef("Github response: %s", $resp->as_string("\n"));
        # If we had ratelimiting headers, apply them
        for my $k (qw(Reset Limit Remaining)) {
            if(defined(my $v = $resp->header('X-RateLimit-' . $k))) {
                my $method = lc $k;
                $self->core_rate_limit->$method->set_numeric($v);
            }
        }

        if($cached && $resp->code == 304) {
            $resp = $cached;
            $log->tracef("Using cached version of [%s] for %d byte response", $uri->as_string, $resp->content_length);
        } elsif($resp->is_success) {
            $log->tracef("Caching [%s] with %d byte response", $uri->as_string, $resp->content_length);
            $self->page_cache->set($uri->as_string => $resp);
        } else {
            $log->tracef("Not caching [%s] due to status %d", $resp->code);
        }

        return Future->done(
            { },
            $resp
        ) if $resp->code == 204;
        return Future->done(
            { },
            $resp
        ) if 3 == ($resp->code / 100);
        try {
            return Future->done(
                $json->decode(
                    $resp->decoded_content
                ),
                $resp
            );
        } catch {
            $log->errorf("JSON decoding error %s from HTTP response %s", $@, $resp->as_string("\n"));
            return Future->fail($@ => json => $resp);
        }
    })->else(sub {
        my ($err, $src, $resp, $req) = @_;
        $log->warnf("Github failed with error %s on source %s", $err, $src);
        $src //= '';
        if($src eq 'http') {
            $log->errorf("HTTP error %s, request was %s with response %s", $err, $req->as_string("\n"), $resp->as_string("\n"));
        } else {
            $log->errorf("Other failure (%s): %s", $src // 'unknown', $err);
        }
        Future->fail(@_);
    })
}

sub http_delete {
    my ($self, %args) = @_;
    my %auth = $self->auth_info;

    if(my $hdr = delete $auth{headers}) {
        $args{headers}{$_} //= $hdr->{$_} for keys %$hdr
    }
    $args{$_} //= $auth{$_} for keys %auth;

    my $uri = delete $args{uri};
    $log->tracef("DELETE %s { %s }", $uri->as_string, \%args);

    # we never cache deletes
    $self->http->do_request(
        method => 'DELETE',
        uri => $uri,
        %args,
    )->then(sub {
        my ($resp) = @_;
        $log->tracef("Github response: %s", $resp->as_string("\n"));
        # If we had ratelimiting headers, apply them
        for my $k (qw(Reset Limit Remaining)) {
            if(defined(my $v = $resp->header('X-RateLimit-' . $k))) {
                my $method = lc $k;
                $self->core_rate_limit->$method->set_numeric($v);
            }
        }

        return Future->done(
            { },
            $resp
        ) if $resp->code == 204;
        return Future->done(
            { },
            $resp
        ) if 3 == ($resp->code / 100);
        try {
            return Future->done(
                $json->decode(
                    $resp->decoded_content
                ),
                $resp
            );
        } catch {
            $log->errorf("JSON decoding error %s from HTTP response %s", $@, $resp->as_string("\n"));
            return Future->fail($@ => json => $resp);
        }
    })->else(sub {
        my ($err, $src, $resp, $req) = @_;
        $log->warnf("Github failed with error %s on source %s", $err, $src);
        $src //= '';
        if($src eq 'http') {
            $log->errorf("HTTP error %s, request was %s with response %s", $err, $req->as_string("\n"), $resp->as_string("\n"));
        } else {
            $log->errorf("Other failure (%s): %s", $src // 'unknown', $err);
        }
        Future->fail(@_);
    })
}

sub http_put {
    my ($self, %args) = @_;
    my %auth = $self->auth_info;
    my $method = delete $args{method} || 'PUT';

    if(my $hdr = delete $auth{headers}) {
        $args{headers}{$_} //= $hdr->{$_} for keys %$hdr
    }
    $args{$_} //= $auth{$_} for keys %auth;

    my $uri = delete $args{uri};
    my $data = delete $args{data};
    $log->tracef("%s %s { %s } <= %s", $method, $uri->as_string, \%args, $data);
    $data = $json->encode($data) if ref $data;
    $self->http->do_request(
        method       => $method,
        uri          => $uri,
        content      => $data,
        content_type => 'application/json',
        %args,
    )->then(sub {
        my ($resp) = @_;
        $log->tracef("Github response: %s", $resp->as_string("\n"));
        # If we had ratelimiting headers, apply them
        for my $k (qw(Limit Remaining Reset)) {
            if(defined(my $v = $resp->header('X-RateLimit-' . $k))) {
                my $method = lc $k;
                $self->core_rate_limit->$method->set_numeric($v);
            }
        }

        return Future->done(
            { },
            $resp
        ) if $resp->code == 204;
        return Future->done(
            { },
            $resp
        ) if 3 == ($resp->code / 100);
        try {
            return Future->done(
                $json->decode(
                    $resp->decoded_content
                ),
                $resp
            );
        } catch {
            $log->errorf("JSON decoding error %s from HTTP response %s", $@, $resp->as_string("\n"));
            return Future->fail($@ => json => $resp);
        }
    })->else(sub {
        my ($err, $src, $resp, $req) = @_;
        $log->warnf("Github failed with error %s on source %s", $err, $src);
        $src //= '';
        if($src eq 'http') {
            $log->errorf("HTTP error %s, request was %s with response %s", $err, $req->as_string("\n"), $resp->as_string("\n"));
        } else {
            $log->errorf("Other failure (%s): %s", $src // 'unknown', $err);
        }
        Future->fail(@_);
    })
}

sub http_patch {
    my ($self, %args) = @_;
    return $self->http_put(%args, method => 'PATCH');
}

sub http_post {
    my ($self, %args) = @_;
    my %auth = $self->auth_info;

    if(my $hdr = delete $auth{headers}) {
        $args{headers}{$_} //= $hdr->{$_} for keys %$hdr
    }
    $args{$_} //= $auth{$_} for keys %auth;

    my $uri = delete $args{uri};
    my $data = delete $args{data};
    $log->tracef("POST %s { %s } <= %s", $uri->as_string, \%args, $data);
    $data = $json->encode($data) if ref $data;
    $self->http->POST(
        $uri,
        $data,
        content_type => 'application/json',
        %args,
    )->then(sub {
        my ($resp) = @_;
        $log->tracef("Github response: %s", $resp->as_string("\n"));
        # If we had ratelimiting headers, apply them
        for my $k (qw(Limit Remaining Reset)) {
            if(defined(my $v = $resp->header('X-RateLimit-' . $k))) {
                my $method = lc $k;
                $self->core_rate_limit->$method->set_numeric($v);
            }
        }

        return Future->done(
            { },
            $resp
        ) if $resp->code == 204;
        return Future->done(
            { },
            $resp
        ) if 3 == ($resp->code / 100);
        try {
            return Future->done(
                $json->decode(
                    $resp->decoded_content
                ),
                $resp
            );
        } catch {
            $log->errorf("JSON decoding error %s from HTTP response %s", $@, $resp->as_string("\n"));
            return Future->fail($@ => json => $resp);
        }
    })->else(sub {
        my ($err, $src, $resp, $req) = @_;
        $log->warnf("Github failed with error %s on source %s", $err, $src);
        $src //= '';
        if($src eq 'http') {
            $log->errorf("HTTP error %s, request was %s with response %s", $err, $req->as_string("\n"), $resp->as_string("\n"));
        } else {
            $log->errorf("Other failure (%s): %s", $src // 'unknown', $err);
        }
        Future->fail(@_);
    })
}

sub api_get_list {
    use Variable::Disposition qw(retain_future);
    use Scalar::Util qw(refaddr);
    use Future::Utils qw(fmap0);
    use namespace::clean qw(retain_future fmap0 refaddr);

    my ($self, %args) = @_;
    my $label = $args{endpoint}
    ? ('Github[' . $args{endpoint} . ']')
    : (caller 1)[3];

    die "Must be a member of a ::Loop" unless $self->loop;

    # Hoist our HTTP API call into a source of items
    my $src = $self->ryu->source(
        label => $label
    );
    my $uri = $args{endpoint}
    ? $self->endpoint(
        $args{endpoint},
        %{$args{endpoint_args}}
    ) : ref $args{uri}
    ? $args{uri}
    : URI->new(
        $self->base_uri . delete($args{uri})
    );

    my $per_page = (delete $args{per_page}) || 100;
    $uri->query_param(
        limit => $per_page
    );
    my @pending = $uri;
    my $f = (fmap0 {
        my $uri = shift;
        $self->http_get(
            uri => $uri,
        )->on_done(sub {
            my ($data, $resp) = @_;
            # Handle paging - this takes the form of zero or more Link headers like this:
            # Link: <https://api.github.com/user/repos?page=2>; rel="next"
            for my $link (map { split /\s*,\s*/, $_ } $resp->header('Link')) {
                if($link =~ m{<([^>]+)>; rel="next"}) {
                    push @pending, URI->new($1);
                }
            }

            $src->emit(
                $args{class}->new(
                    %$_,
                    ($args{extra} ? %{$args{extra}} : ()),
                    github => $self
                )
            ) for @{ $_[0] };
        })->on_fail(sub {
            warn "fail - @_";
            $src->fail(@_)
        })->on_cancel(sub {
            warn "cancel - @_";
            $src->cancel
        });
    } foreach => \@pending)->on_done(sub {
        $src->finish;
    });

    # If our source finishes earlier than our HTTP request, then cancel the request
    $src->completed->on_ready(sub {
        return if $f->is_ready;
        $log->tracef("Finishing HTTP request early for %s since our source is no longer active", $label);
        $f->cancel
    });

    # Track active requests
    my $refaddr = Scalar::Util::refaddr($f);
    $self->pending_requests->push([ {
        id     => $refaddr,
        src    => $src,
        uri    => $uri,
        future => $f,
    } ])->then(sub {
        $f->on_ready(sub {
            retain_future(
                $self->pending_requests->extract_first_by(sub { $_->{id} == $refaddr })
            )
        });
    })->retain;
    $src
}

=head2 pending_requests

A list of all pending requests.

=cut

sub pending_requests {
    shift->{pending_requests} //= do {
        require Adapter::Async::OrderedList::Array;
        Adapter::Async::OrderedList::Array->new
    }
}

=head2 validate_branch_name

Applies validation rules from L<git-check-ref-format> for a branch name.

Will raise an exception on invalid input.

=cut

sub validate_branch_name {
    my ($self, $branch) = @_;
    die "branch not defined" unless defined $branch;
    die "branch contains path component with leading ." if $branch =~ m{/\.};
    die "branch contains double ." if $branch =~ m{\.\.};
    die "branch contains invalid character(s)" if $branch =~ m{[[:cntrl:][:space:]~^:\\]};
    die "branch ends with /" if substr($branch, -1) eq '/';
    die "branch ends with .lock" if substr($branch, -5) eq '.lock';
    return 1;
}

=head2 validate_owner_name

Applies github rules for user/organisation name.

Will raise an exception on invalid input.

=cut

sub validate_owner_name {
    my ($self, $owner) = @_;
    die "owner name not defined" unless defined $owner;
    die "owner name too long" if length($owner) > 39;
    die "owner name contains invalid characters" if $owner =~ /[^a-z0-9-]/i;
    die "owner name contains double hyphens" if $owner =~ /--/;
    die "owner name contains leading hyphen" if $owner =~ /^-/;
    die "owner name contains trailing hyphen" if $owner =~ /-$/;
    return 1;
}

=head2 validate_repo_name

Applies github rules for repository name.

Will raise an exception on invalid input.

=cut

sub validate_repo_name {
    my ($self, $repo) = @_;
    die "repo name not defined" unless defined $repo;
    # Not really as well-defined as I'd like, closest to an official answer seems to be here:
    # https://github.community/t/github-repository-name-vs-description-vs-readme-heading-h1/3284
    # There are repositories with underscores, but that seems to be strongly discouraged:
    # https://github.com/Automattic/_s
    # Canonical repositories with '. character would include the `.wiki` "magic" repo for each
    # Github repo
    die "repo name contains invalid characters" if $repo =~ /[^a-z0-9.]/i;
    die "repo name too long" if length($repo) > 100;
    return 1;
}

=head2 validate_args

Convenience method to apply validation on common parameters.

=cut

sub validate_args {
    my ($self, %args) = @_;
    $self->validate_branch_name($args{branch}) if exists $args{branch};
    $self->validate_owner_name($args{owner}) if exists $args{owner};
    $self->validate_repo_name($args{repo}) if exists $args{repo};
}

=head2 page_cache_size

Returns the total number of GET responses we'll cache. Default is probably 1000.

=cut

sub page_cache_size { shift->{page_cache_size} //= 1000 }

=head2 page_cache

The page cache instance, likely to be provided by L<Cache::LRU>.
=cut

sub page_cache {
    $_[0]->{page_cache} //= do {
        Cache::LRU->new(
            size => $_[0]->page_cache_size
        )
    }
}

=head2 ryu

Our L<Ryu::Async> instance, used for instantiating L<Ryu::Source> instances.

=cut

sub ryu { shift->{ryu} }

sub _add_to_loop {
    my ($self, $loop) = @_;

    # Hand out sources and sinks
    $self->add_child(
        $self->{ryu} = Ryu::Async->new
    );

}

sub ws {
    my ($self) = @_;
    $self->{ws} // do {
        require Net::Async::WebSocket::Client;
        $self->add_child(
            my $ws = Net::Async::WebSocket::Client->new(
                on_frame => $self->curry::weak::on_frame,
            )
        );
        Scalar::Util::weaken($self->{ws} = $ws);
        $ws
    };
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>, with contributions from C<< @chylli-binary >>.

=head1 LICENSE

Copyright Tom Molesworth 2014-2021. Licensed under the same terms as Perl itself.

