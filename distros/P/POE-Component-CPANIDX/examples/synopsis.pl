use strict;
use warnings;
use POE qw(Component::CPANIDX);

my $url = shift or die;
my $cmd = shift or die;
my $search = shift;

my $idx = POE::Component::CPANIDX->spawn();

POE::Session->create(
  package_states => [
    main => [qw(_start _reply)],
  ],
  args => [ $url, $cmd, $search ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($URL,$CMD,$SRCH) = @_[ARG0..ARG2];

  $idx->query_idx(
    event  => '_reply',
    url    => $URL,
    cmd    => $CMD,
    search => $SRCH,
  );

  return;
}

sub _reply {
  my $resp = $_[ARG0];

  use Data::Dumper;
  $Data::Dumper::Indent=1;

  unless ( $resp->{error} ) {
     print Dumper( $resp->{data} );
  }
  else {
     print Dumper( $resp->{error} );
  }
  $idx->shutdown;
  return;
}
