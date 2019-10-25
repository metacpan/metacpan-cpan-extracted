package PostgreSQLHosting::Box;

use Moo;
use strictures 2;
use Rex::Commands::SimpleCheck;

# has name       => (is => 'ro', lazy => 1, builder => 1);
# has id         => (is => 'ro', lazy => 1, builder => 1);
# has private_ip => (is => 'ro', lazy => 1, builder => 1);
# has public_ip  => (is => 'ro', lazy => 1, builder => 1);
has type => (is => 'ro');

has $_ => (is => 'ro', lazy => 1, init_arg => undef, builder => 1)
  for qw(id name private_ip public_ip);

has "_$_" => (is => 'ro', init_arg => $_)
  for qw(id api_client name size region ssh_public_key tag root_pass);


sub wait_for_ssh {
  my ($self, $port) = @_;

  my $ip = $self->public_ip;

  $port ||= 22;

  # print "Waiting for SSH to come up on $ip:$port.";
  while (!is_port_open($ip, $port)) {
    print ".";
    sleep 1;
  }
  print "\n";
}


1;
