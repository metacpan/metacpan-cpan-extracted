use strict;
use warnings;
#use Test::More tests => 8;
use Test::More;

#sub POE::Component::Server::SimpleHTTP::DEBUG () { 1 }
use POE qw(Component::Server::SimpleHTTP Filter::Stream);
use Test::POE::Client::TCP;
use HTTP::Request;
use HTTP::Response;
use POE::Filter::HTTP::Parser;

my @tests = ( 
[ '/', { code => '200', content => 'this is top' } ],
[ '/honk/', { code => '200', content => 'this is honk' } ],
[ '/bonk/zip.html', { code => '200', content_type => 'text/html', content => 'my friend' } ],
[ '/wedonthaveone', { code => '404', } ],
);

my $test_count = 0;

$test_count += scalar keys %{ $_->[1] } for @tests;

plan tests => 6 + $test_count;

POE::Session->create(
   package_states => [
	main => [qw(_start _tests _run_tests webc_connected webc_input webc_disconnected TOP HONK BONK BONK2 _stop)],
   ],
   heap => { tests => \@tests, },
);

$poe_kernel->run();
exit 0;

sub _start {
  my $session_id = $_[SESSION]->ID();
  POE::Component::Server::SimpleHTTP->new(
		KEEPALIVE=>1,
                'ALIAS'         =>      'HTTPD',
                'ADDRESS'       =>      '127.0.0.1',
                'PORT'          =>      0,
                'HOSTNAME'      =>      'pocosimpletest.com',
                'HANDLERS'      =>      [
                        {
                                'DIR'           =>      '^/honk/',
                                'SESSION'       =>      $session_id,
                                'EVENT'         =>      'HONK',
                        },
                        {
                                'DIR'           =>      '^/bonk/zip.html',
                                'SESSION'       =>      $session_id,
                                'EVENT'         =>      'BONK2',
                        },
                        {
                                'DIR'           =>      '^/bonk/',
                                'SESSION'       =>      $session_id,
                                'EVENT'         =>      'BONK',
                        },
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

sub _stop {
  pass('Let my people go go');
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
  $kernel->yield( '_run_tests' );
  return;
}

sub _run_tests {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{parser} = HTTP::Parser->new( response => 1 );
  my $test = shift @{ $heap->{tests} };
  return unless $test;
  my $path = $test->[0];
  $heap->{current_tests} = $test->[1];
  my $req = HTTP::Request->new( GET => $path );
  $req->protocol( 'HTTP/1.1' );
  $req->header( 'Host', "127.0.0.1:$heap->{port}" );
  $req->header( 'Keep-Alive', 300 );
  $req->header( 'Connection', 'keep-alive' );
#  my $keepalive = '';
#  $keepalive = "Keep-Alive: 300\x0D\x0AConnection: keep-alive\x0D\x0A";
#  $heap->{webc}->send_to_server("GET $path HTTP/1.1\x0D\x0AHost: 127.0.0.1:$heap->{port}\x0D\x0A$keepalive\x0D\x0A");
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
     $poe_kernel->yield( '_run_tests' );
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
  $poe_kernel->post( 'HTTPD', 'SHUTDOWN' );
  return;
}

#######################################
sub TOP
{
    my ($request, $response) = @_[ARG0, ARG1];
    $response->code(200);
    $response->content_type('text/plain');
    $response->content("this is top");
    $_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}

#######################################
sub HONK
{
    my ($request, $response) = @_[ARG0, ARG1];
    my $c = $response->connection;
    $_[KERNEL]->call( $_[SENDER], 'SETCLOSEHANDLER', $c->ID, 
                        'on_close', [ $c->ID, "something" ], "more" );
    $response->code(200);
    $response->content_type('text/plain');
    $response->content("this is honk");
    $_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}

#######################################
sub BONK
{
    my ($request, $response) = @_[ARG0, ARG1];
    fail( "bonk should never be called" );
    $response->code(200);
    $response->content_type('text/plain');
    $response->content("this is bonk");
    $_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}

#######################################
sub BONK2
{
    my ($request, $response) = @_[ARG0, ARG1];
    $response->code(200);
    $response->content_type('text/html');
    $response->content(<<'    HTML');
<html>
<head><title>YEAH!</title></head>
<body><p>This, my friend, is the page you've been looking for.</p></body>
</html>
    HTML
    $_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}

