package Mojolicious::Matterbridge;
use strict;
use warnings;
use Mojo::Base 'Mojo::EventEmitter';
use Moo::Role 2;
use API::Matterbridge::Message;

use feature 'current_sub';
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use URI;
use Mojo::UserAgent;
use API::Matterbridge::Message;

our $VERSION = '0.02';

=head1 NAME

Mojolicious::Matterbridge - a simplistic module to connect to chat servers via matterbridge

=head1 SYNOPSIS

  use Mojolicious::Matterbridge;

  my $client = Mojolicious::Matterbridge->new(
      url => 'http://localhost:4242/api/',
  );

  $client->on('message' => sub( $c, $message ) {
      print sprintf "<%s> %s\n", $message->username, $message->text;
      $client->send( "Haha!" );
  });
  $client->connect();

  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

=cut

with 'API::Matterbridge';
#use Mojo::Future;

has 'stream_ua' => (
    is => 'lazy',
    default => sub {
        Mojo::UserAgent->new(
            inactivity_timeout => 0, # permanent connection to localhost
            max_response_size => 0, # we will be retrieving streams
        ),
    },
);

has 'short_ua' => (
    is => 'lazy',
    default => sub {
        Mojo::UserAgent->new(
            inactivity_timeout => 0, # permanent connection to localhost
        ),
    },
);

has 'token' => (
    is => 'ro',
);

# has 'on_message' # use the Mojo-dispatch feature here

sub build_request( $self, %parameters ) {
    my $ua = $parameters{ ua } or die "No UA?!";
    my $method = delete $parameters{ method };
    my $url    = delete $parameters{ url };
    my $headers   = delete $parameters{ headers } || {};
    my $data   = delete $parameters{ data };
    my $res = $ua->build_tx(
        $method => "$url",
        $headers,
        $data,
    );
    #warn "Built request";
    return $res;
}

sub connect( $self ) {
    # Fetch all the pent up rage
    #$self->get_messages();
    $self->get_stream();
}

sub get_messages( $self ) {
    my $tx = $self->build_get_messages();
    $self->short_ua->start_p($tx)->then(sub($tx) {
        my $payload = $self->json->decode( $tx->result->body );
        for my $message (@$payload) {
            my $m = API::Matterbridge::Message->new( $message );
            $self->emit('message', $m );
        };
    });
};

sub get_stream( $self ) {
    my $tx = $self->build_get_message_stream();

    # Just in case we read half a JSON message
    state $buffer = '';

    # Replace "read" events to disable default content parser
    $tx->res->content->unsubscribe('read')->on(read => sub($content,$bytes) {
        $buffer .= $bytes;

        # Every (full) line should be a JSON stanza
        while( $buffer =~ s!^(.*?)\n!! ) {
            my $m = API::Matterbridge::Message->from_bytes( $1 );
            $self->emit('message', $m );
        };
    });
    # Process transaction
    $tx = $self->stream_ua->start_p($tx);
}

sub send( $self, @messages ) {
    my $msg = shift @messages;
    my $tx = $self->build_post_message(%$msg);
    state @queue;
    my $message_sender = sub($tx) {
        my $next = shift @messages;
        if( $next ) {
            push @queue, $self->short_ua->start_p($next)->then(__SUB__);
        } else {
            @queue = ();
        };
    };

    push @queue, $self->short_ua->start_p($tx)->then($message_sender)->catch(sub {
        use Data::Dumper; warn "Error: " . Dumper \@_;
    });
}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Mojolicious-Matterbridge>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/Mojolicious-Matterbridge/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2020 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
