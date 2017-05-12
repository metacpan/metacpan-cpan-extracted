package Hello;

sub echo
{
	"Standard 'Hello $_[1]'!";
}


1;

__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::HTTPX testing suite.

Install this module (Hello.pm) in the deployed modules directory
of the server to be forwarded to -preferably behind a firewall
that the client script (client/http-forward-hello.pl) has no
access to (but is of course accessible to the proxy server).
