# Copyright (C) 2009, Pascal Gaudette.

package MojoX::UserAgent;

use warnings;
use strict;

use base 'Mojo::Base';

use Carp 'croak';

use Mojo 0.991250;

use Mojo::URL;
use Mojo::Transaction::Pipeline;
use Mojo::Client;
use Mojo::Cookie;
use MojoX::UserAgent::Transaction;
use MojoX::UserAgent::CookieJar;

our $VERSION = '0.21';

__PACKAGE__->attr('allow_post_redirect', 1);

__PACKAGE__->attr(
    'agent' => "Mozilla/5.0 (compatible; MojoX::UserAgent/$VERSION)");

__PACKAGE__->attr('app');

__PACKAGE__->attr('cookie_jar' => sub { MojoX::UserAgent::CookieJar->new });

__PACKAGE__->attr(
    'default_done_cb' => sub {
        return sub {
            my ($self, $tx) = @_;
            my $url = $tx->hops ? $tx->original_req->url : $tx->req->url;
            print "$url done in " . $tx->hops . " hops.\n";
        };
    }
);

__PACKAGE__->attr('default_headers');

__PACKAGE__->attr('follow_redirects' => 1);

# pipeline_method: 'none' / 'horizontal' / 'vertical'
__PACKAGE__->attr('pipeline_method' => 'none');

__PACKAGE__->attr('redirect_limit' => 10);

__PACKAGE__->attr('validate_cookie_paths' => 0);


__PACKAGE__->attr('_count' => 0);

__PACKAGE__->attr('_client' => sub { Mojo::Client->new });

__PACKAGE__->attr('_maxconnections' => 3);
__PACKAGE__->attr('_maxpipereqs' => 4);

__PACKAGE__->attr('_active' => sub { {} });
__PACKAGE__->attr('_ondeck' => sub { {} });


# Subroutine declarations
sub _add_pipe_no;
sub _add_pipe_h;
sub _add_pipe_v;

__PACKAGE__->attr(
    '_add_methods' => sub {
        {   'none'       => \&_add_pipe_no,
            'horizontal' => \&_add_pipe_h,
            'vertical'   => \&_add_pipe_v,
        };
    }
);

# Subroutine declarations
sub _find_finished_nopipe;
sub _find_finished_pipe;

__PACKAGE__->attr(
    '_find_finished' => sub {
        {   'none'       => \&_find_finished_nopipe,
            'horizontal' => \&_find_finished_pipe,
            'vertical'   => \&_find_finished_pipe
        };
    }
);

sub new {
    my $self = shift->SUPER::new();
    $self->_client->keep_alive_timeout(30);
    return $self;
}

sub cookies_for_url {
    my $self = shift;

    my $resp_cookies = $self->cookie_jar->cookies_for_url(@_);

    return [] unless @{$resp_cookies};

    # now make request cookies
    my @req_cookies = ();
    for my $rc (@{$resp_cookies}) {
          my $cookie = Mojo::Cookie::Request->new;
          $cookie->name($rc->name);
          $cookie->value($rc->value);
          $cookie->path($rc->path);
          $cookie->version($rc->version) if defined $rc->version;

          push @req_cookies, $cookie;
    }

    return [@req_cookies];
}

sub crank_all {
    my $self = shift;

    my $active_count = 0;
    for my $id (keys %{$self->_active}) {
        $active_count += $self->crank_dest($id);
    }
    return $active_count;
}

sub crank_dest {
    my $self = shift;
    my $dest = shift;

    # Update the active queue
    my $active = $self->_update_active($dest);

    return 0 unless (@{$active}); # nothing currently active for this host:port

    $self->app ? $self->_spin_app($active) : $self->_spin($active);

    my @still_active;
    my @finished;

    # Use appropriate sub to find finished txs based on pipelining method
    my $ff_sub = $self->_find_finished->{$self->pipeline_method};
    $self->$ff_sub($active, \@still_active, \@finished);

    for my $tx (@finished) {

        # TODO: need to check for tx errors here!
        $self->{_count}++;

        # Check for cookies
        $self->_extract_cookies($tx);

        # Check for redirect
        my $redirect = 0;
        my $method;
        my $location;

        if (   $tx->res->is_status_class(300)
            && $self->follow_redirects
            && $tx->hops < $self->redirect_limit
            && ($location = $tx->res->headers->header('Location')))
        {

            # Presumably 304 (not modified) shouldn't include
            # a Location so shouldn't come in here...
            my $code = $tx->res->code;

            if ($code == 301 || $code == 302 || $code == 307) {
                if ($tx->req->method eq 'GET' || $tx->req->method eq 'HEAD') {
                    $redirect = 1;
                    $method   = $tx->req->method;
                }
                elsif ($self->allow_post_redirect) {

                    # This setting allows automated POST redirection to a GET
                    # for a different resource.  This goes against the
                    # current HTTP/1.1 specification, but appears to be
                    # most browsers' default behavior...
                    $redirect = 1;
                    $method   = 'GET';
                }
            }
            elsif ($code == 303) {
                $redirect = 1;
                $method   = 'GET';
            }
            elsif ($code == 305) {

                # Set up a proxied request (TODO)
                $tx->error('Proxy support not yet implemented');
            }
            else {

                # unknown 3xx response... what to do?
                $tx->error('Unknown 3xx response');
            }

        }


        if ($redirect) {

            my $newurl = Mojo::URL->new();
            $newurl->parse($location);
            my $oldurl = $tx->req->url;

            # Deal with relative redirection
            $newurl->scheme($oldurl->scheme)       unless $newurl->is_abs;
            $newurl->authority($oldurl->authority) unless $newurl->is_abs;

            unless ($newurl->path =~ m{^/}) {
                $newurl->path($oldurl->path->append($newurl->path));
            }

            my $new_tx = MojoX::UserAgent::Transaction->new(
                {   url          => $newurl,
                    method       => $method,
                    id           => $tx->id,
                    hops         => $tx->hops + 1,
                    callback     => $tx->done_cb,
                    ua           => $self,
                    original_req => (
                          $tx->original_req
                        ? $tx->original_req
                        : $tx->req
                    )
                }
            );
            $self->spool($new_tx);

        }
        else {

            # Invoke Callback
            $tx->done_cb->($self, $tx);
        }
    }

    # Put those not finished back into the active array for this host:port
    push @{$active}, @still_active;

    return scalar @{$active};
}

sub get {
    my $self = shift;
    my $url = shift;
    my $cb = shift || $self->default_done_cb;

    my $tx = MojoX::UserAgent::Transaction->new(
        {   url      => $url,
            callback => $cb,
            ua       => $self
        }
    );
    $self->spool($tx);
    1;
}

sub is_idle {
    my $self = shift;

    return (!(scalar keys %{$self->_active})
             && !(scalar keys %{$self->_ondeck}));
}

sub maxconnections {
    my $self = shift;
    my $value = shift;

    return $self->_maxconnections unless $value;

    $self->is_idle
      ? return $self->_maxconnections($value)
      : return $self->_maxconnections;
}

sub maxpipereqs {
    my $self = shift;
    my $value = shift;

    return $self->_maxpipereqs unless $value;

    $self->is_idle
      ? return $self->_maxpipereqs($value)
      : return $self->_maxpipereqs;
}

sub post {
    my $self = shift;
    my $url = shift;
    my $cb = shift || $self->default_done_cb;

    my $tx = MojoX::UserAgent::Transaction->new(
        {   method   => 'POST',
            url      => $url,
            callback => $cb,
            ua       => $self
        }
    );
    $self->spool($tx);
    1;
}

sub run_all {
    my $self = shift;

    while (1) {
        $self->crank_all;
        last if $self->is_idle;
    }
}

sub spool {
    my $self = shift;
    my $new_transactions = (ref $_[0] eq 'ARRAY') ? shift : [@_];

    for my $tx (@{$new_transactions}) {
        my ($scheme, $host, $port) = $tx->client_info;

        my $id = "$host:$port";
        if (my $ondeck = $self->_ondeck->{$id}) {
            push @{$ondeck}, $tx;
        }
        else {
            $self->_ondeck->{$id} = [$tx];
            $self->_active->{$id} = [];
        }
    }
    1;
}

sub _extract_cookies {
    my ($self, $tx) = @_;

    my $cookies = $tx->res->cookies;

    if (@{$cookies}) {
        my $cleared = $self->_scrub_cookies($tx, $cookies);
        $self->cookie_jar->store($cleared) if @{$cleared};
    }


    1;
}

sub _find_finished_pipe {
    my ($self, $active, $still_active, $finished) = @_;

    while (my $tx = shift @{$active}) {
        if ($tx->is_finished) {

            # if it's a pipeline, we must unpack
            if (ref $tx eq 'Mojo::Transaction::Pipeline') {
                while (my $inner = shift @{$tx->finished}) {
                    push @{$finished}, $inner;
                }

                # We must also unpack from the other two queues...
                while (my $inner =
                    (shift @{$tx->inactive} || shift @{$tx->active}))
                {
                    unless ($inner->has_error) {
                        $tx->has_error
                          ? $inner->error($tx->error)
                          : $inner->error('Something weird happened');
                    }
                    push @{$finished}, $inner;
                }

            }
            else {
                push @{$finished}, $tx;
            }
        }
        else {
            # if it's a pipeline, look for finished single transactions within
            if (ref $tx eq 'Mojo::Transaction::Pipeline') {
                while (my $inner = shift @{$tx->finished}) {
                    push @{$finished}, $inner;
                }
            }

            push @{$still_active}, $tx;
        }
    }

}

sub _find_finished_nopipe {
    my ($self, $active, $still_active, $finished) = @_;

    while (my $tx = shift @{$active}) {
        $tx->is_finished
          ? push @{$finished}, $tx
          : push @{$still_active}, $tx;
    }

}

sub _add_pipe_h_or_v() {
    my ($self, $h_or_v, $slots, $ondeck, $active) = @_;

    my $queue_max = $slots * $self->maxpipereqs;

    my @stage;
    my $i=0;
    my $j=0;
    my $queued=0;

    while ($queued < $queue_max && @{$ondeck}) {

        $stage[$i] = [] unless $stage[$i];

        $stage[$i]->[$j] = shift @{$ondeck};
        $queued++;

        if ($h_or_v) {

            # Vertical
            $j++;
            if ($j == $self->maxpipereqs) {
                $j = 0;
                $i++;
            }
        }
        else {

            # Horizontal
            $i++;
            if ($i == $slots) {
                $i = 0;
                $j++;
            }
        }
    }

    foreach my $slot (@stage) {
        if (scalar @{$slot} == 1) {
            push @{$active}, $slot->[0];
        }
        else {
            my $pipe = Mojo::Transaction::Pipeline->new(@{$slot});
            push @{$active}, $pipe;
        }
    }
}

sub _add_pipe_h {
    my $self= shift;

    $self->_add_pipe_h_or_v(0, @_);

}

sub _add_pipe_no {
    my ($self, $slots, $ondeck, $active) = @_;

    my $i=0;
    while ($i<$slots && @{$ondeck}) {
        push @{$active}, (shift @{$ondeck});
        $i++;
    }
}

sub _add_pipe_v() {
    my $self= shift;

    $self->_add_pipe_h_or_v(1, @_);

}

sub _scrub_cookies {
    my $self = shift;
    my $tx = shift;
    my $cookies = shift;

    my @cleared = ();

    for my $cookie (@{$cookies}) {

        # Domain check
        if ($cookie->domain) {

            my $domain = $cookie->domain;
            my $host   = $tx->req->url->host;

            # strip any leading dot
            $cookie->domain($domain) if ($domain =~ s/^\.//);

            unless (   $domain =~ m{[\w\-]+\.[\w\-]+$}x
                    && ($host =~ s/\.$domain$//x || $host =~ s/^$domain$//x)
                    && $host !~ m{\.})
            {

                # Note that in theory we should add to this a refusal if
                # the domain matches one of these:
                # http://publicsuffix.org/list/
                next;
            }
        }
        else {
            $cookie->domain($tx->req->url->host);
        }

        # Port check
        if ($cookie->port) {

            # Should be comma separated list of numbers
            next unless $cookie->port =~ m/^[\d\,]+$/;
        }

        # Clean max-age
        if ($cookie->max_age) {

            # Integer number - only digits
            next unless $cookie->max_age =~ m/^\d+$/;
        }

        # Path check
        if ($cookie->path) {

            # Should be a prefix of the request URI
            if ($self->validate_cookie_paths) {
                my $cpath = $cookie->path;
                next unless ($tx->req->url->path =~ m/^$cpath/);
            }
        }
        else {
            $cookie->path($tx->req->url->path);
        }

        push @cleared, $cookie;
    }
    return \@cleared;
}

sub _spin {
    my $self = shift;
    my $txs = shift;

    $self->_client->spin(@{$txs});
}
sub _spin_app {
    my $self = shift;
    my $txs = shift;

    #can only spin one so pick at random
    my $tx = $txs->[int(rand(scalar @{$txs}))];
    $self->_client->spin_app($self->{app}, $tx);
}

sub _update_active {
    my $self = shift;
    my $dest = shift;

    my $ondeck = $self->_ondeck->{$dest};
    my $active = $self->_active->{$dest};

    my $on_count = scalar @{$ondeck};
    my $act_count = scalar @{$active};

    if (!$act_count && !$on_count) {
        # nothing active or ondeck for this host/port: delete hash entries
        delete $self->_ondeck->{$dest};
        delete $self->_active->{$dest};
        return [];
    }

    if (@{$ondeck} && $act_count < $self->maxconnections) {

        # Use appropriate method to add to the active queue
        my $slots = $self->maxconnections - $act_count;
        my $add_sub = $self->_add_methods->{$self->pipeline_method};
        $self->$add_sub($slots, $ondeck, $active);
    }

    return $active;
}


1;
__END__

=head1 NAME

MojoX::UserAgent - An asynchronous user-agent for the Mojo Web Framework.

=head1 SYNOPSIS

    use MojoX::UserAgent;
    my $ua = MojoX::UserAgent->new;

    # Simple

    $ua->default_done_cb(
        sub {
            my ($ua, $tx) = @_;
            $tx->has_error
              ? print $tx->error
              : print $tx->res;
        }
    );

    $ua->get('http://www.google.com/');

    $ua->run_all;

    # More Complicated

    my $tx = MojoX::UserAgent::Transaction->new(
        {   url     => 'http://www.some.host.com/bla/',
            method  => 'POST',
            ua      => $ua,
            id      => '123456',
            headers => {
                'Expect'       => '100-continue',
                'Content-Type' => 'text/plain'
            },
            body     => 'Hello!',
            callback => sub {
                my ($ua, $tx) = @_;
                ok(!$tx->has_error, 'Completed');
                is($tx->id, '123456', 'Request ID');
                is($tx->res->code, 200, 'Status 200');
            }
        }
    };

    $ua->spool($tx);

    while (1) {
        $ua->crank_all;
        # do other stuff
        # ...
        last if $ua->is_idle;
    }


=head1 DESCRIPTION

L<MojoX::UserAgent> is an asynchronous user-agent built upon the Mojo
Web Framework.  It supports basic session cookies, follows
redirections automatically and implements opportunistic HTTP request
pipelining.



=head1 ATTRIBUTES

L<MojoX::UserAgent> implements the following attributes.

=head2 C<allow_post_redirect>

Defaults to 1.  Controls whether to allow a POST to be redirected to a
GET for another resource on a 301 or 302 response.  Default value
immitates common browser behavior (and goes against the current
HTTP/1.1 specification).

=head2 C<agent>

Defaults to 'Mozilla/5.0 (compatible; MojoX::UserAgent/$VERSION)'.
The User-Agent string that is used with every request that is made.

=head2 C<app>

Defaults to undef.  If set, L<MojoX::UserAgent> will send transactions
to your application via Mojo's builtin facility for doing so.  This
doesn't require any network connectivity, and the application doesn't
need to be started separately.  Great for testing.

=head2 C<cookie_jar>

The place where session cookies are stored.  See
L<MojoX::UserAgent::CookieJar>.

=head2 C<default_done_cb>

Defaults to a not particularly useful sub. This is the sub that is
used as a callback for every transaction for which a different
callback is not provided.  Set it.  When invoked, this sub is passed
two arguments: the UserAgent object that performed the transaction and
the transaction itself.

=head2 C<default_headers>

Defaults to undef.  When set to a hash reference, the given key/value
pairs will be added as header names and values to every outgoing
request, unless a different value for a given header is already set in
a given L<MojoX::UserAgent::Transaction> object.  Example:

    $ua->default_headers({ 'Accept-Language' => 'en-us,en;q=0.5'});

=head2 C<follow_redirects>

Defaults to 1.  Whether or not to follow HTTP redirects.

=head2 C<pipeline_method>

Defaults to 'none'.  Other possible values are 'horizontal' and
'vertical'.

=head2 C<redirect_limit>

Defaults to 10.  Number of redirections to allow for any transaction.

=head2 C<validate_cookie_paths>

Defaults to 0.  When activated, cookie paths must be a prefix of the
current request URL.

=head1 METHODS

L<MojoX::UserAgent> inherits all methods from L<Mojo::Base> and
implements the following new ones.

=head2 C<new>

    my $ua = MojoX::UserAgent->new;

=head2 C<cookies_for_url>

    my $cookies = $ua->cookies_for_url('http://www.foo.bar.com/baz/');

Get currently active cookies for a given URL.  This is a callback used
by L<MojoX::UserAgent::Transaction> in order to add cookies to a
request that is about to be sent. Pass in either a URL string or a
Mojo::URL object.  Returns a reference to an array of
Mojo::Cookie::Request objects.

=head2 C<crank_all>

    my $active = $ua->crank_all;

Perform a single IO operation on all currently active connections.
Returns the total number of currently active connections. Note that
this number could be zero without the UA being idle, since
transactions are added to the queue at the beginning of the cycle.
Use is_idle to test whether the UA is done with all currently spooled
requests.

=head2 C<crank_dest>

Perform a single IO operation on all currently active connections to a
given server.  Returns the total number of currently active
connections. Note that this number could be zero without the UA being
idle, since transactions are added to the queue at the beginning of
the cycle.  It is not currently recommended that you use this method
directly - use crank_all instead.

=head2 C<get>

    my $sub = sub { ... };
    $ua->get('http://www.bar.foo.com/baz/', $sub);

A helper method to queue a simple GET request.  The second argument is
facultative.  If not provided, the default_done_cb will be used.

=head2 C<is_idle>

    my $idle = $ua->is_idle;

True if and only if the UserAgent currently has no outstanding
transactions.

=head2 C<maxconnections>

Use as a set-once attribute.  Sets the maximum number of concurrent
connections to a given server.  Any value change will be ignored
unless is_idle is true.

=head2 C<maxpipereqs>

Use as a set-once attribute.  Sets the maximum number of transactions
that may be pipelined to a given server over a given connection.  Any
value change will be ignored unless is_idle is true.

=head2 C<post>

    my $sub = sub { ... };
    $ua->post('http://www.bar.foo.com/baz/', $sub);

A helper method to queue a simple POST request.  The second argument
is facultative.  If not provided, the default_done_cb will be
used. Note that for more complex requests, you should instantiate a
L<MojoX::UserAgent::Transaction> directly and then spool it yourself.

=head2 C<run_all>

   $ua->run_all;

A blocking method that only returns when all spooled transactions
(including intervening redirects) are finished.

=head2 C<spool>

    my $tx = MojoX::UserAgent::Transaction->new(
        { [...]
        }
    );
    $self->spool($tx);

Spool one or a series of L<MojoX::UserAgent::Transaction> objects.
Please see the L<MojoX::UserAgent::Transaction> POD for information on
how to instantiate such objects.

=head1 AUTHOR

Pascal Gaudette <acajou@gmail.com> - L<http://github.com/Acajou>

=head1 LICENSE

See LICENSE file.

=cut
