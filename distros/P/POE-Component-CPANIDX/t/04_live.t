use strict;
use warnings;
use Test::More;

unless ( -e 'network.tests' ) {
  plan skip_all => 'No network tests';
}

my @tests = (
  [ 'timestamp' ],
  [ mod => 'POE' ],
  [ auth => 'BINGOS' ],
  [ dists => 'BINGOS' ],
  [ corelist => 'CPANPLUS' ],
  [ 'topten' ],
  [ 'mirrors' ],
);

plan tests => 3 + ( scalar @tests * 2 );

use POE;
use_ok('POE::Component::CPANIDX');

use constant IDX => 'http://cpanidx.org/cpanidx/';

my $idx = POE::Component::CPANIDX->spawn();
isa_ok($idx,'POE::Component::CPANIDX');

POE::Session->create(
  package_states => [
    main => [qw(_start _stop _reply)],
  ],
  heap => { tests => \@tests },
);

$poe_kernel->run();
exit 0;

sub _start {
  my $test = shift @{ $_[HEAP]->{tests} };
  $idx->query_idx( event => '_reply', url => IDX );
  return;
}

sub _stop {
  pass('The poco let us go');
  $idx->shutdown;
  return;
}

sub _reply {
  my ($heap,$resp) = @_[HEAP,ARG0];
  ok( $resp->{data}, 'We have data' );
  #use Data::Dumper; $Data::Dumper::Indent=1;
  #diag(Dumper($resp->{data}));
  ok( ref $resp->{data} eq 'ARRAY', 'And it is an array ref' );
  my $test = shift @{ $heap->{tests} };
  return unless $test;
  $idx->query_idx( event => '_reply', url => IDX, cmd => $test->[0], search => $test->[1] );
  return;
}
