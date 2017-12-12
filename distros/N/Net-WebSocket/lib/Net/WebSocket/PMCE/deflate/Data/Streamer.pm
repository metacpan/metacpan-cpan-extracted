package Net::WebSocket::PMCE::deflate::Data::Streamer;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::WebSocket::PMCE::deflate::Data::Streamer

=head1 SYNOPSIS

    my $streamer = $deflate_data->create_streamer( $frame_class );

    #These frames form a single compressed message in three
    #fragments whose content is “onetwothree”.
    my @frames = (
        $streamer->create_chunk('one'),
        $streamer->create_chunk('two'),
        $streamer->create_final('three'),
    );

=head1 DESCRIPTION

This class implements fragmentation for the permessage-deflate WebSocket
extension. It allows you to send a single message in arbitrarily many
parts. The class is not instantiated directly, but instances are returned
as the result of L<Net::WebSocket::PMCE::deflate::Data>’s
C<create_streamer()> method.

Strictly speaking, this is a base class; the C<::Client> and C<::Server>
subclasses implement a bit of logic specific to either endpoint type.

The C<create_chunk()> and C<create_final()> methods follow the same
pattern as L<Net::WebSocket::Streamer>.

=cut

use Module::Load ();

use Net::WebSocket::Frame::continuation ();

=head1 METHODS

=cut

sub new {
    my ($class, $data_obj, $frame_class) = @_;

    Module::Load::load($frame_class);

    my $self = {
        _data_obj => $data_obj,
        _frame_class => $frame_class,
    };

    return bless $self, $class;
}

my ($_COMPRESS_FUNC, $_FIN);

=head2 I<OBJ>->create_chunk( OCTET_STRING )

Compresses OCTET_STRING. The compressor doesn’t necessarily produce output
from this, however. If the compressor does produce output, then this
method returns a frame object (an instance of either the streamer’s
assigned frame class or L<Net::WebSocket::Frame::continuation>); otherwise,
undef is returned.

=cut

sub create_chunk {
    $_COMPRESS_FUNC = '_compress_non_final_fragment';
    $_FIN = 0;

    goto &_create;
}

=head2 I<OBJ>->create_final( OCTET_STRING )

Compresses OCTET_STRING and flushes the compressor. The output matches
that of C<create_chunk()> except that the output is always a frame object.
The output of this method will complete the message.

=cut

sub create_final {
    $_COMPRESS_FUNC = $_[0]->{'_data_obj'}{'final_frame_compress_func'};
    $_FIN = 1;

    goto &_create;
}

sub _create {
    my ($self) = @_;

    my $data_obj = $self->{'_data_obj'};

    my $payload_sr = \($data_obj->$_COMPRESS_FUNC( $_[1] ));

    return undef if !length $$payload_sr;

    my $class = $self->{'_frames_count'} ? 'Net::WebSocket::Frame::continuation' : $self->{'_frame_class'};
    my $rsv = $self->{'_frames_count'} ? 0 : $data_obj->INITIAL_FRAME_RSV();

    $self->{'_frames_count'}++;

    return $class->new(
        payload => $payload_sr,
        rsv => $rsv,
        $data_obj->FRAME_MASK_ARGS(),
    );
}

1;
