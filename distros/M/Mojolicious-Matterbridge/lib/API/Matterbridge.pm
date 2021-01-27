package API::Matterbridge;
use strict;
use warnings;
use Moo::Role 2;

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use URI;

requires 'build_request', 'short_ua', 'stream_ua';

our $VERSION = '0.01';

=head1 SEE ALSO

L<https://app.swaggerhub.com/apis-docs/matterbridge/matterbridge-api/0.1.0-oas3>

=cut

# Naah, this should move straight to Mojolicious
# instead of separating out a protocol module that can be used elsewhere ...
# The message stream (via /api/stream) needs special async handling and can't
# be used with (for example) LWP

has 'url' => (
    is => 'lazy',
    default => sub { URI->new( 'http://localhost:4242/api/' ) },
);

has 'health_url' => (
    is => 'lazy',
    default => sub { URI->new( $_[0]->url . 'health' ) },
);

has 'message_url' => (
    is => 'lazy',
    default => sub { URI->new( $_[0]->url . 'message' ) },
);

has 'messages_url' => (
    is => 'lazy',
    default => sub { URI->new( $_[0]->url . 'messages' ) },
);

has 'stream_url' => (
    is => 'lazy',
    default => sub { URI->new( $_[0]->url . 'stream' ) },
);

has 'json' => (
    is => 'lazy',
    default => sub {
        require JSON;
        return JSON->new()
    },
);

sub build_post_message( $self, %options ) {
    $self->build_request(
        method => 'POST',
        url    => $self->message_url,
        headers => {
            'Content-Type' => 'application/json',
        },
        data   => $self->json->encode( \%options ),
        ua     => $self->short_ua,
    );
}

sub build_get_messages( $self ) {
    $self->build_request(
        method => 'GET',
        url    => $self->messages_url,
        ua     => $self->short_ua,
    );
}

sub build_get_message_stream( $self ) {
    $self->build_request(
        method => 'GET',
        url    => $self->stream_url,
        ua     => $self->stream_ua,
    );
}

1;
