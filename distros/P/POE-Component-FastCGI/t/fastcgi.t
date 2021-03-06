use Test::Simple tests => $ENV{FULL_TEST} ? 4 : 2;
use IO::Socket;
# Will probably fail on windows..
my $address = "/tmp/pocofcgi.test";

use POE::Component::FastCGI;
ok(1);

# silence the warning
POE::Kernel->run();

ok(POE::Component::FastCGI->new(
   Address => $address,
   Unix => 1,
   Handlers => [
      [ '/' => sub {
         my $request = shift;
         $request->make_response->error(404, "Bananas");
      } ]
   ]
));

goto END unless $ENV{FULL_TEST};

my $pid = fork();
die $! unless defined $pid;

POE::Kernel->run unless $pid;

sleep 2;

ok(my $sock = IO::Socket::UNIX->new($address));

die $! unless $sock;

# A FastCGI request..
print $sock '            �  SERVER_SOFTWARElighttpd/1.3.13SERVER_NAME0.0.0.0GATEWAY_INTERFACECGI/1.1SERVER_PORT8080	SERVER_ADDR127.0.0.1REMOTE_PORT57158	REMOTE_ADDR127.0.0.1SCRIPT_NAME/	 PATH_INFOSCRIPT_FILENAME//
DOCUMENT_ROOT/REQUEST_URI/ QUERY_STRINGREQUEST_METHODGETREDIRECT_STATUS200SERVER_PROTOCOLHTTP/1.0
HTTP_USER_AGENTWget/1.8.2	HTTP_HOSTlocalhost:8080HTTP_ACCEPT*/*
HTTP_CONNECTIONKeep-Alive          ';

read($sock, $i, 60);
ok($i =~ /Bananas/);

# Stop forked copy running POE
kill(15, $pid);

END:
unlink "/tmp/pocofcgi.test";
