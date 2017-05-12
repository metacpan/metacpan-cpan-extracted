use Test::More tests => 11;
BEGIN { use_ok('POE::Component::Server::SimpleContent') };

use POE;
use HTTP::Request;
use HTTP::Response;

my $content = POE::Component::Server::SimpleContent->spawn( root_dir => 'static/', alias_path => '/CPAN' );

isa_ok( $content, 'POE::Component::Server::SimpleContent' );

POE::Session->create(
	package_states => [
		'main' => [ qw(_start _timeout DONE _handler) ],
	],
);

$poe_kernel->run();
exit 0;

sub _start {
  my @content = qw(200 200 301 403 404);
  $_[HEAP]->{content} = {}; 
  my @response;
  for my $code (@content) {
    push @response, HTTP::Response->new;
    $_[HEAP]->{content}{$response[$#response]} = $code;
  }

  $content->set_handlers(
        {
                'cgi' => { SESSION => $_[SESSION]->ID, EVENT => '_handler' },
        },
  );

  $content->auto_index( 0 );
  $content->request( HTTP::Request->new( GET => 'http://localhost/CPAN/' ), shift @response );
  $content->request( HTTP::Request->new( GET => 'http://localhost/CPAN/blah.cgi' ), shift @response );
  $content->request( HTTP::Request->new( GET => 'http://localhost/CPAN/test' ), shift @response );
  $content->request( HTTP::Request->new( GET => 'http://localhost/CPAN/test/' ), shift @response );
  $content->request( HTTP::Request->new( GET => 'http://localhost/CPAN/../t/' ), shift @response );

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

sub _handler {
  my ($kernel,$heap,$data) = @_[KERNEL,HEAP,ARG0];
  isa_ok( $data->{request}, 'HTTP::Request' );
  isa_ok( $data->{response}, 'HTTP::Response' );
  ok( $data->{script_name} eq '/CPAN/blah.cgi', 'Script Name' );
  ok( $data->{script_filename} eq 'static/blah.cgi', 'Script Filename' );
  $data->{response}->code( 200 );
  $kernel->call( $data->{session}, 'DONE', $data->{response} );
  return;
}
