use strictures 1;
use Test::More;

$ENV{OBJECT_REMOTE_TEST_LOGGER} = 1;

use Object::Remote;
use Object::Remote::FromData;

my $conn1 = Reconnector->new::on('-');
my $conn2 = $conn1->connect;

isa_ok($conn1, 'Object::Remote::Proxy');
isa_ok($conn2, 'Object::Remote::Proxy');

my $root_pid = $$;
my $conn1_pid = $conn1->pid;
my $conn2_pid = $conn2->pid;

ok($root_pid != $conn1_pid, "Root and conn1 are not the same interpreter instance");
ok($root_pid != $conn2_pid, "Root and conn2 are not the same interpreter instance");
ok($conn1_pid != $conn2_pid, "conn1 and conn2 are not the same interpreter instance");

ok($conn1->ping eq "pong", "Ping success on conn1");
ok($conn2->ping eq "pong", "Ping success on conn2");

done_testing;

__DATA__

package Reconnector;

use Moo;

sub connect {
  return Reconnector->new::on('-');
}

sub pid {
  return $$;
}

sub ping {
  return 'pong';
}
