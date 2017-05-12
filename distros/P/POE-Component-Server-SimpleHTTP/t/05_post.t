use strict;
use warnings;
#use Test::More tests => 8;
use Test::More;

use POE qw(Component::Server::SimpleHTTP Filter::Stream);
use Test::POE::Client::TCP;
use HTTP::Request;
use HTTP::Response;
use POE::Filter::HTTP::Parser;

my @tests = ( 
[ '/', { code => '200', content => '^we' } ],
);

my $test_count = 0;

$test_count += scalar keys %{ $_->[1] } for @tests;

plan tests => 2 + $test_count;

POE::Session->create(
   package_states => [
	main => [qw(_start _tests webc_connected webc_input webc_disconnected TOP)],
   ],
   heap => { tests => \@tests, },
   options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub _start {
  my $session_id = $_[SESSION]->ID();
  POE::Component::Server::SimpleHTTP->new(
                'ALIAS'         =>      'HTTPD',
                'ADDRESS'       =>      '127.0.0.1',
                'PORT'          =>      0,
                'HOSTNAME'      =>      'pocosimpletest.com',
                'HANDLERS'      =>      [
                        {
                                'DIR'           =>      '^/$',
                                'SESSION'       =>      $session_id,
                                'EVENT'         =>      'TOP',
                        },
                ],
                SETUPHANDLER => { SESSION => $session_id, EVENT => '_tests', },
  );
  return;
}

sub _tests {
  my ($kernel,$heap,$port) = @_[KERNEL,HEAP,ARG0];
  $heap->{webc} = Test::POE::Client::TCP->spawn(
	address 	=> '127.0.0.1',
	port    	=> $port,
	autoconnect 	=> 1,
	prefix  	=> 'webc',
	filter		=> POE::Filter::HTTP::Parser->new(),
  );
  $heap->{port} = $port;
  return;
}

sub webc_connected {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $test = shift @{ $heap->{tests} };
  my $path = $test->[0];
  $heap->{current_tests} = $test->[1];
  my $req = HTTP::Request->new( POST => $path );
  $req->header( Host => "127.0.0.1:$heap->{port}" );
  $req->header( 'Content-Length', 40 );
  $req->protocol( 'HTTP/1.1' );
  $req->content( 'brother !~we need to get off this island' );
#  $heap->{webc}->send_to_server("POST $path HTTP/1.1\x0D\x0AHost: 127.0.0.1:$heap->{port}\x0D\x0AContent-Length: 40\x0D\x0A\x0D\x0Abrother !~we need to get off this island");
  $heap->{webc}->send_to_server( $req );
  return;
}

sub webc_input {
  my ($heap,$resp) = @_[HEAP,ARG0];
#  my $status = $heap->{parser}->add($input);
#  if ( $status == 0 ) {
#     my $resp = $heap->{parser}->object();
     isa_ok( $resp, 'HTTP::Response' );
     diag($resp->as_string);
     my $tests = delete $heap->{current_tests};
     foreach my $test ( keys %{ $tests } ) {
	if ( $test eq 'code' ) {
	   ok( $resp->code eq $tests->{$test}, 'Code: ' . $tests->{$test} );
	}
	if ( $test eq 'content_type' ) {
	   ok( $resp->content_type eq $tests->{$test}, 'Content-Type: ' . $tests->{$test} );
	}
	if ( $test eq 'content' ) {
	   like( $resp->content, qr/$tests->{$test}/, 'Content: ' . $tests->{$test} );
	}
     }
#  }
#  else {
#  }
  return;
}

sub webc_disconnected {
  my ($heap,$state) = @_[HEAP,STATE];
  pass($state);
  $heap->{webc}->shutdown();
  delete $heap->{webc};
  if ( scalar @{ $heap->{tests} } ) {
     $poe_kernel->yield( '_tests', $heap->{port} );
     return;
  }
  $poe_kernel->post( 'HTTPD', 'SHUTDOWN' );
  return;
}

sub TOP
{
    my ($request, $response) = @_[ARG0, ARG1];
    diag($request->as_string);
    $response->code(200);
    $response->content_type('text/plain');

    $response->content(join ' ', reverse split (/~/, $request->content) );
    $poe_kernel->post( 'HTTPD', 'DONE', $response );
    return;
}
