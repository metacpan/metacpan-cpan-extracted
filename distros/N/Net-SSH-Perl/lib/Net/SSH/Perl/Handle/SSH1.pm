package Net::SSH::Perl::Handle::SSH1;
use strict;
use warnings;

use Net::SSH::Perl::Buffer;
use Net::SSH::Perl::Constants qw(
    SSH_SMSG_STDOUT_DATA
    SSH_SMSG_EXITSTATUS
    SSH_CMSG_STDIN_DATA
    SSH_CMSG_EOF );

use constant CHUNK_SIZE => 32000;

use Tie::Handle;
use base qw( Tie::Handle );

sub TIEHANDLE {
    my $class = shift;
    my($mode, $ssh) = @_;
    my $read = $mode =~ /^[rR]/;
    my $handle = bless { ssh => $ssh }, $class;
    if ($read) {
        my $incoming = $handle->{incoming} =
            Net::SSH::Perl::Buffer->new( MP => 'SSH1' );
        $ssh->register_handler(SSH_SMSG_STDOUT_DATA, sub {
            my($ssh, $packet) = @_;
            $incoming->append($packet->get_str);
            $ssh->break_client_loop;
        });
        $ssh->register_handler(SSH_SMSG_EXITSTATUS,
            sub { $handle->{exit} = $_[1]->get_int32 });
    }
    $handle;
}

sub READ {
    my $h = shift;
    my $buf = $h->{incoming};
    $_[0] = undef, return 0 unless $buf->length || !$h->EOF;
    while (!$buf->length) {
        $h->{ssh}->_start_interactive;
        $_[0] = undef, return 0 unless $buf->length;
    }
    $_[0] = $buf->bytes;
    $buf->empty;
    length($_[0]);
}

sub WRITE {
    my $h = shift;
    my($data) = @_;
    my $len = length($data);
    while ($data) {
        my $chunk = substr($data, 0, CHUNK_SIZE, '');
        my $packet = $h->{ssh}->packet_start(SSH_CMSG_STDIN_DATA);
        $packet->put_str($chunk);
        $packet->send;
    }
    $len;
}

sub EOF { defined $_[0]->{exit} ? 1 : 0 }

sub CLOSE {
    my $h = shift;
    unless ($h->{incoming}) {
        my $ssh = $h->{ssh};
        my $packet = $ssh->packet_start(SSH_CMSG_EOF);
        $packet->send;
        $ssh->_start_interactive;
    }
    1;
}

1;
