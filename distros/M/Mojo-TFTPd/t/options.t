use Mojo::Base -strict;
use Test::More;
use Mojo::TFTPd;

my $tftpd = Mojo::TFTPd->new(retries => 6);
our ($RECV, $SEND);

$tftpd->on(error => sub { note "Err! $_[1]" });

subtest 'OACK cannot be empty' => sub {
  $tftpd->{socket} = bless {}, 'Dummy::Handle';
  $tftpd->on(
    rrq => sub {
      my ($tftpd, $c) = @_;
      my $FH;
      $c->filehandle($FH) if open $FH, '<', 't/data/' . $c->file;
      $c->filesize(-s 't/data/' . $c->file);
    }
  );

  $SEND = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "octet", "multicast", "0";
  $tftpd->_incoming;
  is $RECV, pack('n', 6), 'incorrect OACK empty';
};

subtest 'RRQ OACK invalid timeout' => sub {
  $SEND = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "octet", "timeout", "0";
  $tftpd->_incoming;
  is $RECV, pack('n', 6), 'RRQ OACK invalid timeout';
};

subtest 'RRQ OACK tsize' => sub {
  $SEND = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "octet", "tsize", "0";
  $tftpd->_incoming;
  is $RECV, pack('na*', 6, join "\0", "tsize", "512", ""), 'RRQ OACK tsize';
};

subtest 'RRQ OACK all' => sub {
  $SEND = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "octet", "tsize", "0",
    "blksize", "100", "timeout", "1", "multicast", "1";
  $tftpd->_incoming;
  is $RECV, pack('na*', 6, join "\0", "blksize", "100", "timeout", "1", "tsize", "512", ""),
    'RRQ OACK all';
};

subtest 'WRQ options' => sub {
  $tftpd->on(
    wrq => sub {
      my ($tftpd, $c) = @_;
      my $FH;
      $c->filehandle($FH) if open $FH, '>', 't/data/' . $c->file;
    }
  );

  $SEND = pack('n', Mojo::TFTPd::OPCODE_WRQ) . join "\0", "test.swp", "octet", "tsize", "500",
    "blksize", "200";
  $tftpd->_incoming;
  is $RECV, pack('na*', 6, join "\0", "blksize", "200", "tsize", "500", ""), 'WRQ OACK tsize';

  $SEND = pack('nna*', Mojo::TFTPd::OPCODE_DATA, 1, ("a" x 200));
  $tftpd->_incoming;
  is $RECV, pack('nn', 4, 1), 'ack on a x 200';

  $SEND = pack('nna*', Mojo::TFTPd::OPCODE_DATA, 2, ("a" x 200));
  $tftpd->_incoming;
  is $RECV, pack('nn', 4, 2), 'ack on a x 200';

  $SEND = pack('nna*', Mojo::TFTPd::OPCODE_DATA, 3, ("a" x 200));
  $tftpd->_incoming;
  is $RECV, pack('nnZ*', 5, 3, 'Disk full or allocation exceeded'), 'ack on a x 200';
  ok !$tftpd->{connections}{whatever}, 'wrq connection is completed';
};

note 'Cannot cleanup Dummy::Handle';
delete $tftpd->{socket};

done_testing;

package Dummy::Handle;
sub recv     { $_[1] = $main::SEND }
sub send     { $main::RECV = $_[1] }
sub peername {'whatever'}
sub peerport {12345}
sub peerhost {'127.0.0.1'}
1;
