use strict;
use warnings;

use POE;
use POE::Component::SmokeBox::Dists;

my $search = '^BINGOS$';

POE::Session->create(
  package_states => [
	'main' => [qw(_start _results)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::SmokeBox::Dists->author(
	event => '_results',
	search => $search,
  );
  return;
}

sub _results {
  my $ref = $_[ARG0];

  return if $ref->{error}; # Oh dear there was an error

  print $_, "\n" for @{ $ref->{dists} };

  return;
}
