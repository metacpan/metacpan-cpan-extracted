package Calculator;

sub add
{
shift;
my $sum = 0;

	if ( ref ($_[0]) ) {		# assume this HAS to be an ARRAY
		foreach (@{$_[0]}) {
			$sum += $_;
		}
	}
	else {
		foreach (@_) {
			$sum += $_;
		}
	}

	$sum;
}


1;


__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::HTTPX testing suite.

Install this module (Calculator.pm) in the deployed modules directory
of the server to be forwarded to -preferably behind a firewall
that the client script (client/http-forward-newuri-calculator.pl) has no
access to (but is of course accessible to the proxy server).

Install also in the deployed modules directory
of the server to be redirected to -which must be accessible to the
client scripts (client/http-redirect-*calculator.pl).
