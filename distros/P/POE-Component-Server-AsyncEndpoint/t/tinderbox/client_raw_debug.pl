#!/usr/bin/perl

use warnings;
use strict;

use IO::Socket;

my $remote = '127.0.0.1';
my $port = 61614;

my $server = IO::Socket::INET->new(PeerAddr => $remote,
				   PeerPort => $port,
				   Proto    => 'tcp',
				   Type => SOCK_STREAM)
    
    || die "Could not bind to $remote port $port: $!\n";
    
    
$server->autoflush(1);

my $retval = undef;
my $frame = undef;

# conectar al server
$frame = 
qq|CONNECT
login:username
passcode:password

\000|;
print $server $frame;


# verificar conexión...
$retval = &read_server($server);


print "Server Rerturned:\n".$retval;






print "Closing Connection...";
close $server;
print "Client DONE!\n";


#     if (! ($line =~ /^HELO TKMAILER SERVER.*/)) {
# 	close $server;
# 	&_error_dialog($self, $lc->locale('error10'));
# 	return 0;
#     }


sub read_server {

    my $server = shift;
    
    my $message = undef;

    while(my $line = <$server>){
	
	$message .= $line;
	last if ($line eq "\000\n");
	
    }
    
    return $message;

}
