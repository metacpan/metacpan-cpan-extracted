#!/usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);

use Data::Dumper ();
use Fcntl;
use File::Temp 'mktemp';
use Test::More tests => 36;

use POSIX::2008;

my %funcs = (
  'poll'  => defined(&POSIX::2008::poll)  ? \&POSIX::2008::poll  : undef,
  'ppoll' => defined(&POSIX::2008::ppoll) ? \&POSIX::2008::ppoll : undef,
);

my $tmpname = mktemp('X'x20);
sysopen my $tmpfh, $tmpname, O_RDWR|O_CREAT|O_EXCL, 0700 or die "$tmpname: $!";

while (my ($fname, $func) = each %funcs) {
 SKIP: {
    if (! defined $func) {
      skip "$fname\() UNAVAILABLE", 18;
    }

    my $pollfds;
    my $rv = $func->($pollfds, 0);
    is($rv, 0, "$fname\(undef, 0)");
    is($pollfds, undef, "$fname\(undef, 0)");

    $pollfds = [];
    $rv = $func->($pollfds, 0);
    is($rv, 0, "$fname\([], 0)");
    is(ref $pollfds, 'ARRAY', "$fname\([], 0)");
    is(scalar @$pollfds, 0, "$fname\([], 0)");

    # dist/IO/t/io_poll.t says these OSes suck.
    if ($^O =~ /^(?:MSWin32|NetWare|VMS|beos)$/) {
      skip "$fname\() doesn't work on non-socket fds on $^O", 13;
    }
    $pollfds = [
      [$tmpfh, POSIX::2008::POLLIN|POSIX::2008::POLLOUT, 0],
      [\*STDOUT, POSIX::2008::POLLIN|POSIX::2008::POLLWRNORM, 0],
    ];
    $rv = $func->($pollfds, 0);
    my $pfd_dump = Data::Dumper->new([$pollfds])->Terse(1)->Indent(0)->Dump();
    my $msg = "$fname pollfds: $pfd_dump";
    is($rv, 2, "poll() rv; $msg");
    is(ref $pollfds, 'ARRAY', "pollfds is ARRAY ref; $msg");
    is(scalar @$pollfds, 2, "pollfds has 2 elements; $msg");
    is(ref $pollfds->[0], 'ARRAY', "pollfds[0] is an ARRAY ref; $msg");
    is(scalar @{$pollfds->[0]}, 3, "pollfds[0] has 3 elements; $msg");
    is(ref $pollfds->[1], 'ARRAY', "pollfds[1] is an ARRAY ref; $msg");
    is(scalar @{$pollfds->[1]}, 3, "pollfds[1] has 3 elements; $msg");
    is($pollfds->[0]->[0], $tmpfh, "pollfds[0][0] if file handle $msg");
    is($pollfds->[0]->[1], POSIX::2008::POLLIN|POSIX::2008::POLLOUT,
       "pollfds[0][1]==POLLIN|POLLOUT; $msg");
    is($pollfds->[0]->[2], POSIX::2008::POLLIN|POSIX::2008::POLLOUT,
       "pollfds[0][2]==POLLIN|POLLOUT; $msg");
    is($pollfds->[1]->[0], \*STDOUT, "pollfds[1][0] is STDOUT; $msg");
    is($pollfds->[1]->[1], POSIX::2008::POLLIN|POSIX::2008::POLLWRNORM,
       "pollfds[1][1]==POLLIN|POLLWRNORM; $msg");
    is($pollfds->[1]->[2], POSIX::2008::POLLWRNORM,
       "pollfds[1][2]==POLLWRNORM; $msg");
  }
}

END {
  unlink $tmpname if defined $tmpname;
}
