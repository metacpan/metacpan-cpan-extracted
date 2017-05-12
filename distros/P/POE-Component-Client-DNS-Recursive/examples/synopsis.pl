use strict;
use warnings;
use Getopt::Long;

use POE qw(Component::Client::DNS::Recursive);

my $trace;
GetOptions ('trace' => \$trace);

my $host = shift || die "Nothing to query\n";
my $type = shift;

POE::Session->create(
  package_states => [
        'main', [qw(_start _response _trace)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::Client::DNS::Recursive->resolve(
        event => '_response',
        host => $host,
	( $type ? ( type => $type ) : () ),
	( $trace ? ( trace => '_trace' ) : () ),
  );
  return;
}

sub _trace {
  my $packet = $_[ARG0];
  return unless $packet;
  print $packet->string;
  return;
}

sub _response {
  my $packet = $_[ARG0]->{response};
  return unless $packet;
  print $packet->string;
  return;
}
