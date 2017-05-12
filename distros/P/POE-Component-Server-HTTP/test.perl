
use strict;

use Data::Dumper;

#sub POE::Kernel::TRACE_DEFAULT () { 1 }
#sub POE::Kernel::ASSERT_DEFAULT () { 1 }
#sub POE::Kernel::TRACE_DEFAULT () { 1 }
BEGIN {
	require 'HTTP.pm';
	POE::Component::Server::HTTP->import();
}
#use HTTP::Status;




use POE;

#use Carp qw(confess);

#$SIG{INT} = sub { confess };

POE::Component::Server::HTTP->new(
				  Port => 8000, 
				  ContentHandler =>
				  {
				      '/' => \&callback,
				      '/arthur/' => \&artur,
				  },
				  #TransHandler => [\&uri],
				  #PostHandler => {
				  #    '/' => [\&post],
				  #},
				  #StreamHandler => \&stream,
				  Headers => { Foo => "bar" });



sub stream {
    my ($request, $response) = @_;
    $response->send(qq!<script language="JavaScript">alert("hi");</script>!);
    $response->close();
}

sub uri {
#	my ($request,$response) = @_;
#	$response->next();
#	return RC_WAIT;
}

sub artur {
    my $request = shift;
    my $response = shift;
    my $connection = shift;
    $response->code('200');
    $response->content("Welcome to " . $request->uri);
    return $response;
}

sub callback {
    my $request = shift;
    my $response = shift;
    my $connection = $request->connection;
    #my $cookie = CGI::Cookie->new(-name => "FOO", -value => "bar");

    $response->code('200');
    $response->push_header("Content-type", "text/html");
    #$response->push_header('Set-Cookie' => $cookie->as_string);
    $response->content("Welcome ".$connection->remote_ip);
#    $response->streaming(1);
    return $response;
}
$poe_kernel->run();










