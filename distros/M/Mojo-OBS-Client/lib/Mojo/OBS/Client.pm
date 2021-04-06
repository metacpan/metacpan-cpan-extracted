package Mojo::OBS::Client;
use 5.012;
use Moo;
use Mojo::UserAgent;
use Encode qw( encode decode );
use Mojo::JSON 'decode_json', 'encode_json';
use Net::Protocol::OBSRemote;
use Future::Mojo;

our $VERSION = '0.01';

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
with 'Moo::Role::RequestReplyHandler';

use Carp 'croak';

=head1 NAME

Mojo::OBS::Client - Mojolicious client for the OBS WebSocket remote plugin

=head1 SYNOPSIS

  use feature 'signatures';

  my $obs = Mojo::OBS::Client->new;
  $obs->login('ws://localhost:4444', 'secret')->then(sub {
      $obs->SetTextFreetype2Properties( source => 'Text.NextTalk',text => 'Hello World')
  })->then(sub {
      $obs->GetSourceSettings( sourceName => 'VLC.Vortrag', sourceType => 'vlc_source')
  });

=cut

=head1 ACCESSORS

=head2 C<< ->ioloop >>

Access the underlying L<Mojo::IOLoop>

=cut

has ioloop => (
    is => 'ro',
    default => sub {
        return Mojo::IOLoop->new();
    },
);

=head2 C<< ->ua >>

Access the L<Mojo::UserAgent> object used to talk to OBS.

=cut

has ua => (
    is => 'ro',
    default => sub {
        return Mojo::UserAgent->new();
    },
);

=head2 C<< ->tx >>

The websocket connection to OBS.

=cut

has tx => (
    is => 'rw',
);

=head2 C<< ->protocol >>

The L<Net::Protocol::OBSRemote> instance used to generate the OBS messages.

=cut

has protocol => (
    is => 'ro',
    default => sub {
        return Net::Protocol::OBSRemote->new();
    },
);

=head2 C<< ->debug >>

Switch on debug messages to STDERR. Also enabled if
C<< $ENV{PERL_MOJO_OBS_CLIENT_DEBUG} >> is set to a true value.

=cut

has debug => (
    is => 'ro',
    default => sub {
        return !!$ENV{PERL_MOJO_OBS_CLIENT_DEBUG};
    },
);

=head1 METHODS

=cut

sub future($self, $loop=$self->ioloop) {
    Future::Mojo->new( $loop )
}

sub get_reply_key($self,$msg) {
    $msg->{'message-id'}
};

sub connect($self,$ws_url) {
    my $res = $self->future();

    $self->ua->websocket(
       $ws_url,
    => { 'Sec-WebSocket-Extensions' => 'permessage-deflate' }
    => []
    => sub($dummy, $_tx) {
            my $tx = $_tx;
            $self->tx( $tx );
            if( ! $tx->is_websocket ) {
                say 'WebSocket handshake failed!';
                $res->fail('WebSocket handshake failed!');
                return;
            };

            $tx->on(finish => sub {
                my ($tx, $code, $reason) = @_;
                #if( $s->_status ne 'shutdown' ) {
                #    say "WebSocket closed with status $code.";
                #};
            });

            $tx->on(message => sub($tx,$msg) {
                # At least from Windows, OBS sends Latin-1 in JSON
                my $payload = decode_json(encode('UTF-8',decode('Latin-1', $msg)));

                if( my $type = $payload->{"update-type"}) {
                    if( $self->debug ) {
                        require Data::Dumper;
                        say "*** " . Data::Dumper::Dumper( $msg );
                    };
                    $self->event_received( $type, $payload );
                } elsif( my $id = $self->get_reply_key( $payload )) {
                    if( $self->debug ) {
                        require Data::Dumper;
                        say "<== " . Data::Dumper::Dumper( $msg );
                    };
                    $self->message_received($payload);
                };
            });

            $res->done();
       },
    );
    return $res;
}

sub shutdown( $self ) {
    $self->tx->finish;
}

sub send_message($self, $msg) {
    my $res = $self->future();

    if( $self->debug ) {
        require Data::Dumper;
        say "==> " . Data::Dumper::Dumper( $msg );
    };
    my $id = $msg->{'message-id'};
    $self->on_message( $id, sub($response) {
        $res->done($response);
    });
    $self->tx->send( encode_json( $msg ));
    return $res
};

=head1 METHODS

For the OBS methods, see L<Net::Protocl::OBSRemote>.

=cut

# We delegate all unknown methods to $self->protocol
sub AUTOLOAD( $self, @args ) {
    our $AUTOLOAD =~ /::(\w+)$/
        or croak "Weird AUTOLOAD method '$AUTOLOAD'";
    return if $1 eq 'DESTROY';
    my $method = $self->protocol->can("$1")
        or croak "Unknown OBS method '$1'";

    my $payload = $method->($self->protocol, @args);
    return $self->send_message( $payload );
}

=head2 C<< ->login $url, $password >>

    $obs->login('ws://localhost:4444', 'secret')
    ->then(sub( $res ){
        if( $res->{error} ) {
            warn $res->{error};
            return
        };
    })

Performs the login authentication with the OBS websocket

=cut

sub login( $h, $url, $password ) {
    return $h->connect($url)->then(sub {
        $h->GetVersion();
    })->then(sub {
        $h->GetAuthRequired();
    })->then(sub( $challenge ) {
        $h->Authenticate($password,$challenge);
    });
};

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Mojo-OBS-Client>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/Mojo-OBS-Client/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2021-2021 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
