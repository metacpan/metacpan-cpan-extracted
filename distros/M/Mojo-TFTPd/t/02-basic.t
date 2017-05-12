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
    is Mojo::TFTPd::OPCODE_RRQ, 1, 'OPCODE_RRQ';
    is Mojo::TFTPd::OPCODE_WRQ, 2, 'OPCODE_WRQ';
    is Mojo::TFTPd::OPCODE_DATA, 3, 'OPCODE_DATA';
    is Mojo::TFTPd::OPCODE_ACK, 4, 'OPCODE_ACK';
    is Mojo::TFTPd::OPCODE_ERROR, 5, 'OPCODE_ERROR';
    is Mojo::TFTPd::OPCODE_OACK, 6, 'OPCODE_OACK';
    is $tftpd->ioloop, Mojo::IOLoop->singleton, 'got Mojo::IOLoop';
}

{
    $tftpd->{socket} = bless {}, 'Dummy::Handle';

    local $! = 5;
    $DATA = undef;
    $tftpd->_incoming;
    like $error[0][0], qr{^Read: }, 'Got read error';

    $DATA = pack 'n', Mojo::TFTPd::OPCODE_ACK;
    $tftpd->_incoming;
    is $error[1][0], '127.0.0.1 has no connection', $error[1][0];

    $DATA = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "ascii";
    $tftpd->_incoming;
    is $error[2][0], 'Cannot handle rrq requests', $error[2][0];

    $DATA = pack('n', Mojo::TFTPd::OPCODE_WRQ) . join "\0", "rrq.bin", "ascii";
    $tftpd->_incoming;
    is $error[3][0], 'Cannot handle wrq requests', $error[3][0];
}

{
    @error = ();
    $tftpd->on(rrq => sub {
        my($tftpd, $c) = @_;
        my $FH;
        $c->filehandle($FH) if open $FH, '<', 't/data/' .$c->file;
    });

    $DATA = pack('n', Mojo::TFTPd::OPCODE_WRQ) . join "\0", "rrq.bin", "ascii";
    $tftpd->_incoming;
    is $error[0][0], 'Cannot handle wrq requests', 'Can only handle rrq requests';
}

{
    $DATA = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "doesntexist", "ascii";
    $tftpd->_incoming;
    ok $tftpd->{connections}{whatever}, 'rrq connection does not exists on invalid file';
    is $DATA, pack('nnZ*', Mojo::TFTPd::OPCODE_ERROR, 1, "File not found"), 'doesntexist result in error';
    $DATA = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
    $tftpd->_incoming;
    is $finish[0][1], 'No filehandle', 'error on ack of error';
}

{
    $DATA = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "ascii";
    $tftpd->_incoming;
    isa_ok $tftpd->{connections}{whatever}, 'Mojo::TFTPd::Connection';
    is $DATA, pack('nna*', 3, 1, (1 x 511). "\n"), 'rrq.bin was sent';

    $DATA = pack('nn', Mojo::TFTPd::OPCODE_ACK, 4);
    $tftpd->_incoming;
    is $tftpd->{connections}{whatever}{retries}, 5, 'retrying';
    is $DATA, pack('nna*', 3, 1, (1 x 511). "\n"), 'rrq.bin was sent again';

    $DATA = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
    $tftpd->_incoming;
    is $DATA, pack('nna*', 3, 2, ''), 'empty data was sent';
    ok !$tftpd->{connections}{whatever}, 'rrq connection is completed';
}

{
    $DATA = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "150abcd", "ascii";
    $tftpd->_incoming;
    isa_ok $tftpd->{connections}{whatever}, 'Mojo::TFTPd::Connection';
    is $DATA, pack('nna*', 3, 1, ('abcd' x 128)), 'first block was sent';

    $DATA = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
    $tftpd->_incoming;
    is $DATA, pack('nna*', 3, 2, ('abcd' x 22)), 'second block was sent';
    $DATA = pack('nn', Mojo::TFTPd::OPCODE_ACK, 2);
    $tftpd->_incoming;
    ok !$tftpd->{connections}{whatever}, '150abcd connection is completed';
}

{
    local $tftpd->{retries} = 0;
    $DATA = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "ascii";
    $tftpd->_incoming;
    ok $tftpd->{connections}{whatever}, 'got whatever connection';
    $DATA = pack('nn', Mojo::TFTPd::OPCODE_ACK, 5);
    $tftpd->_incoming;
    ok !$tftpd->{connections}{whatever}, 'retries==0';
}

{
    @error = ();
    $tftpd->on(wrq => sub {
        my($tftpd, $c) = @_;
        my $FH;
        $c->filehandle($FH) if open $FH, '>', 't/data/' .$c->file;
    });

    $DATA = pack('n', Mojo::TFTPd::OPCODE_WRQ) . join "\0", "test.swp", "ascii";
    $tftpd->_incoming;
    isa_ok $tftpd->{connections}{whatever}, 'Mojo::TFTPd::Connection';
    is $DATA, pack('nn', 4, 0), 'ack on test.swp';

    $DATA = pack('nna*', Mojo::TFTPd::OPCODE_DATA, 1, ("a" x 512));
    $tftpd->_incoming;
    is $DATA, pack('nn', 4, 1), 'ack on a x 512';

    $DATA = pack('nna*', Mojo::TFTPd::OPCODE_DATA, 2, ("a" x 400));
    $tftpd->_incoming;
    is $DATA, pack('nn', 4, 2), 'ack on a x 400';
    ok !$tftpd->{connections}{whatever}, 'wrq connection is completed';
}

{
    @error = ();
    local $tftpd->{connections}{anything} = 1;
    local $tftpd->{max_connections} = 1;
    $DATA = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "ascii";
    $tftpd->_incoming;
    is $error[0][0], 'Max connections (1) reached', $error[0][0];
}

done_testing;

package Dummy::Handle;
sub recv { $_[1] = $main::DATA }
sub send { $main::DATA = $_[1] }
sub peername { 'whatever' }
sub peerport { 12345 }
sub peerhost { '127.0.0.1' }
1;
