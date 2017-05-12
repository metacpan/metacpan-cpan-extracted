use strict;
use warnings;
use Test::More;
use Mojo::TFTPd;


my $tftpd = Mojo::TFTPd->new(retries => 6);
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

    $DATA = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "octet", "multicast", "0";
    $tftpd->_incoming;

    is $DATA, pack('n', 6), 'incorrect OACK empty';
}
{
    $DATA = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "octet", "timeout", "0";
    $tftpd->_incoming;

    is $DATA, pack('n', 6), 'RRQ OACK invalid timeout';

}
{
    $DATA = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "octet", "tsize", "0";
    $tftpd->_incoming;

    is $DATA, pack('na*', 6, join "\0", "tsize", "512"), 'RRQ OACK tsize';

}
{
    $DATA = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "octet",
    "tsize", "0", "blksize", "100", "timeout", "1", "multicast", "1";
    $tftpd->_incoming;

    is $DATA, pack('na*', 6, join "\0",
    "blksize", "100", "timeout", "1", "tsize", "512"), 'RRQ OACK all';
}

{
    @error = ();
    $tftpd->on(wrq => sub {
        my($tftpd, $c) = @_;
        my $FH;
        $c->filehandle($FH) if open $FH, '>', 't/data/' .$c->file;
    });

    $DATA = pack('n', Mojo::TFTPd::OPCODE_WRQ) . join "\0", "test.swp", "octet", "tsize", "500", "blksize", "200";
    $tftpd->_incoming;

    is $DATA, pack('na*', 6, join "\0", "blksize", "200", "tsize", "500"), 'WRQ OACK tsize';

    $DATA = pack('nna*', Mojo::TFTPd::OPCODE_DATA, 1, ("a" x 200));
    $tftpd->_incoming;
    is $DATA, pack('nn', 4, 1), 'ack on a x 200';

    $DATA = pack('nna*', Mojo::TFTPd::OPCODE_DATA, 2, ("a" x 200));
    $tftpd->_incoming;
    is $DATA, pack('nn', 4, 2), 'ack on a x 200';

    $DATA = pack('nna*', Mojo::TFTPd::OPCODE_DATA, 3, ("a" x 200));
    $tftpd->_incoming;

    is $DATA, pack('nnZ*', 5, 3, 'Disk full or allocation exceeded'), 'ack on a x 200';

    ok !$tftpd->{connections}{whatever}, 'wrq connection is completed';
}

done_testing;

package Dummy::Handle;
sub recv { $_[1] = $main::DATA }
sub send { $main::DATA = $_[1] }
sub peername { 'whatever' }
sub peerport { 12345 }
sub peerhost { '127.0.0.1' }
1;
