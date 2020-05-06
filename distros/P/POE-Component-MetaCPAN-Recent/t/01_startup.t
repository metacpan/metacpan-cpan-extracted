use Test::More;

plan 'no_plan';

use POE;

use_ok('POE::Component::MetaCPAN::Recent');

POE::Session->create(
      package_states => [
        'main' => [qw(_start _stop recent _bye)],
      ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my $mrecent = POE::Component::MetaCPAN::Recent->spawn(
      event => 'recent',
  );
  isa_ok( $mrecent, 'POE::Component::MetaCPAN::Recent' );
  $_[HEAP]->{mrecent} = $mrecent;
  $poe_kernel->delay('_bye' => 10);
  diag('10 seconds delay then shutdown');
  return;
}

sub _stop {
  pass("The component let go of the reference");
  return;
}

sub _bye {
  $poe_kernel->post( $_[HEAP]->{mrecent}->session_id, 'shutdown' );
  return;
}

sub recent {
  return;
}
