# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 8 };
use bytes;
use strict;
use Socket;
use Socket::MsgHdr;

sub send_emu($$;$$$) { # we allow optional flags
  my (%msg, $flags);
  my $s = shift;

  $msg{buf}     = shift;
  $flags        = shift if @_;
  $msg{name}    = shift if @_;
  my $m = new Socket::MsgHdr(%msg);

  $m->cmsghdr(@{shift(@_)}) if @_;

  return sendmsg($s, $m, $flags);
}

sub send_test($$;$) {
  my ($msg, $flags, $cmsg) = @_;
  my $buf;
  local (*Rd, *Wr);

  socketpair(Rd, Wr, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
    or die "socketpair: $!\n";

  if (ref $cmsg eq 'ARRAY') {
    send_emu(\*Wr, $msg, $flags, undef, $cmsg) or die "sendmsg: $!\n";
  } else {
    send_emu(\*Wr, $msg, $flags) or die "sendmsg: $!\n";
  }
  return (defined recv(\*Rd, $buf, 8192, 0) and $buf eq $msg);
}

sub sendto_test($$) {
  my ($msg, $flags) = @_;
  my $buf;
  local (*Rd, *Wr);

  for (\*Rd, \*Wr) {
    socket($_, AF_INET, SOCK_DGRAM, 0) or die "socket: $!\n";
  }
  bind(Rd, sockaddr_in(0, inet_aton('127.0.0.01')))
    or die "bind: $!\n";

  my $name = getsockname(Rd)
     or die "getsockname: $!\n";

  send_emu(\*Wr, $msg, $flags, $name) or die "sendmsg: $!\n";
  return (defined recv(\*Rd, $buf, 8192, 0) and $buf eq $msg);
}



# 1..2
ok(send_test("foobarbaz", 0), "plain send emulation");
ok(sendto_test("foobarbaz", 0), "plain sendto emulation");

# 2..4
SKIP: {
  no strict 'subs';
  eval { &MSG_NOSIGNAL; }; # autoloaded, may not be defined yet
  skip "msg_nosignal not defined", 2 if $@;
  ok(send_test("msg_nosignal", MSG_NOSIGNAL),
     "send(msg_nosignal) emulation");
  ok(sendto_test("msg_nosignal", MSG_NOSIGNAL),
     "sendto(msg_nosignal) emulation");
};

# 5..6
SKIP: {
  no strict 'subs';
  eval { &MSG_DONTWAIT; }; # autoloaded, may not be defined yet
  skip "msg_dontwait not defined", 2 if $@;
  ok(send_test("msg_dontwait", MSG_DONTWAIT),
     "send(msg_dontwait) emulation");
  ok(sendto_test("msg_nosignal", MSG_DONTWAIT),
     "sendto(msg_dontwait) emulation");
};

# 7
eval { defined sendmsg(\*STDIN, new Socket::MsgHdr(buf=>"fail")) 
       or die "sendmsg: $!\n"; }; # ENOTSOCK
ok($@, "sendmsg() undef on failure");

# 8
SKIP: {
  no strict 'subs';
  eval { &SOL_SOCKET; &SCM_RIGHTS; };
  skip "fd passing: SOL_SOCKET/SCM_RIGHTS unavailable", 1 if $@;
  skip "fd passing: where's STDIN?", 1 unless defined fileno(STDIN);

  my $control = [SOL_SOCKET, SCM_RIGHTS, pack('i', fileno STDIN)];

  ok(send_test("fileno STDIN on the way", 0, $control),
     "fd passing test");

};
