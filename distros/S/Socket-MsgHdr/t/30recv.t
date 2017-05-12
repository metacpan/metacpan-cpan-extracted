# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 9 };
use bytes;
use strict;
use Socket;
use Socket::MsgHdr;

sub recv_emu($$$;$) {
  my ($s, undef, $length, $flags) = @_;
  my ($m, $ret);

  $m = new Socket::MsgHdr(buflen => $length, namelen => 256);
  return unless defined recvmsg($s, $m, $flags || 0);
  $_[1] = $m->buf();
  return (defined $m->name() ? $m->name() : "");
}

sub recv_test($$) {
  my ($msg, $flags) = @_;
  my $buf;
  local (*Rd, *Wr);

  socketpair(Rd, Wr, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!\n";

  send(\*Wr, $msg, 0) or die "send: $!\n";
  return (defined recv_emu(\*Rd, $buf, 8192, $flags) and ($buf eq $msg));
}

sub sin2human($) {
  my ($port, $addr) = sockaddr_in(shift);
  return join(":", inet_ntoa($addr), $port);
}

sub recvfrom_test($$) {
  my ($msg, $flags) = @_;
  my $buf;
  local (*Snd, *Rcv);

  for (\*Snd, \*Rcv) {
    socket($_, AF_INET, SOCK_DGRAM, 0)
      or die "socket: $!\n";
    bind($_, sockaddr_in(0, inet_aton('127.0.0.01')))
      or die "bind: $!\n";
  }

  send(\*Snd, $msg, $flags, getsockname(Rcv)) or die "sendto: $!\n";

  my $sender = getsockname(Snd);
  my $r = recv_emu(\*Rcv, $buf, 8192, 0);
  ## trim to size
  $r = substr($r, 0, length(sockaddr_in(0, inet_aton('127.0.0.01'))));
  return (($msg eq $buf) and (sin2human($sender) eq sin2human($r)));

}

# 1..2
ok(recv_test("foobarbaz", 0), "plain recv emulation");
ok(recvfrom_test("foobarbaz", 0), "plain recvfrom emulation");

# 2..4
SKIP: {
  no strict 'subs';
  eval { &MSG_TRUNC; }; # autoloaded, may not be defined yet
  skip "msg_trunc not defined", 2 if $@;
  ok(recv_test("msg_trunc", MSG_TRUNC),
     "recv(msg_trunc) emulation");
  ok(recvfrom_test("msg_trunc", MSG_TRUNC),
     "recvfrom(msg_trunc) emulation");
};

# 5..6
SKIP: {
  no strict 'subs';
  eval { &MSG_DONTWAIT; }; # autoloaded, may not be defined yet
  skip "msg_dontwait not defined", 2 if $@;
  ok(recv_test("msg_dontwait", MSG_DONTWAIT),
     "recv(msg_dontwait) emulation");
  ok(recvfrom_test("msg_nosignal", MSG_DONTWAIT),
     "recvfrom(msg_dontwait) emulation");
};

# 7
eval { defined recvmsg(\*STDIN, new Socket::MsgHdr(buf=>"fail")) 
       or die "recvmsg: $!\n"; }; # ENOTSOCK
ok($@, "recvmsg() undef on failure");

# 8..9
SKIP: {
  no strict 'subs';
  eval { &SOL_SOCKET; &SCM_RIGHTS; };
  skip "fd passing: SOL_SOCKET/SCM_RIGHTS unavailable", 1 if $@;
  skip "fd passing: where's STDIN?", 1 unless defined fileno(STDIN);

  local (*Rd, *Wr);
  socketpair(Rd, Wr, AF_UNIX, SOCK_DGRAM, 0)
    or die "socketpair: $!\n";

  my $hdr = new Socket::MsgHdr(buf => "hello!");
  $hdr->cmsghdr(SOL_SOCKET, SCM_RIGHTS, pack('i', fileno STDIN));
  sendmsg(\*Wr, $hdr, 0)
    or die "sendmsg: $!\n";

  my $m = new Socket::MsgHdr(buflen => 256, controllen => 256);
  recvmsg(\*Rd, $m, 0)
    or die "recvmsg: $!\n";

  close Rd; close Wr;

  my $new_fd = ($m->cmsghdr())[2];
  $new_fd = unpack('i', $new_fd);
  local *New;
  open(New, "<&=$new_fd") or die "fdopen(<&=$new_fd): $!\n";

  my ($dev1, $ino1, $dev2, $ino2) =
     ((stat(STDIN))[0,1], (stat(New))[0,1]);

  cmp_ok($dev1, '==', $dev2, "scm_rights fds on same device");
  cmp_ok($ino1, '==', $ino2, "scm_rights fds are same inode");
};
