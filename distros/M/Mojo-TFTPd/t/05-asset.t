use strict;
use warnings;
use Test::More;
use Mojo::TFTPd;
use Mojo::Asset::Memory;
use Mojo::Asset::File;


my $tftpd = Mojo::TFTPd->new(retries => 6);
my(@error, @finish);
our $DATA;

$tftpd->on(error => sub { shift; push @error, [@_] });
$tftpd->on(finish => sub { shift; push @finish, [@_] });

$tftpd->{socket} = bless {}, 'Dummy::Handle';

{
    @error = ();
    $tftpd->on(rrq => sub {
        my($tftpd, $c) = @_;
        my $file = Mojo::Asset::File->new(path => 't/data/' . $c->file);
        $c->filehandle($file) if -e 't/data/' . $c->file;
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
    my $received;
    @error = ();
    $tftpd->on(wrq => sub {
        my($tftpd, $c) = @_;
        my $file = Mojo::Asset::Memory->new();
        $c->filehandle($file);
    });

    $tftpd->on(finish => sub {
        my($tftpd, $c) = @_;
        #$c->filehandle->move_to('t/data/' . $c->file);
        $received = $c->filehandle->slurp;
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

    ok length($received) == (512 + 400), 'received length ok';
    ok $received eq "a" x (512 + 400), 'received ok';
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
