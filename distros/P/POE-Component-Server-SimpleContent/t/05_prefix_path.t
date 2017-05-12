use Test::More tests => 7;
BEGIN { use_ok('POE::Component::Server::SimpleContent') };

use POE;
use HTTP::Request;
use HTTP::Response;

my $content = POE::Component::Server::SimpleContent->spawn( root_dir => 'nested/', prefix_path => '/static' );

isa_ok( $content, 'POE::Component::Server::SimpleContent' );

POE::Session->create(
	package_states => [
		'main' => [ qw(_start _timeout DONE) ],
	],
);

$poe_kernel->run();
exit 0;

sub _start {
  my @content = qw(200 404 301 403 404);
  $_[HEAP]->{content} = {}; 
  my @response;
  for my $code (@content) {
    push @response, HTTP::Response->new;
    $_[HEAP]->{content}{$response[$#response]} = $code;
  }

  $content->auto_index( 0 );
  $content->request( HTTP::Request->new( GET => 'http://localhost/' ), shift @response );
  $content->request( HTTP::Request->new( GET => 'http://localhost/blah' ), shift @response );
  $content->request( HTTP::Request->new( GET => 'http://localhost/test' ), shift @response );
  $content->request( HTTP::Request->new( GET => 'http://localhost/test/' ), shift @response );
  $content->request( HTTP::Request->new( GET => 'http://localhost/../t/' ), shift @response );

  $poe_kernel->delay( _timeout => 60 );
  undef;
}

sub _timeout {
  $content->shutdown();
  undef;
}

sub DONE {
  my ($heap) = $_[HEAP];
  my ($response) = $_[ARG0];
  my $code = $response->code;

  ok( $code eq delete $heap->{content}{$response}, "Test for $code" );

  if ( scalar keys %{ $heap->{content} } == 0 ) {
	$poe_kernel->delay( _timeout => undef );
	$content->shutdown();
  }
  undef;
}
