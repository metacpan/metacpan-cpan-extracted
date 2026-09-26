package
    Mojo::ATProto::OAuth::ResourceClient;
use Mojo::Base -base, -signatures;

use Mojo::ATProto::OAuth::DPoP qw//;
use Mojo::URL                  qw//;
use Mojo::UserAgent            qw//;
use Mojo::Log                  qw//;
use Mojo::Promise              qw//;

use feature 'try';

use constant DEBUG => $ENV{MOJO_OAUTH_DEBUG} || 0;

our $VERSION = '1.03'; # VERSION

has 'oauth' => sub { die "oauth is required\n" };    # Mojo::ATProto::OAuth instance - only ->store, ->refresh_tokens(_p) and ->_update_stored_session(_p) are used
has 'ua'    => sub($self) { $self->oauth->ua };
has 'log'   => sub($self) { $self->oauth->log };

# Sends an authenticated XRPC request against $did's stored session's own
# PDS (host_url), handling DPoP nonce rotation and access-token refresh
# transparently. $method is a lowercase Mojo::UserAgent verb ('get',
# 'post', ...), $path is the XRPC path (and query string, if any) to
# append to host_url, $body (if given) is sent as a JSON request body.
# Returns the decoded JSON response. Dies on a non-2xx response that
# isn't recovered by a nonce/refresh retry - see _request_with_session.
sub request($self, $did, $session_id, $method, $path, $body = undef) {
    my $session = $self->oauth->store->get_session($did, $session_id);
    return $self->_request_with_session($session, $method, $path, $body, 1, 1);
}

sub request_p($self, $did, $session_id, $method, $path, $body = undef) {
    return $self->oauth->store->get_session_p($did, $session_id)->then(sub($session) {
        return $self->_request_with_session_p($session, $method, $path, $body, 1, 1);
    });
}

# DPoP nonce rotation (RFC 9449): a 401 accompanied by a fresh
# DPoP-Nonce response header means "retry with this nonce", not a real
# auth failure - bounded by $nonce_retries_left. A 401 with no fresh
# nonce means the access token itself needs refreshing, via
# $self->oauth->refresh_tokens(_p) (which persists the refreshed session
# itself) - bounded by $refresh_retries_left. Either bound reaching 0
# means a persistently-failing session dies cleanly instead of looping.
sub _request_with_session($self, $session, $method, $path, $body, $nonce_retries_left, $refresh_retries_left) {
    my $url      = Mojo::URL->new($session->{host_url})->path($path);
    my $dpop_key = Mojo::ATProto::OAuth::DPoP->import_private_pem($session->{dpop_private_key_pem});
    my $dpop_jwt = Mojo::ATProto::OAuth::DPoP->proof(
        key => $dpop_key, method => $method, url => $url->to_string,
        nonce => $session->{dpop_host_nonce}, access_token => $session->{access_token},
        issuer => $session->{auth_server_url},
    );
    $self->log->debug("request: $method $url") if DEBUG;

    my $headers = {Authorization => 'DPoP ' . $session->{access_token}, DPoP => $dpop_jwt};
    my @extra   = defined($body) ? (json => $body) : ();
    my $tx      = $self->ua->$method($url, $headers, @extra);
    my $res     = $tx->res;

    # The resource server can rotate the DPoP nonce on any response, not
    # just a 401 - persist it either way so the next call anywhere starts
    # from the freshest known nonce. Only the nonce is written: $session
    # was read before this request, and writing all of it back would
    # overwrite tokens another process may have refreshed since.
    my $new_nonce = $res->headers->header('DPoP-Nonce') // '';
    if (length($new_nonce) && $new_nonce ne ($session->{dpop_host_nonce} // '')) {
        $session->{dpop_host_nonce} = $new_nonce;
        $self->oauth->_update_stored_session($session->{account_did}, $session->{session_id}, {dpop_host_nonce => $new_nonce});
    }

    if (($res->code // 0) == 401) {
        if (length($new_nonce) && $nonce_retries_left > 0) {
            $self->log->debug('request: retrying with fresh DPoP-Nonce') if DEBUG;
            return $self->_request_with_session($session, $method, $path, $body, $nonce_retries_left - 1, $refresh_retries_left);
        }
        if ($refresh_retries_left > 0) {
            $self->log->debug('request: refreshing access token and retrying') if DEBUG;
            $session = $self->oauth->refresh_tokens($session);
            return $self->_request_with_session($session, $method, $path, $body, $nonce_retries_left, $refresh_retries_left - 1);
        }
        die "request failed (HTTP 401): session could not be refreshed\n";
    }

    die $self->_error_message($tx, $res) unless $res->is_success;
    return $res->json;
}

sub _request_with_session_p($self, $session, $method, $path, $body, $nonce_retries_left, $refresh_retries_left) {
    my $url      = Mojo::URL->new($session->{host_url})->path($path);
    my $dpop_key = Mojo::ATProto::OAuth::DPoP->import_private_pem($session->{dpop_private_key_pem});
    my $dpop_jwt = Mojo::ATProto::OAuth::DPoP->proof(
        key => $dpop_key, method => $method, url => $url->to_string,
        nonce => $session->{dpop_host_nonce}, access_token => $session->{access_token},
        issuer => $session->{auth_server_url},
    );
    $self->log->debug("request_p: $method $url") if DEBUG;

    my $headers   = {Authorization => 'DPoP ' . $session->{access_token}, DPoP => $dpop_jwt};
    my @extra     = defined($body) ? (json => $body) : ();
    my $ua_method = "${method}_p";
    return $self->ua->$ua_method($url, $headers, @extra)->then(sub($tx) {
        my $res       = $tx->res;
        my $new_nonce = $res->headers->header('DPoP-Nonce') // '';

        my $nonce_saved_p = Mojo::Promise->resolve;
        if (length($new_nonce) && $new_nonce ne ($session->{dpop_host_nonce} // '')) {
            $session->{dpop_host_nonce} = $new_nonce;
            $nonce_saved_p = $self->oauth->_update_stored_session_p($session->{account_did}, $session->{session_id}, {dpop_host_nonce => $new_nonce});
        }

        return $nonce_saved_p->then(sub {
            if (($res->code // 0) == 401) {
                if (length($new_nonce) && $nonce_retries_left > 0) {
                    $self->log->debug('request_p: retrying with fresh DPoP-Nonce') if DEBUG;
                    return $self->_request_with_session_p($session, $method, $path, $body, $nonce_retries_left - 1, $refresh_retries_left);
                }
                if ($refresh_retries_left > 0) {
                    $self->log->debug('request_p: refreshing access token and retrying') if DEBUG;
                    return $self->oauth->refresh_tokens_p($session)->then(sub($refreshed) {
                        return $self->_request_with_session_p($refreshed, $method, $path, $body, $nonce_retries_left, $refresh_retries_left - 1);
                    });
                }
                die "request_p failed (HTTP 401): session could not be refreshed\n";
            }

            die $self->_error_message($tx, $res) unless $res->is_success;
            return $res->json;
        });
    });
}

# Extracts the XRPC response's machine-readable `error` field (e.g.
# 'InvalidSwap') alongside the human-readable `message`, so a caller can
# distinguish error *kinds* (e.g. a swapRecord conflict) without needing
# a blessed exception type - matches this library's "no models" rule.
sub _error_message($self, $tx, $res) {
    my $json_body  = eval { $res->json };
    my $message    = (ref($json_body) eq 'HASH' && defined($json_body->{message})) ? $json_body->{message} : ($tx->error->{message} // 'unknown error');
    my $xrpc_error = (ref($json_body) eq 'HASH' && defined($json_body->{error}))   ? $json_body->{error}   : undef;
    return 'request failed (HTTP ' . ($res->code // 'connection error')
        . (defined($xrpc_error) ? ", xrpc_error=$xrpc_error" : '') . "): $message\n";
}

1;

__END__

=head1 NAME

Mojo::ATProto::OAuth::ResourceClient - authenticated XRPC requests against a session's own PDS

=head1 SYNOPSIS

    use Mojo::ATProto::OAuth qw//;
    use Mojo::ATProto::OAuth::ResourceClient qw//;
    use feature 'try'; 

    my $oauth  = Mojo::ATProto::OAuth->new(..., store => 'Pg');
    my $client = Mojo::ATProto::OAuth::ResourceClient->new(oauth => $oauth);

    # authenticated GET
    my $profile = $client->request($did, $session_id, 'get', '/xrpc/app.bsky.actor.getProfile?actor=' . $did);

    # authenticated POST, e.g. a putRecord with optimistic-concurrency swapRecord
    try { 
        my $result = $client->request($did, $session_id, 'post', '/xrpc/com.atproto.repo.putRecord', {
            repo       => $did,
            collection => 'app.bsky.feed.post',
            rkey       => $rkey,
            record     => $record,
            swapRecord => $prior_cid,
        });
    } catch($ex) {
        die $err unless $ex =~ /xrpc_error=InvalidSwap/; # re-throw the exception if it isn't an InvalidSwap
        # ... retry with a fresh $prior_cid ...
    }

    # non-blocking counterpart
    $client->request_p($did, $session_id, 'get', '/xrpc/app.bsky.actor.getProfile?actor=' . $did)
        ->then(sub ($profile) { ... })
        ->catch(sub ($err) { ... });

=head1 DESCRIPTION

L<Mojo::ATProto::OAuth> itself only handles the OAuth handshake (PAR, token exchange, refresh) and gives you a durable L<store|Mojo::ATProto::OAuth/store> - it has no opinion on what you do with a session afterwards. This class provides the "make an authenticated request against the resource server (the user's own PDS) with a stored session" logic. Given a C<$did>/C<$session_id> pair, it loads the session from the same C<store> the C<$oauth> instance uses, signs a DPoP proof, sends the request, and transparently handles the two ways a PDS can reject an otherwise-valid request:

=over 4

=item * B<DPoP nonce rotation> (RFC 9449) - a C<401> accompanied by a fresh C<DPoP-Nonce> response header means "retry with this nonce", not a real auth failure. The resource server can also rotate the nonce on a I<successful> response - this is persisted back to L<store|Mojo::ATProto::OAuth/store> either way, so the next call (from any session, any process) starts from the freshest known nonce. Only the nonce itself is written (via the store's C<update_session>), never the rest of the session this request started with, so it can't overwrite tokens another process has refreshed in the meantime.

=item * B<access token expiry> - a C<401> with no fresh nonce means the access token itself needs refreshing; this calls the C<$oauth> instance's own L<refresh_tokens(_p)|Mojo::ATProto::OAuth/refresh_tokens> (which persists the refreshed session itself, and is safe to call from several processes sharing one session at once - see there) and retries once more.

=back

Both of these are retried at most once (matching L<Mojo::ATProto::OAuth>'s own C<_post_dpop_retry>/C<_post_dpop_retry_p> 2-attempt cap), so a persistently-failing session dies cleanly instead of looping.

=head1 ATTRIBUTES

=head2 oauth

(Required.) The L<Mojo::ATProto::OAuth> instance to operate against - its L<store|Mojo::ATProto::OAuth/store> is used to load/save sessions, and its L<refresh_tokens|Mojo::ATProto::OAuth/refresh_tokens>/L<refresh_tokens_p|Mojo::ATProto::OAuth/refresh_tokens_p> are called on access-token expiry.

=head2 ua

A L<Mojo::UserAgent> instance used for every HTTP request this class makes. Defaults to C<< $oauth->ua >>, so this class shares the same client (and its configured timeout) unless overridden.

=head2 log

A L<Mojo::Log> instance for debug logging. Defaults to C<< $oauth->log >>.

=head1 METHODS

=head2 request / request_p

    my $json = $client->request($did, $session_id, $method, $path, $body);

Sends an authenticated XRPC request against the session's own PDS (C<host_url>). C<$method> is a lowercase L<Mojo::UserAgent> verb (C<get>, C<post>, ...); C<$path> is the XRPC path, including any query string, appended to C<host_url>; C<$body> (optional) is sent as a JSON request body. Returns the decoded JSON response.

C<request> dies (C<request_p> rejects) with a newline-terminated message on a non-2xx response that isn't recovered by a nonce/refresh retry. The message includes the XRPC response's machine-readable C<error> field when present (as C<xrpc_error=I<value>>) alongside the human-readable C<message>, so a caller can distinguish error I<kinds> (e.g. a C<com.atproto.repo.putRecord> C<swapRecord> conflict surfacing as C<xrpc_error=InvalidSwap>) by matching against the die message, without needing a blessed exception type.

=head1 SEE ALSO

L<Mojo::ATProto::OAuth>, L<Mojo::ATProto::OAuth::DPoP>

=cut
