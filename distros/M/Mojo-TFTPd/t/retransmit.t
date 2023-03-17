use strict;
use warnings;
use Test::More;
use Mojo::TFTPd;

my $tftpd = Mojo::TFTPd->new(retries => 6, retransmit => 1);
my @error;
our ($RECV, $SEND);

$tftpd->on(error => sub { note "Err! $_[1]"; push @error, $_[1] });

subtest 'error on ack of error' => sub {
  $tftpd->{socket} = bless {}, 'Dummy::Handle';
  @error = ();
  $tftpd->on(
    rrq => sub {
      my ($tftpd, $c) = @_;
      my $FH;
      $c->filehandle($FH) if open $FH, '<', 't/data/' . $c->file;
      $c->filesize(-s 't/data/' . $c->file);
    }
  );

  $SEND = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "doesntexist", "ascii";
  $tftpd->_incoming;

  ok !$tftpd->{connections}{whatever}, 'rrq connection does not exists on invalid file';
  is $RECV, pack('nnZ*', Mojo::TFTPd::OPCODE_ERROR, 1, "File not found"),
    'doesntexist result in error';
  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
  $tftpd->_incoming;
  like "@error", qr{has no connection}, 'error on ack of error';
};

subtest 'retransmit' => sub {
  $SEND = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "ascii", "blksize", "200",
    "tsize", "0";
  $tftpd->_incoming;
  isa_ok $tftpd->{connections}{whatever}, 'Mojo::TFTPd::Connection';
  is $RECV, pack('na*', 6, join "\0", "blksize", "200", "tsize", "512", ""), 'RRQ OACK all';

  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 0);
  $tftpd->_incoming;
  is $RECV, pack('nna*', 3, 1, (1 x 200)), 'rrq.bin seq 1 was sent';

  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
  $tftpd->_incoming;
  is $RECV, pack('nna*', 3, 2, (1 x 200)), 'rrq.bin seq 2 was sent';

  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
  $tftpd->_incoming;

  # data should not be changed
  is $SEND, pack('nn', Mojo::TFTPd::OPCODE_ACK, 1), 'rrq.bin dup ack 1';

  # retries not changed
  is $tftpd->{connections}{whatever}{retries}, 6, 'rrq.bin seq 2';

  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 5);
  $tftpd->_incoming;
  is $tftpd->{connections}{whatever}{retries}, 5, 'rrq.bin seq 5';

  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
  $tftpd->_incoming;
  is $tftpd->{connections}{whatever}{retries}, 5, 'rrq.bin seq 1';

  # disable retransmit
  $tftpd->{connections}{whatever}{retransmit} = 0;

  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
  $tftpd->_incoming;
  is $tftpd->{connections}{whatever}{retries}, 4, 'rrq.bin seq 1 no retransmit';
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
