use strict;
use POE qw(Component::Server::SimpleHTTP Component::Server::SimpleContent);

my $path = 'content';

my $content = POE::Component::Server::SimpleContent->spawn( root_dir => $path );

POE::Component::Server::SimpleHTTP->new(
   ALIAS => 'httpd',
   ADDRESS => '127.0.0.1',
   PORT => 8080,
   HANDLERS => [
	{
	  DIR => '.*',
	  EVENT => 'request',
	  SESSION => $content->session_id(),
	},
   ],
);

$poe_kernel->run();
exit 0;
