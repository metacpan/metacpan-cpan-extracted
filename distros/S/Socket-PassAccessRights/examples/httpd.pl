#!/usr/bin/perl
# 29.1.2000, Sampo Kellomaki <sampo@iki.fi>
#
# Contact Unix domain socket, send STDIO there, send request, and
# receive response.
#
# This client pretends to be a simplistic HTTP server that serves
# requests for simple .txt documents directly while forwarding
# requests for complex .x documents to persistent application server.
#
# You can run this from command line or put it in /etc/inetd.conf:
#  http2 stream tcp nowait nobody /usr/src/PassAccessRights/examples/httpd.pl x

use Socket;
use Socket::PassAccessRights;

$sock_name = '/tmp/appd';
$webroot = '/tmp';

sysread STDIN,$req,4096;
($op, $path, $ext,$rest) = $req =~
    /^(\w+)\s+(\S+?)([^\s.]*)\s+HTTP\/1.[01]\r?\n(.*)$/is;

if (uc($op) eq GET && $ext ne 'x') {
    ### Simple file case

    print "HTTP/1.0 200 Ok\r\nContent-type: text/plain\r\n\r\n";

    $path =~ s|\.\.+|.|g;
    open F,"<$webroot/$path.$ext" or die "No file $webroot/$path.$ext: $!";
    undef $/;
    print <F>;
    close F;
    exit;
}

### Either it was a post or a request for complex .x file. Send
### the request to application server.

socket S, PF_UNIX, SOCK_STREAM, 0  or die "socket: $!";
connect S, sockaddr_un($sock_name) or die "connect($sock_name): $!";
$was = select S; $|=1; select $was;

Socket::PassAccessRights::sendfd(fileno(S), fileno(STDIN)) or die;
Socket::PassAccessRights::sendfd(fileno(S), fileno(STDOUT)) or die;
print S $req;  # Request line was already read from STDIN so I send it again

### Not that I really expect to get anything back, but just in case...

while (defined($x=<S>)) {
    print $x;
}
close S;

#EOF

