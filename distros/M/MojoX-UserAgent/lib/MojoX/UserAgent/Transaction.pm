# Copyright (C) 2009, Pascal Gaudette.

package MojoX::UserAgent::Transaction;

use warnings;
use strict;

use base 'Mojo::Transaction::Single';

use Carp 'croak';

__PACKAGE__->attr('done_cb');
__PACKAGE__->attr('hops' => 0);
__PACKAGE__->attr('id');
__PACKAGE__->attr('original_req');
__PACKAGE__->attr('ua');

sub new {
    my $self = shift->SUPER::new();

    my ($arg_ref) = @_;
    my $req = $self->req;

    croak('Missing arguments')
      if (   !defined($arg_ref->{url})
          || !defined($arg_ref->{ua}));

    $self->res->code(999); # Default response status should not be 200

    my $url = $arg_ref->{url};
    ref $url && $url->isa('Mojo::URL')
      ? $req->url($url)
      : $req->url->parse($url);

    $self->ua($arg_ref->{ua});

    $arg_ref->{callback}
      ? $self->done_cb($arg_ref->{callback})
      : $self->done_cb($self->ua->default_done_cb);

    if ($arg_ref->{headers}) {
        my $headers = $arg_ref->{headers};
        for my $name (keys %{$headers}) {
            $req->headers->header($name, $headers->{$name});
        }
    }

    $req->method($arg_ref->{method}) if $arg_ref->{method};
    $req->body($arg_ref->{body}) if $arg_ref->{body};

    $self->id($arg_ref->{id}) if $arg_ref->{id};

    # Not sure if I should allow hops or
    # original_req in the constructor...
    $self->hops($arg_ref->{hops}) if $arg_ref->{hops};
    $self->original_req($arg_ref->{original_req}) if $arg_ref->{original_req};

    return $self;
}

sub client_connect {
    my $self = shift;

    my $ua = $self->ua;

    # Add default headers

    if (my $dh = $ua->default_headers) {
        for my $name (keys %{$dh}) {
            $self->req->headers->header($name, $dh->{$name})
              unless $self->req->headers->header($name);
        }
    }

    # Add cookies
    # (What if req already had some cookies?)

    my $cookies = $ua->cookies_for_url($self->req->url);
    $self->req->cookies(@{$cookies});

    # Add User-Agent identification

    unless ($self->req->headers->user_agent) {
        my $ua_str = $ua->agent;
        $self->req->headers->user_agent($ua_str) if $ua_str;
    }

    $self->SUPER::client_connect();
    return $self;
}
1;

=head1 NAME

MojoX::UserAgent::Transaction - Basic building block of
L<MojoX::UserAgent>, encapsulates a single HTTP exchange.

=head1 SYNOPSIS

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


=head1 DESCRIPTION

A subclass of L<Mojo::Transaction::Single>, this class simply adds
the few extra elements that are needed by L<MojoX::UserAgent>.


=head1 ATTRIBUTES

This class inherits all the attributes of L<Mojo::Transaction::Single>, and
adds the following.

=head2 C<done_cb>

The subroutine that will be called once the transaction is completed.
When invoked, this sub is passed two arguments: the UserAgent object
that performed the transaction and the transaction itself.

=head2 C<hops>

The number of hops (ie redirects) that this transaction has gone through.

=head2 C<id>

An optional transaction identifier. Not used internally by the class,
but preserved across redirects and accessible to the callback.

=head2 C<original_req>

If the transaction is redirected, this holds the original request object.

=head2 C<ua>

A pointer back to the L<MojoX::UserAgent> to which this transaction was
spooled.


=head1 METHODS

L<MojoX::UserAgent::Transaction> inherits all methods from
L<Mojo::Transaction::Single> and implements the following new ones.


=head2 C<new>

Constructor that accepts a reference to a hash of named arguments.
This hash must contain the following key/value pairs:

=over 2

=item *

key: 'url' value: either a string or a L<Mojo::URL> object;

=item *

key: 'ua'  value: a reference to the L<Mojox::UserAgent> object
to which this transaction belongs.

=back

It may also contain any/all of the following:

=over 7

=item *

key: 'callback' value: the callback subroutine that will be
called when this transaction is finished (see done_cb above);

=item *

key: 'headers' value: a reference to a hash of request headers
(see L<Mojo::Message::Request>);

=item *

key: 'method' value: the HTTP method to be used in the request;

=item *

key: 'body' value: the contents of the body of the request;

=item *

key: 'id' value: the value of the id attribute (see above);

=item *

key: 'hops' value: the value of the hops attribute (see above,
  should only be set by the User-Agent);

=item *

key: 'original_req' value: the original L<Mojo::Message::Request>
object iff hops isn't 0.

=back

=head2 C<client_connect>

Called when the transaction is about to be sent out, this method is
used to add the User-Agent and request cookies to the outgoing
request.

=cut
