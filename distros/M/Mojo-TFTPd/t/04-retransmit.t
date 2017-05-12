use strict;
use warnings;
use Test::More;
use Mojo::TFTPd;


my $tftpd = Mojo::TFTPd->new(retries => 6, retransmit => 1);
my(@error, @finish);
our $DATA;

$tftpd->on(error => sub { shift; push @error, [@_] });
$tftpd->on(finish => sub { shift; push @finish, [@_] });

{
    $tftpd->{socket} = bless {}, 'Dummy::Handle';
    @error = ();
    $tftpd->on(rrq => sub {
        my($tftpd, $c) = @_;
        my $FH;
        $c->filehandle($FH) if open $FH, '<', 't/data/' .$c->file;
        $c->filesize(-s 't/data/' .$c->file);
    });

    $DATA = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "doesntexist", "ascii";
    $tftpd->_incoming;

    ok $tftpd->{connections}{whatever}, 'rrq connection does not exists on invalid file';
    is $DATA, pack('nnZ*', Mojo::TFTPd::OPCODE_ERROR, 1, "File not found"), 'doesntexist result in error';
    $DATA = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
    $tftpd->_incoming;
    is $finish[0][1], 'No filehandle', 'error on ack of error';
}

{
    $DATA = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "ascii",
        "blksize", "200", "tsize", "0";
    $tftpd->_incoming;
    isa_ok $tftpd->{connections}{whatever}, 'Mojo::TFTPd::Connection';
    is $DATA, pack('na*', 6, join "\0",
    "blksize", "200", "tsize", "512"), 'RRQ OACK all';

    $DATA = pack('nn', Mojo::TFTPd::OPCODE_ACK, 0);
    $tftpd->_incoming;
    is $DATA, pack('nna*', 3, 1, (1 x 200)), 'rrq.bin seq 1 was sent';

    $DATA = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
    $tftpd->_incoming;
    is $DATA, pack('nna*', 3, 2, (1 x 200)), 'rrq.bin seq 2 was sent';

    $DATA = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
    $tftpd->_incoming;
    # data should not be changed
    is $DATA, pack('nn', Mojo::TFTPd::OPCODE_ACK, 1), 'rrq.bin dup ack 1';
    # retries not changed
    is $tftpd->{connections}{whatever}{retries}, 6, 'rrq.bin seq 2';

    $DATA = pack('nn', Mojo::TFTPd::OPCODE_ACK, 5);
    $tftpd->_incoming;
    is $tftpd->{connections}{whatever}{retries}, 5, 'rrq.bin seq 5';

    $DATA = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
    $tftpd->_incoming;
    is $tftpd->{connections}{whatever}{retries}, 5, 'rrq.bin seq 1';

    # disable retransmit
    $tftpd->{connections}{whatever}{retransmit} = 0;

    $DATA = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
    $tftpd->_incoming;
    is $tftpd->{connections}{whatever}{retries}, 4, 'rrq.bin seq 1 no retransmit';
}


done_testing;

package Dummy::Handle;
sub recv { $_[1] = $main::DATA }
sub send { $main::DATA = $_[1] }
sub peername { 'whatever' }
sub peerport { 12345 }
sub peerhost { '127.0.0.1' }
1;
