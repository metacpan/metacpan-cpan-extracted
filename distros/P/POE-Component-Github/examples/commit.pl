use strict;
use warnings;
use POE qw(Component::Github);

my $user = shift;
my $repo = shift;
my $commit = shift;

die "Not enough options\n" unless $user and $repo and $commit;

my $github = POE::Component::Github->spawn();

POE::Session->create(
  package_states => [
	'main' => [qw(_start _github)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  $poe_kernel->post( $github->get_session_id, 'commits', 'commit', 
	{ 
	  event => '_github', 
	  user => $user,
	  repo => $repo,
	  commit => $commit,
	},
  );
  return;
}

sub _github {
  my ($kernel,$heap,$resp) = @_[KERNEL,HEAP,ARG0];
  use Data::Dumper;
  warn Dumper($resp);
  $github->yield( 'shutdown' );
  return;
}
