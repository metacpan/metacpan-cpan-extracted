package Net::Rexster::Request;

use warnings;
use strict;
use Carp;

use Moose;
use LWP::UserAgent;
use Net::Rexster::Response;
use Encode;
use JSON;
use URI::Escape;
use utf8;

has 'ua' => (is => 'ro', isa => "LWP::UserAgent", default => sub { LWP::UserAgent->new } );

__PACKAGE__->meta->make_immutable;
no Moose;

sub get { shift->_call('GET', @_) }
sub post { shift->_call('POST', @_) }
sub put { shift->_call('PUT', @_) }
sub delete { shift->_call('DELETE', @_) }

# Send query to server by LWP::UserAgent
sub _call {
    my ($self, $method, $uri, $data, $args) = @_;

    # URI encoding for # and the language which needs ecoding, e.g. Japanese
    $uri = uri_escape_utf8($uri, "^A-Za-z0-9\/\:\&\+\=\?\(\)\'\,\*\;");
    my $req = HTTP::Request->new($method, $uri);

    my $response = $self->ua->request($req);
    unless ($response->is_success){
        warn "Failed to get response from server...\n";
        return Net::Rexster::Response->new(content => {});
    }

    # Decode from JSON and utf8
    return Net::Rexster::Response->new(content => JSON->new->utf8->decode(decode_utf8($response->content))); 
}

1; # Magic true value required at end of module
