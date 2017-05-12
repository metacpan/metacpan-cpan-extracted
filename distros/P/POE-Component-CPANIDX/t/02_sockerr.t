use strict;
use warnings;
use Test::More tests => 2;
use POE qw(Component::CPANIDX);

my $idx = POE::Component::CPANIDX->spawn();

POE::Session->create(
  package_states => [
  main => [qw(_start _stop _reply _default)],
  ]
);

$poe_kernel->run();
exit 0;

sub _start {
  $idx->query_idx(
    event => '_reply',
    url   => 'http://bogus.gumbybrain.com/',
    cmd   => 'mod',
    search => 'Module::Load',
  );
}

sub _reply {
  use Data::Dumper;
  $Data::Dumper::Indent=1;
  diag(Dumper($_[ARG0]));
  ok( $_[ARG0]->{error}, 'There is an error' );
  return;
}

sub http_sockerr {
  pass($_[STATE]);
  return;
}

sub http_response {
  SKIP: {
     skip 'Oh no, we got a HTTP::Response and we shouldn\'t. Broken DNS, because "bogus.gumbybrain.com" just should not resolve', 1;
  }
  diag($_[ARG0]->as_string());
  return;
}

sub _stop {
  $idx->shutdown;
  pass('Everything stopped');
}

 sub _default {
     my ($event, $args) = @_[ARG0 .. $#_];
     return 0 if $event eq '_child';
     my @output = ( "$event: " );

     for my $arg (@$args) {
         if ( ref $arg eq 'ARRAY' ) {
             push( @output, '[' . join(' ,', @$arg ) . ']' );
         }
         else {
             push ( @output, "'$arg'" );
         }
     }
     diag( join ' ', @output, "\n" );
     return 0;
 }

