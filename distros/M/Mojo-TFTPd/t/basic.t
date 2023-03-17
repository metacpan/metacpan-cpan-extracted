use Mojo::Base -strict;
use Test::More;
use Mojo::TFTPd;

my $tftpd = Mojo::TFTPd->new(retries => 6);
my @error;
our ($RECV, $SEND);

$tftpd->on(error => sub { shift; note "Err! @_"; push @error, [@_] });

subtest 'constants' => sub {
  is Mojo::TFTPd::OPCODE_RRQ,   1,                       'OPCODE_RRQ';
  is Mojo::TFTPd::OPCODE_WRQ,   2,                       'OPCODE_WRQ';
  is Mojo::TFTPd::OPCODE_DATA,  3,                       'OPCODE_DATA';
  is Mojo::TFTPd::OPCODE_ACK,   4,                       'OPCODE_ACK';
  is Mojo::TFTPd::OPCODE_ERROR, 5,                       'OPCODE_ERROR';
  is Mojo::TFTPd::OPCODE_OACK,  6,                       'OPCODE_OACK';
  is $tftpd->ioloop,            Mojo::IOLoop->singleton, 'got Mojo::IOLoop';
};

subtest 'errors on dummy socket' => sub {
  $tftpd->{socket} = bless {}, 'Dummy::Handle';

  local $! = 5;
  $SEND = undef;
  $tftpd->_incoming;
  like $error[0][0], qr{^Read: }, 'Got read error';

  $SEND = pack 'n', Mojo::TFTPd::OPCODE_ACK;
  $tftpd->_incoming;
  is $error[1][0], '127.0.0.1 has no connection', $error[1][0];

  $SEND = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "ascii";
  $tftpd->_incoming;
  is $error[2][0], 'Cannot handle rrq requests', $error[2][0];

  $SEND = pack('n', Mojo::TFTPd::OPCODE_WRQ) . join "\0", "rrq.bin", "ascii";
  $tftpd->_incoming;
  is $error[3][0], 'Cannot handle wrq requests', $error[3][0];
};

subtest 'only subscribed to "rrq" events' => sub {
  @error = ();
  $tftpd->on(
    rrq => sub {
      my ($tftpd, $c) = @_;
      my $FH;
      $c->filehandle($FH) if open $FH, '<', 't/data/' . $c->file;
    }
  );

  $SEND = pack('n', Mojo::TFTPd::OPCODE_WRQ) . join "\0", "rrq.bin", "ascii";
  $tftpd->_incoming;
  is $error[0][0], 'Cannot handle wrq requests', 'Can only handle rrq requests';
};

subtest 'rrq data' => sub {
  $SEND = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "150abcd", "ascii";
  $tftpd->_incoming;
  isa_ok $tftpd->{connections}{whatever}, 'Mojo::TFTPd::Connection';
  is $RECV, pack('nna*', 3, 1, ('abcd' x 128)), 'first block was sent';

  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
  $tftpd->_incoming;
  is $RECV, pack('nna*', 3, 2, ('abcd' x 22)), 'second block was sent';
  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 2);
  $tftpd->_incoming;
  ok !$tftpd->{connections}{whatever}, '150abcd connection is completed';
};

subtest 'rrq data no retries' => sub {
  local $tftpd->{retries} = 0;
  $SEND = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "ascii";
  $tftpd->_incoming;
  ok $tftpd->{connections}{whatever}, 'got whatever connection';
  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 5);
  $tftpd->_incoming;
  ok !$tftpd->{connections}{whatever}, 'retries==0';
};

subtest 'wrq data' => sub {
  @error = ();
  $tftpd->on(
    wrq => sub {
      my ($tftpd, $c) = @_;
      my $FH;
      $c->filehandle($FH) if open $FH, '>', 't/data/' . $c->file;
    }
  );

  $SEND = pack('n', Mojo::TFTPd::OPCODE_WRQ) . join "\0", "test.swp", "ascii";
  $tftpd->_incoming;
  isa_ok $tftpd->{connections}{whatever}, 'Mojo::TFTPd::Connection';
  is $RECV, pack('nn', 4, 0), 'ack on test.swp';

  $SEND = pack('nna*', Mojo::TFTPd::OPCODE_DATA, 1, ("a" x 512));
  $tftpd->_incoming;
  is $RECV, pack('nn', 4, 1), 'ack on a x 512';

  $SEND = pack('nna*', Mojo::TFTPd::OPCODE_DATA, 2, ("a" x 400));
  $tftpd->_incoming;
  is $RECV, pack('nn', 4, 2), 'ack on a x 400';
  ok !$tftpd->{connections}{whatever}, 'wrq connection is completed';
};

subtest 'max connections' => sub {
  @error = ();
  local $tftpd->{connections}{anything} = 1;
  local $tftpd->{max_connections} = 1;
  $SEND = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "ascii";
  $tftpd->_incoming;
  is $error[0][0], 'Max connections (1) reached', $error[0][0];
};

subtest 'destroy' => sub {
  no warnings qw(redefine);
  my $removed = 0;
  local *Mojo::Reactor::Poll::remove = sub { $removed++ };
  undef $tftpd;
  is $removed, 1, 'removed filehandle';
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
