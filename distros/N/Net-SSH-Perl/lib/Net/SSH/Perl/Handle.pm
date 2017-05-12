package Net::SSH::Perl::Handle;
use strict;
use warnings;

use Net::SSH::Perl::Buffer qw( SSH2 );

use Carp qw( croak );
use Tie::Handle;
use base qw( Tie::Handle );

sub TIEHANDLE {
    my $class = shift;
    my($channel, $mode) = @_;
    my $read = $mode =~ /^[rR]/;
    my $handle = bless { channel => $channel }, $class;
    if ($read) {
        my $incoming = $handle->{incoming} = Net::SSH::Perl::Buffer->new;
        $channel->register_handler("_output_buffer", sub {
            my($channel, $buffer) = @_;
            $incoming->append($buffer->bytes);
            $channel->{ssh}->break_client_loop;
        });
    }
    $handle;
}

sub READ {
    my $h = shift;
    my $buf = $h->{incoming};
    while (!$buf->length) {
        $h->{channel}{ssh}->client_loop;
        croak "Connection closed" unless $buf->length;
    }
    $_[0] = $buf->bytes;
    $buf->empty;
}

sub WRITE {
    my $h = shift;
    my($data) = @_;
    $h->{channel}->send_data($data);
}

=pod

sub DESTROY {
    my $h = shift;
    unless ($h->{incoming}) {
        my $c = $h->{channel};
        my $ssh = $c->{ssh};
        $c->{istate} = CHAN_INPUT_WAIT_DRAIN;
        $c->send_eof;
        $c->{istate} = CHAN_INPUT_CLOSED;
        $ssh->client_loop;
    }
}

=cut

1;
