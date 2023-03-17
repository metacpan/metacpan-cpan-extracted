use Mojo::Base -strict;
use Test::More;
use Mojo::TFTPd;
use Mojo::Asset::Memory;
use Mojo::Asset::File;

my $tftpd = Mojo::TFTPd->new(retries => 6);
my @error;
our ($RECV, $SEND);

$tftpd->on(error => sub { note "Err! $_[1]"; push @error, $_[1] });

$tftpd->{socket} = bless {}, 'Dummy::Handle';

subtest 'only subscribed to "rrq" events' => sub {
  @error = ();
  $tftpd->on(
    rrq => sub {
      my ($tftpd, $c) = @_;
      my $file = Mojo::Asset::File->new(path => 't/data/' . $c->file);
      $c->filehandle($file) if -e 't/data/' . $c->file;
    }
  );

  $SEND = pack('n', Mojo::TFTPd::OPCODE_WRQ) . join "\0", "rrq.bin", "ascii";
  $tftpd->_incoming;
  is "@error", 'Cannot handle wrq requests', 'Can only handle rrq requests';
};

subtest 'rrq file not found' => sub {
  @error = ();
  $SEND  = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "doesntexist", "ascii";
  $tftpd->_incoming;
  ok !$tftpd->{connections}{whatever}, 'rrq connection does not exists on invalid file';
  is $RECV, pack('nnZ*', Mojo::TFTPd::OPCODE_ERROR, 1, "File not found"),
    'doesntexist result in error';
  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
  $tftpd->_incoming;
  like "@error", qr{has no connection}, 'error on ack of error';
};

subtest 'rrq empty data with retry' => sub {
  $SEND = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "ascii";
  $tftpd->_incoming;
  isa_ok $tftpd->{connections}{whatever}, 'Mojo::TFTPd::Connection';
  is $RECV, pack('nna*', 3, 1, (1 x 511) . "\n"), 'rrq.bin was sent';

  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 4);
  $tftpd->_incoming;
  is $tftpd->{connections}{whatever}{retries}, 5, 'retrying';
  is $RECV, pack('nna*', 3, 1, (1 x 511) . "\n"), 'rrq.bin was sent again';

  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 1);
  $tftpd->_incoming;
  is $RECV, pack('nna*', 3, 2, ''), 'empty data was sent';
  ok !$tftpd->{connections}{whatever}, 'rrq connection is completed';
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

subtest 'rrq empty data without retry' => sub {
  local $tftpd->{retries} = 0;
  $SEND = pack('n', Mojo::TFTPd::OPCODE_RRQ) . join "\0", "rrq.bin", "ascii";
  $tftpd->_incoming;
  ok $tftpd->{connections}{whatever}, 'got whatever connection';
  $SEND = pack('nn', Mojo::TFTPd::OPCODE_ACK, 5);
  $tftpd->_incoming;
  ok !$tftpd->{connections}{whatever}, 'retries==0';
};

subtest 'wrq memory file' => sub {
  my $received;
  @error = ();
  $tftpd->on(
    wrq => sub {
      my ($tftpd, $c) = @_;
      my $file = Mojo::Asset::Memory->new();
      $c->filehandle($file);
    }
  );

  $tftpd->on(
    finish => sub {
      my ($tftpd, $c) = @_;

      #$c->filehandle->move_to('t/data/' . $c->file);
      $received = $c->filehandle->slurp;
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

  ok length($received) == (512 + 400), 'received length ok';
  ok $received eq "a" x (512 + 400), 'received ok';
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
