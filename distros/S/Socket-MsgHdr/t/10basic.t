# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { plan tests => 24 };
use Socket;
use Socket::MsgHdr;
ok(1); # If we made it this far, we are ok.

for my $g (*recvmsg, *sendmsg) {
  ok(defined *{$g}{CODE}, "basic exports");
}

for my $m (qw|recvmsg sendmsg|) {
  ok(IO::Socket->can($m), "IO::Socket->can($m)");
}

for my $m (qw|new name namelen buf buflen control controllen flags cmsghdr|) {
  ok(Socket::MsgHdr->can($m), "Socket::MsgHdr->can($m)");
}

# len/int accessors
for $m (qw|namelen buflen controllen flags|) {
  my $val = int(rand(1024)+1);
  my $hdr = new Socket::MsgHdr ($m => $val);
  ok($val == $hdr->$m(), "$m method/ctor ok");
}

# other accessors
for $m (qw|name buf control|) {
  my $val = "foo" x int(rand(256)+1);
  my $hdr = new Socket::MsgHdr ($m => $val);
  my $mlen = $m. "len";
  ok($val eq $hdr->$m() && length($hdr->$m)==$hdr->$mlen, "$m method/ctor ok");
}

my $hdr = Socket::MsgHdr->new();
ok(!$hdr->controllen && !length($hdr->control),
   "empty initial cmsghdr sets control");
my @l = (5, 10, "fifteen", 20, 25, "thirty");
$hdr->cmsghdr(@l);
ok($hdr->controllen && (length($hdr->control) == $hdr->controllen),
   "cmsghdr sets control");
ok(eq_array(\@l, [$hdr->cmsghdr]), "cmsghdr fetches properly");


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

