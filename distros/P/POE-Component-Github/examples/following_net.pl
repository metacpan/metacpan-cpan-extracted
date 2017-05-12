use strict;
use warnings;
use POE qw(Component::Github);

my $start_point = shift || die "No one to start at\n";

my $github = POE::Component::Github->spawn();

POE::Session->create(
  package_states => [
	'main' => [qw(_start _github _following)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  $poe_kernel->post( $github->get_session_id, 'user', 'following', { event => '_github', user => $start_point }, );
  return;
}

sub _github {
  my ($kernel,$heap,$resp) = @_[KERNEL,HEAP,ARG0];
  use Data::Dumper;
  warn Dumper($resp);
  if ( $resp->{error} ) {
     $kernel->post( $github->get_session_id, 'shutdown' );
     return;
  }
  my $user = $resp->{user};
  my $following = $resp->{data}->{users} || [ ];
  $heap->{net}->{ $user } = $following;
  $kernel->post( $_[SENDER], 'user', 'following', { event => '_following', user => $_ }, )
	for @{ $following };
  return;
}

sub _following {
  my ($kernel,$heap,$resp) = @_[KERNEL,HEAP,ARG0];
  use Data::Dumper;
  warn Dumper($resp);
  return if $resp->{error};
  my $user = $resp->{user};
  my $following = $resp->{data}->{users} || [ ];
  return if defined $heap->{net}->{ $user };
  $heap->{net}->{ $user } = $following;
  $kernel->post( $_[SENDER], 'user', 'following', { event => '_following', user => $_ }, )
	for grep { !defined $heap->{net}->{ $_ } } @{ $following };
  return;
}
