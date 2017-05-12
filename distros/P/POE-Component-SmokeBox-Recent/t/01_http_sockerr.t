use strict;
use warnings;
use Test::More tests => 2;
use POE qw(Component::SmokeBox::Recent::HTTP);
use URI;

my $uri = URI->new();
$uri->scheme('http');
$uri->host('bogus.gumbybrain.com');
$uri->port('/pub/CPAN/RECENT');

POE::Session->create(
  package_states => [
	main => [qw(_start _stop http_sockerr http_response _default)],
  ]
);

$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::SmokeBox::Recent::HTTP->spawn(
	uri => $uri,
  );
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
