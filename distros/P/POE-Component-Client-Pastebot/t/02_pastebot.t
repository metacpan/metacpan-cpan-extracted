use strict;
use warnings;
use Test::More tests => 11; 
use POE;
use Test::POE::Server::TCP;
use POE::Filter::HTTP::Parser;
use HTTP::Date qw( time2str );
use HTTP::Response;
use_ok('POE::Component::Client::Pastebot');

POE::Session->create(
	package_states => [
	  'main' => [ qw(_start _start_tests _stop _child _time_out _got_paste _got_fetch 
			 httpd_registered httpd_client_input) ],
	],
	options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  #$heap->{pastebot} = 'http://scsys.co.uk:8002/';
  #$poe_kernel->yield( '_start_tests' );
  #return;
  $heap->{httpd} = Test::POE::Server::TCP->spawn(
     address => '127.0.0.1',
     filter  => POE::Filter::HTTP::Parser->new( type => 'server' ),
     prefix  => 'httpd',
  );
  return;
}

sub httpd_registered {
  my ($heap,$object) = @_[HEAP,ARG0];
  $heap->{pastebot} = 'http://127.0.0.1:' . $object->port() . '/';
  $poe_kernel->yield( '_start_tests' );
  return;
}

sub httpd_client_input {
  my ($heap,$id,$req) = @_[HEAP,ARG0,ARG1];
  if ( $req->method eq 'POST' ) {
    my $content = $req->content();
    my $path = $req->uri->path_query;
    is( $content, 'paste=Moo', 'The paste content was as expected');
    is( $path, '/paste', 'The Path was okay' );
    my $resp = HTTP::Response->new( 200 );
    $resp->protocol('HTTP/1.1');
    $resp->header('Content-Type', 'text/html');
    $resp->header('Date', time2str(time));
    $resp->header('Server', 'Test-POE-Server-TCP/' . $Test::POE::Server::TCP::VERSION);
    $resp->header('Connection', 'close');
    $resp->content( _gen_content_paste( $heap->{pastebot} ) );
    use bytes;
    $resp->header('Content-Length', length $resp->content);
    $heap->{httpd}->send_to_client( $id, $resp );
    return;
  }
  my $path = $req->uri->path_query;
  is( $path, '/1?tx=on', 'The GET path was okay' );
  my $resp = HTTP::Response->new( 200 );
  $resp->protocol('HTTP/1.1');
  $resp->header('Content-Type', 'text/html');
  $resp->header('Date', time2str(time));
  $resp->header('Server', 'Test-POE-Server-TCP/' . $Test::POE::Server::TCP::VERSION);
  $resp->header('Connection', 'close');
  $resp->content( 'Moo' );
  use bytes;
  $resp->header('Content-Length', length $resp->content);
  $heap->{httpd}->send_to_client( $id, $resp );
  return;
}

sub _start_tests {
  my $pbobj = POE::Component::Client::Pastebot->spawn( options => { trace => 0 }, debug => 1 );
  isa_ok( $pbobj, 'POE::Component::Client::Pastebot' );
  pass('started');
  $poe_kernel->delay( '_time_out' => 60 );
  undef;
}

sub _stop {
  pass('stopped');
}

sub _time_out {
  die;
}

sub _child {
  my ($kernel,$heap,$what,$who) = @_[KERNEL,HEAP,ARG0,ARG1];
  if ( $what eq 'create' ) {
	$kernel->post( $who => 'paste' => { event => '_got_paste', paste => 'Moo', url => $heap->{pastebot} } );
	pass('created');
	return;
  }
  if ( $what eq 'lose' ) {
	pass('lost');
	$kernel->delay( '_time_out' );
	return;
  }
  undef;
}

sub _got_paste {
  my ($kernel,$hashref) = @_[KERNEL,ARG0];
  if ( $hashref->{pastelink} ) {
	pass('pastelink');
	$kernel->post( $_[SENDER], 'fetch', { event => '_got_fetch', url => $hashref->{pastelink} } );
  }
  else {
	warn $hashref->{error};
  	$kernel->post( $_[SENDER], 'shutdown' );
  }
  undef;
}

sub _got_fetch {
  my ($kernel,$heap,$hashref) = @_[KERNEL,HEAP,ARG0];
  ok( $hashref->{content}, 'fetched' );
  diag($hashref->{error}) unless $hashref->{content};
  $kernel->post( $_[SENDER], 'shutdown' );
  $heap->{httpd}->shutdown;
  undef;
}

sub _gen_content_paste {
  my $url = shift;
  my $content = <<HERE;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
 <head>
  <title>Your paste, number 30261...</title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
 </head>
 <body>

  <p>
   This content is stored as
   <a href='${url}1'>${url}1</a>.
  </p>
  <p>
   From: Someone at 127.0.0.1
   <br>
   Summary: Moo
  </p>
  <p>
   <pre>Moo</pre>
  </p>
  <p>
   <div align=right><font size='-1'><a href='http://sf.net/projects/pastebot/'>Pastebot</a> is powered by <a href='http://poe.perl.org/'>POE</a>.</font></div>
   <!-- \$Id: paste-answer.html 113 2006-10-01 22:10:27Z rcaputo $ -->
  </p>
 </body>
</html>
HERE
  return $content;
}
