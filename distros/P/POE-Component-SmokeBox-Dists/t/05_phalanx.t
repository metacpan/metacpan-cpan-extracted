use strict;
use warnings;
use Test::More; #tests => 1;

if ( -e 'no.network' ) {
  plan skip_all => 'No Internet access no point in proceeding with tests';
}

plan tests => 4;

diag("Running a phalanx search, this can take a while ...");

use POE;
use POE::Component::SmokeBox::Dists;
use Cwd;

$ENV{PERL5_SMOKEBOX_DIR} = cwd();

POE::Session->create(
  package_states => [
	'main' => [qw(_start _stop _results _time_out)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $dists = POE::Component::SmokeBox::Dists->phalanx(
	event => '_results',
	options => { trace => 0 },
  );
  $kernel->delay( '_time_out', 10 * 60 );
}

sub _stop {
  pass('Component let go of our reference');
  return;
}

sub _results {
  my ($kernel,$results) = @_[KERNEL,ARG0];
  $kernel->delay( '_time_out' );
  ok( ref $results eq 'HASH', "We got a hashref back" );
  ok( $results->{dists} && ref $results->{dists} eq 'ARRAY', "There was a dists arrayref" );
  ok( scalar @{ $results->{dists} }, "The dists arrayref was populated" );
  diag("$_\n") for @{ $results->{dists} };
  diag(scalar @{ $results->{dists} });
  return;
}

sub _time_out {
  die "Ooops something went seriously wrong, dude\n";
  return;
}
