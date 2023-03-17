use Mojo::Base -strict;
use Test::More;
use Mojo::Asset::Memory;
use Mojo::TFTPd;
use Mojo::Util;

sub d ($) { Mojo::Util::term_escape($_[0]) }

my $tftpd    = Mojo::TFTPd->new(retries => 6, retransmit => 1);
my $ROLLOVER = 256 * 256;
our ($RECV, $SEND);

$tftpd->on(error => sub { note "Err! $_[1]" });

note 'save WRQ to a temporary file, to be deleted';
$tftpd->on(
  wrq => sub {
    my ($tftpd, $c) = @_;
    $c->filehandle(Mojo::Asset::Memory->new);
  }
);

note 'create a "large" file for sending';
my $mem = Mojo::Asset::Memory->new;
$mem->add_chunk(chr($_ % 256) x 13) for 1 .. $ROLLOVER + 3;

$tftpd->on(
  rrq => sub {
    my ($tftpd, $c) = @_;
    $c->filehandle($mem);
  }
);

$tftpd->{socket} = bless {}, 'Dummy::Handle';

subtest 'rollover for WRQ' => sub {
  $SEND = pack('n', Mojo::TFTPd::OPCODE_WRQ) . join "\0", "wrq.bin", "octet", "blksize", "13";
  $tftpd->_incoming;
  isa_ok $tftpd->{connections}{whatever}, 'Mojo::TFTPd::Connection';
  is $RECV, pack('na*', 6, join "\0", "blksize", "13", ""), 'WRQ OACK all';

  # these should be just fine, check every so often
  for my $n (1 .. $ROLLOVER - 2) {
    $SEND = pack('nna*', Mojo::TFTPd::OPCODE_DATA, $n, chr($n % 256) x 13);
    $tftpd->_incoming;
    is d $RECV, d(pack 'nn', Mojo::TFTPd::OPCODE_ACK, $n), "packet $n received" if not $n % 4099;
  }

  # test every packet around the rollover
  for my $n ($ROLLOVER - 1 .. $ROLLOVER + 3) {
    $SEND = pack('nna*', Mojo::TFTPd::OPCODE_DATA, $n, chr($n % 256) x 13);
    $tftpd->_incoming;
    is d $RECV, d(pack 'nn', Mojo::TFTPd::OPCODE_ACK, $n % $ROLLOVER), "packet $n received";
  }
};

subtest 'rollover for RRQ' => sub {
  is $mem->size, 13 * ($ROLLOVER + 3), "RRQ file size";
  $SEND = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "octet", "blksize", "13";
  $tftpd->_incoming;
  is d $RECV, d(pack 'na*', Mojo::TFTPd::OPCODE_OACK, join "\0", "blksize", "13", ""),
    'RRQ OACK all';
  isa_ok $tftpd->{connections}{whatever}, 'Mojo::TFTPd::Connection';

  # ack start of transmission
  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 0);

  # these should be just fine, check every so often
  for my $n (1 .. $ROLLOVER - 2) {
    $tftpd->_incoming;
    is d $RECV, d(pack 'nna*', Mojo::TFTPd::OPCODE_DATA, $n, chr($n % 256) x 13), "packet $n sent"
      if not $n % 4099;
    $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, $n % $ROLLOVER);
  }

  # test every packet around the rollover
  for my $n ($ROLLOVER - 1 .. $ROLLOVER + 3) {
    $tftpd->_incoming;
    is d $RECV, d(pack 'nna*', Mojo::TFTPd::OPCODE_DATA, $n, chr($n % 256) x 13), "packet $n sent";
    $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, $n % $ROLLOVER);
  }
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
