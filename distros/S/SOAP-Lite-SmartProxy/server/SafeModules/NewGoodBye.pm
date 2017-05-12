package NewGoodBye;

sub echo
{
	"The 'New Good Bye $_[1]'!";
}


1;

__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::HTTPX testing suite.

Install this module (NewGoodBye.pm) in the deployed modules directory
of the server to be redirected to -which must be accessible to the
client script (client/http-redirect-newuri-goodbye.pl).
