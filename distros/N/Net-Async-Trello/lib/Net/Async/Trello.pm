package Net::Async::Trello;
# ABSTRACT: Interaction with the trello.com API

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '0.005';

=head1 NAME

Net::Async::Trello - low-level Trello API access

=head1 DESCRIPTION

Provides a basic interface for interacting with the L<Trello|https://trello.com> webservice.

It's currently a very crude implementation, implementing a small subset of the available API
features.

=cut

no indirect;

use Dir::Self;
use curry;
use Future;
use URI;
use URI::QueryParam;
use URI::Template;
use URI::wss;
use HTTP::Request;

use JSON::MaybeUTF8 qw(:v1);
use Syntax::Keyword::Try;

use File::ShareDir ();
use Log::Any qw($log);
use Path::Tiny ();

use IO::Async::SSL;

use Net::Async::OAuth::Client;

use Net::Async::Trello::WS;

use Net::Async::Trello::Organisation;
use Net::Async::Trello::Member;
use Net::Async::Trello::Board;
use Net::Async::Trello::Card;
use Net::Async::Trello::List;

use Ryu::Async;
use Adapter::Async::OrderedList::Array;

=head2 me

Returns profile information for the current user.

=cut

sub me {
    my ($self, %args) = @_;
    $self->http_get(
        uri => URI->new($self->base_uri . 'members/me')
    )->transform(
        done => sub {
            Net::Async::Trello::Member->new(
                %{ $_[0] },
                trello => $self,
            )
        }
    )
}

=head2 boards

Returns a L<Ryu::Source> representing the available boards.

=cut

sub boards {
    my ($self, %args) = @_;
    $self->api_get_list(
        endpoint => 'boards',
        class    => 'Net::Async::Trello::Board',
    )
}

=head2 board

Resolves to the board with the corresponding ID.

Takes the following named parameters:

=over 4

=item * id - the board ID to request

=back

Returns a L<Future>.

=cut

sub board {
    my ($self, %args) = @_;
    my $id = delete $args{id};
    my $uri = URI->new($self->base_uri . 'board/' . $id);
    $uri->query_param($_ => $args{$_}) for keys %args;
    $self->http_get(
        uri => $uri
    )->transform(
        done => sub {
            Net::Async::Trello::Board->new(
                %{ $_[0] },
                trello => $self,
            )
        }
    )
}

sub card {
    my ($self, %args) = @_;
    my $id = delete $args{id};
    $self->http_get(
        uri => URI->new($self->base_uri . 'cards/' . $id)
    )->transform(
        done => sub {
            Net::Async::Trello::Card->new(
                %{ $_[0] },
                trello => $self,
            )
        }
    )
}

=head2 search

Performs a search.

=cut

sub search {
    my ($self, %args) = @_;
    $self->http_get(
        uri => $self->endpoint(
            'search',
            
        ),
    )->transform(
        done => sub {
            Net::Async::Trello::Card->new(
                %{ $_[0] },
                trello => $self,
            )
        }
    )
}

sub configure {
    my ($self, %args) = @_;
    for my $k (grep exists $args{$_}, qw(key secret token token_secret ws_token)) {
        $self->{$k} = delete $args{$k};
    }
    $self->SUPER::configure(%args);
}

sub ws_token { shift->{ws_token} }

sub key { shift->{key} }
sub secret { shift->{secret} }
sub token { shift->{token} }
sub token_secret { shift->{token_secret} }

sub http {
    my ($self) = @_;
    $self->{http} ||= do {
        require Net::Async::HTTP;
        $self->add_child(
            my $ua = Net::Async::HTTP->new(
                fail_on_error            => 1,
                max_connections_per_host => 2,
                pipeline                 => 0,
                max_in_flight            => 4,
                decode_content           => 1,
                timeout                  => 30,
                user_agent               => 'Mozilla/4.0 (perl; Net::Async::Trello; TEAM@cpan.org)',
            )
        );
        $ua
    }
}

=head1 METHODS - Internal

None of these are likely to be stable or of much use to external callers.

=cut

sub base_uri { shift->{base_uri} //= URI->new('https://api.trello.com/1/') }

sub mime_type { shift->{mime_type} //= 'application/json' }

sub oauth {
    my ($self) = @_;
    $self->{oauth} //= Net::Async::OAuth::Client->new(
        realm           => 'Trello',
        consumer_key    => $self->key,
        consumer_secret => $self->secret,
        token           => $self->token,
        token_secret    => $self->token_secret,
    )
}

=head2 endpoints

=cut

sub endpoints {
    my ($self) = @_;
    $self->{endpoints} ||= do {
        my $path = Path::Tiny::path(__DIR__)->parent(3)->child('share/endpoints.json');
        $path = Path::Tiny::path(
            File::ShareDir::dist_file(
                'Net-Async-Trello',
                'endpoints.json'
            )
        ) unless $path->exists;
        decode_json_text($path->slurp_utf8)
    };
}

=head2 endpoint

=cut

sub endpoint {
    my ($self, $endpoint, %args) = @_;
    URI::Template->new(
        $self->endpoints->{$endpoint . '_url'}
    )->process(%args);
}

sub http_get {
    my ($self, %args) = @_;

    $args{headers}{Authorization} = $self->oauth->authorization_header(
        method => 'GET',
        uri => $args{uri}
    );

    $log->tracef("GET %s { %s }", ''. $args{uri}, \%args);
    $self->http->GET(
        (delete $args{uri}),
        %args
    )->then(sub {
        my ($resp) = @_;
        $log->tracef("%s => %s", $args{uri}, $resp->decoded_content);
        return { } if $resp->code == 204;
        return { } if 3 == ($resp->code / 100);
        try {
            return Future->done(decode_json_utf8($resp->decoded_content))
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

sub http_post {
    my ($self, %args) = @_;

    $args{headers}{Authorization} = $self->oauth->authorization_header(
        method => 'GET',
        uri => $args{uri}
    );

    $log->tracef("POST %s { %s }", ''. $args{uri}, \%args);
    $self->http->POST(
        (delete $args{uri}),
        encode_json_utf8(delete $args{body}),
        content_type => 'application/json',
        %args
    )->then(sub {
        my ($resp) = @_;
        $log->tracef("%s => %s", $args{uri}, $resp->decoded_content);
        return { } if $resp->code == 204;
        return { } if 3 == ($resp->code / 100);
        try {
            return Future->done(decode_json_utf8($resp->decoded_content))
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

sub http_put {
    my ($self, %args) = @_;

    $args{headers}{Authorization} = $self->oauth->authorization_header(
        method => 'PUT',
        uri    => $args{uri}
    );

    $log->tracef("PUT %s { %s }", ''. $args{uri}, \%args);
    $self->http->PUT(
        (delete $args{uri}),
        encode_json_utf8(delete $args{body}),
        content_type => 'application/json',
        %args
    )->then(sub {
        my ($resp) = @_;
        $log->tracef("%s => %s", $args{uri}, $resp->decoded_content);
        return { } if $resp->code == 204;
        return { } if 3 == ($resp->code / 100);
        try {
            return Future->done(decode_json_utf8($resp->decoded_content))
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

sub socket_io {
    my ($self, %args) = @_;

    my $uri = $self->endpoint('socket_io');
    $args{headers}{Authorization} = $self->oauth->authorization_header(
        method => 'GET',
        uri => $uri,
    );

    $log->tracef("GET %s { }", ''. $uri);
    $self->http->GET(
        $uri,
        %args
    )->then(sub {
        my ($resp) = @_;
        return { } if $resp->code == 204;
        return { } if 3 == ($resp->code / 100);
        my @info = split /:/, $resp->decoded_content;
        die "expected websocket" unless $info[3] eq 'websocket';
        Future->done($info[0]);
    });
}

sub api_get_list {
    use Variable::Disposition qw(retain_future);
    use Scalar::Util qw(refaddr);
    use Future::Utils qw(fmap0);
    use namespace::clean qw(retain_future refaddr);

    my ($self, %args) = @_;
    my $label = $args{endpoint}
    ? ('Trello[' . $args{endpoint} . ']')
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
    ) : URI->new(
        $self->base_uri . $args{uri}
    );

    my $per_page = (delete $args{per_page}) || 100;
    $uri->query_param(
        limit => $per_page
    );
    my $f = (fmap0 {
#        $uri->query_param(
#            before => $per_page
#        );
        $self->http_get(
            uri => $uri,
        )->on_done(sub {
            $log->tracef("we received %s", $_[0]);
            $src->emit(
                $args{class}->new(
                    %$_,
                    ($args{extra} ? %{$args{extra}} : ()),
                    trello => $self
                )
            ) for @{ $_[0] };
            $src->finish;
        })->on_fail(sub {
            $src->fail(@_)
        })->on_cancel(sub {
            $src->cancel
        });
    } foreach => [1]);

    # If our source finishes earlier than our HTTP request, then cancel the request
    $src->completed->on_ready(sub {
        return if $f->is_ready;
        $log->tracef("Finishing HTTP request early for %s since our source is no longer active", $label);
        $f->cancel
    });

    # Track active requests
    my $refaddr = Scalar::Util::refaddr($f);
    retain_future(
        $self->pending_requests->push([ {
            id  => $refaddr,
            src => $src,
            uri => $args{uri},
            future => $f,
        } ])->then(sub {
            $f->on_ready(sub {
                retain_future(
                    $self->pending_requests->extract_first_by(sub { $_->{id} == $refaddr })
                )
            });
        })
    );
    $src
}

sub pending_requests {
    shift->{pending_requests} //= Adapter::Async::OrderedList::Array->new
}

sub ryu { shift->{ryu} }

sub _add_to_loop {
    my ($self, $loop) = @_;

    $self->add_child(
        $self->{ryu} = Ryu::Async->new
    );

}

sub ws {
    my ($self) = @_;
    $self->{ws} //= do {
        $self->add_child(
            my $ws = Net::Async::Trello::WS->new(
                trello => $self,
                token  => $self->ws_token,
            )
        );
        $ws
    }
}

sub websocket { shift->ws->connection }

sub oauth_request {
    my ($self, $code) = @_;

    # We don't provide any scope or expiration details at this point. Those are added to the URI in the browser.
    my $uri = URI->new('https://trello.com/1/OAuthGetRequestToken');
    my $req = HTTP::Request->new(POST => "$uri");
    $req->protocol('HTTP/1.1');

    # $req->header(Authorization => 'Bearer ' . $self->req);
    $self->oauth->configure(
        token => '',
        token_secret => '',
    );
    my $hdr = $self->oauth->authorization_header(
        method => 'POST',
        uri    => $uri,
    );
    $req->header('Authorization' => $hdr);
    $log->tracef("Resulting auth header for userstream was %s", $hdr);

    $req->header('Host' => $uri->host);
    # $req->header('User-Agent' => 'OAuth gem v0.4.4');
    $req->header('Connection' => 'close');
    $req->header('Accept' => '*/*');
    $self->http->do_request(
        request => $req,
    )->then(sub {
        my ($resp) = @_;
        $log->debugf("RequestToken response was %s", $resp->as_string("\n"));
        my $rslt = URI->new('http://localhost?' . $resp->decoded_content)->query_form_hash;
        $log->debugf("Extracted token [%s]", $rslt->{oauth_token});
        $self->oauth->configure(token => $rslt->{oauth_token});
        $log->debugf("Extracted secret [%s]", $rslt->{oauth_token_secret});
        $self->oauth->configure(token_secret => $rslt->{oauth_token_secret});

        my $auth_uri = URI->new(
            'https://trello.com/1/OAuthAuthorizeToken'
        );
        $auth_uri->query_param(oauth_token => $rslt->{oauth_token});
        $auth_uri->query_param(scope => 'read,write');
        $auth_uri->query_param(name => 'trelloctl');
        $auth_uri->query_param(expiration => 'never');
        $code->($auth_uri);
    }, sub {
        $log->errorf("Failed to do oauth lookup - %s", join ',', @_);
        die @_;
    })->then(sub {
        my ($verify) = @_;
        my $uri = URI->new('https://trello.com/1/OAuthGetAccessToken');
        my $req = HTTP::Request->new(POST => "$uri");
        $req->protocol('HTTP/1.1');

        my $hdr = $self->oauth->authorization_header(
            method => 'POST',
            uri    => $uri,
            parameters => {
                oauth_verifier => $verify
            }
        );
        $req->header('Authorization' => $hdr);
        $log->tracef("Resulting auth header was %s", $hdr);

        $req->header('Host' => $uri->host);
        $req->header('Connection' => 'close');
        $req->header('Accept' => '*/*');
        $self->http->do_request(
            request => $req,
        )
    })->then(sub {
        my ($resp) = @_;
        $log->tracef("GetAccessToken response was %s", $resp->as_string("\n"));
        my $rslt = URI->new('http://localhost?' . $resp->decoded_content)->query_form_hash;
        $log->tracef("Extracted token [%s]", $rslt->{oauth_token});
        $self->configure(token => $rslt->{oauth_token});
        $log->tracef("Extracted secret [%s]", $rslt->{oauth_token_secret});
        $self->configure(token_secret => $rslt->{oauth_token_secret});
        Future->done({
            token        => $rslt->{oauth_token},
            token_secret => $rslt->{oauth_token_secret},
        })
    })
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2014-2017. Licensed under the same terms as Perl itself.

