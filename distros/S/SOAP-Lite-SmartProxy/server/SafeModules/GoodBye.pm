package GoodBye;

sub echo
{
	"Standard 'Good Bye $_[1]'!";
}


1;


__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::HTTPX testing suite.

Install this module (GoodBye.pm) in the deployed modules directory
of the proxy host server  -which must be accessible to the client
script (client/http-goodbye.pl).
