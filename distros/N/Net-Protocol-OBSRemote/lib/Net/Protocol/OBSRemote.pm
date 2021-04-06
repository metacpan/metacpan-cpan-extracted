package Net::Protocol::OBSRemote;
use strict;
use warnings;
use Digest::SHA 'sha256_base64';
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.01';

=head1 NAME

Net::Protocol::OBSRemote - event-loop agnostic protocol to control OBS via the WebSocket plugin

=head1 SYNOPSIS

    my $protocol = Net::Protocol::OBSRemote->new();
    my $message = $protocol->GetVersion();

    my $result = $obs_connection->send_message( $message );

See L<Mojo::OBS::Client> for a Mojolicious implementation. This module merely
abstracts constructing the messages.

=cut

has id => (
    is => 'rw',
    default => 1,
);

sub nextMessage($self,$msg) {
    my $id = $self->{id}++;
    $msg->{"message-id"} = "$id";
    return $msg;
}

=head1 SEE ALSO

L<https://github.com/Palakis/obs-websocket/blob/4.x-current/docs/generated/protocol.md>

=cut

# See https://github.com/Palakis/obs-websocket/blob/4.x-current/docs/generated/comments.json
# for the non-code version of this

sub GetVersion($self) {
    return $self->nextMessage({'request-type' => 'GetVersion'})
}

sub GetAuthRequired($self) {
    return $self->nextMessage({'request-type' => 'GetAuthRequired'})
}

sub Authenticate($self,$password,$saltMsg) {
    my $hash = sha256_base64( $password, $saltMsg->{salt} );
    while( length( $hash )% 4) {
        $hash .= '=';
    };
    my $auth_response = sha256_base64( $hash, $saltMsg->{challenge} );
    while( length( $auth_response ) % 4) {
        $auth_response .= '=';
    };

    my $payload = {
        'request-type' => 'Authenticate',
        'auth' => $auth_response,
    };
    return $self->nextMessage($payload)
}

sub GetTextFreetype2Properties($self,%properties) {
    return $self->nextMessage({
        'request-type' => 'GetTextFreetype2Properties',
        %properties,
    })
};

sub SetTextFreetype2Properties($self,%properties) {
    return $self->nextMessage({
        'request-type' => 'SetTextFreetype2Properties',
        %properties,
    })
};

sub GetSourceSettings($self,%sourceInfo) {
    return $self->nextMessage({
        'request-type' => 'GetSourceSettings',
        %sourceInfo,
    })
};

sub SetSourceSettings($self,%sourceInfo) {
    return $self->nextMessage({
        'request-type' => 'SetSourceSettings',
        %sourceInfo,
    })
};

sub GetMediaSourcesList($self) {
    return $self->nextMessage({
        'request-type' => 'GetMediaSourcesList',
    })
}

sub GetMediaDuration($self, $sourceName) {
    return $self->nextMessage({
        'request-type' => 'GetMediaDuration',
        sourceName => $sourceName,
    })
}

sub GetMediaTime($self, $sourceName) {
    return $self->nextMessage({
        'request-type' => 'GetMediaTime',
        sourceName => $sourceName,
    })
}

sub GetMediaState($self, $sourceName) {
    return $self->nextMessage({
        'request-type' => 'GetMediaState',
        'sourceName' => $sourceName,
    })
}

sub GetCurrentScene($self) {
    return $self->nextMessage({
        'request-type' => 'GetCurrentScene',
    })
}

=head2 C<< ->SetCurrentScene $sceneName >>

Sets the current broadcast scene

=cut

sub SetCurrentScene($self, $sceneName) {
    return $self->nextMessage({
        'request-type' => 'SetCurrentScene',
        'scene-name' => $sceneName
    })
}

=head2 C<< ->GetPreviewScene >>

Gets the current preview scene

=cut

sub GetPreviewScene($self) {
    return $self->nextMessage({
        'request-type' => 'GetPreviewScene',
    })
}

=head2 C<< ->SetPreviewScene $sceneName >>

Sets the current preview scene

=cut

sub SetPreviewScene($self, $sceneName) {
    return $self->nextMessage({
        'request-type' => 'SetPreviewScene',
        'scene-name' => $sceneName
    })
}

sub StartRecording($self) {
    return $self->nextMessage({
        'request-type' => 'StartRecording',
    })
}

sub StopRecording($self) {
    return $self->nextMessage({
        'request-type' => 'StopRecording',
    })
}

sub SetMute($self,%sourceInfo) {
    return $self->nextMessage({
        'request-type' => 'SetMute',
        %sourceInfo,
    })
};

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Net-Protocol-OBSRemote>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/Net-Protocol-OBSRemote/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2021-2021 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
