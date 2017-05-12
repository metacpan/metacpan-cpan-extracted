use strict;
use warnings;
use Test::More;

unless ( -e 'network.tests' ) {
  plan skip_all => 'No network tests';
}

plan tests => 4;

use POE;

use_ok('POE::Component::SmokeBox::Recent');

POE::Session->create(
      package_states => [
        'main' => [qw(_start _stop recent)],
      ],
);

$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::SmokeBox::Recent->recent(
      url => 'http://www.cpan.org/',
      event => 'recent',
      context => 'Blah Blah Blah',
      epoch => ( time() - ( 60*60*24 ) ),
  );
  return;
}

sub _stop {
  pass("The component let go of the reference");
  return;
}

sub recent {
  my $hashref = $_[ARG0];
  ok( $hashref->{recent}, 'We got a RECENT listing' );
  ok( $hashref->{context} eq 'Blah Blah Blah', 'Context was okay' );
  diag($_) for @{ $hashref->{recent} };
  return;
}
