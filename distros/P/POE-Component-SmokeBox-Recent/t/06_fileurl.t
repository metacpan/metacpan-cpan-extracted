use strict;
use warnings;
use Test::More;
use URI::file;

my $path = URI::file->new_abs();

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
      url => $path,
      event => 'recent',
      context => 'Blah Blah Blah',
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
