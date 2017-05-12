use strict;
use warnings;
use Test::More;
use Mojo::TFTPd;
use Mojo::Asset::Memory;

my $ROLLOVER = 256 * 256;

my $tftpd = Mojo::TFTPd->new(retries => 6, retransmit => 1);
my(@error, @finish);
our $DATA;

$tftpd->on(error => sub { shift; push @error, [@_] });
$tftpd->on(finish => sub { shift; push @finish, [@_] });

# save WRQ to a temporary file, to be deleted
$tftpd->on(
    wrq => sub {
        my ( $tftpd, $c ) = @_;
        $c->filehandle(Mojo::Asset::Memory->new);
    }
);

# create a "large" file for sending
my $mem = Mojo::Asset::Memory->new;
$mem->add_chunk(chr( $_ % 256 ) x 13) for 1 .. $ROLLOVER + 3;

$tftpd->on(
    rrq => sub {
        my ( $tftpd, $c ) = @_;
        $c->filehandle($mem);
    }
);

$tftpd->{socket} = bless {}, 'Dummy::Handle';

# rollover for WRQ
{

    $DATA = pack('n', Mojo::TFTPd::OPCODE_WRQ) . join "\0", "wrq.bin", "octet",
        "blksize", "13";
    $tftpd->_incoming;
    isa_ok $tftpd->{connections}{whatever}, 'Mojo::TFTPd::Connection';
    is $DATA, pack('na*', 6, join "\0", "blksize", "13" ), 'WRQ OACK all';

    # these should be just fine, check every so often
    for my $n ( 1 .. $ROLLOVER - 2 ) {
        $DATA = pack( 'nna*', Mojo::TFTPd::OPCODE_DATA, $n, chr( $n % 256 ) x 13 );
        $tftpd->_incoming;
        is $DATA, pack('nn', Mojo::TFTPd::OPCODE_ACK, $n), "packet $n received"
           if not $n % 4099;
    }

    # test every packet around the rollover
    for my $n ( $ROLLOVER - 1 .. $ROLLOVER + 3 ) {
        $DATA = pack( 'nna*', Mojo::TFTPd::OPCODE_DATA, $n, chr( $n % 256 ) x 13 );
        $tftpd->_incoming;
        is $DATA, pack( 'nn', Mojo::TFTPd::OPCODE_ACK, $n % $ROLLOVER ), "packet $n received";
    }

}

# rollover for RRQ
is $mem->size, 13 * ( $ROLLOVER + 3 ), "RRQ file size";
{

    $DATA = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "octet", "blksize", "13";
    $tftpd->_incoming;
    is $DATA, pack('na*', Mojo::TFTPd::OPCODE_OACK, join "\0", "blksize", "13" ), 'RRQ OACK all';
    isa_ok $tftpd->{connections}{whatever}, 'Mojo::TFTPd::Connection';

    # ack start of transmission
    $DATA = pack( 'nn', Mojo::TFTPd::OPCODE_ACK, 0 );

    # these should be just fine, check every so often
    for my $n ( 1 .. $ROLLOVER - 2 ) {
        $tftpd->_incoming;
        is $DATA, pack( 'nna*', Mojo::TFTPd::OPCODE_DATA, $n, chr( $n % 256 ) x 13 ), "packet $n sent"
            if not $n % 4099;
        $DATA = pack( 'nn', Mojo::TFTPd::OPCODE_ACK, $n % $ROLLOVER );
    }

    # test every packet around the rollover
    for my $n ( $ROLLOVER - 1 .. $ROLLOVER + 3 ) {
        $tftpd->_incoming;
        is $DATA, pack( 'nna*', Mojo::TFTPd::OPCODE_DATA, $n, chr( $n % 256 ) x 13 ), "packet $n sent";
        $DATA = pack( 'nn', Mojo::TFTPd::OPCODE_ACK, $n % $ROLLOVER );
    }

}



done_testing;

package Dummy::Handle;
sub recv { $_[1] = $main::DATA }
sub send { $main::DATA = $_[1] }
sub peername { 'whatever' }
sub peerport { 12345 }
sub peerhost { '127.0.0.1' }
1;
