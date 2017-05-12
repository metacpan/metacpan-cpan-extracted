use Test::More;

unless ( -e 'network.tests' ) {
  plan skip_all => 'No network tests';
}

unlink( 'search-cpan-recent.sto' ) if -e 'search-cpan-recent.sto';

plan 'no_plan';

use POE; 

use_ok('POE::Component::SmokeBox::Uploads::RSS');

POE::Session->create(
      package_states => [
        'main' => [qw(_start _stop recent)],
      ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my $rss = POE::Component::SmokeBox::Uploads::RSS->spawn(
      event => 'recent',
  );
  isa_ok( $rss, 'POE::Component::SmokeBox::Uploads::RSS' );
  return;
}

sub _stop {
  pass("The component let go of the reference");
  return;
}

sub recent {
  pass($_[ARG0]);
  warn "# ", $_[ARG0], "\n";
  return if $_[HEAP]->{foo};
  $_[HEAP]->{foo}++;
  $poe_kernel->post( $_[SENDER], 'shutdown' );
  return;
}
