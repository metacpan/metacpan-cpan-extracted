#!perl
use strict;
use warnings;
use Test::More 'no_plan';

use POE::Filter::Postfix::Plain;
use IO::Socket::UNIX;

my $pid;
if ($pid = fork) {
  sleep 2;
} else {
  require POE;
  require POE::Component::Server::Postfix;
  my $server = POE::Component::Server::Postfix->new(
    path => 'sock',
    filter => 'Plain',
    handler => sub {
      my ($self, $attr) = @_;
      #use Data::Dumper;
      #warn Dumper($attr);
      return $attr;
    },
  );
  POE::Kernel->run;
  exit(0);
}

my $sock = IO::Socket::UNIX->new(
  Peer => 'sock',
) or die $!;

my $filter = POE::Filter::Postfix::Plain->new;

my $attr = {
  foo => 1,
  bar => 'hello',
  quux => '',
  baz => "blort",
};
for (@{ $filter->put([ $attr ]) }) {
  #diag "write: \Q$_\E";
  $sock->print($_);
}
$sock->blocking(0);
sleep 2;
is_deeply(
  $filter->get([ do {
    $sock->read(my $buf, 8192);
    #diag "read: \Q$buf\E";
    $buf
  } ]),
  [ $attr ],
  'round trip over unix socket',
);
kill 15 => $pid;
