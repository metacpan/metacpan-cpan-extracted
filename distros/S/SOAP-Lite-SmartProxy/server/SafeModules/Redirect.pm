package Redirect;
use base qw(Exporter);

BEGIN
{
	use vars qw(@EXPORT %Redirect );

	@EXPORT = qw ( %Redirect );

	my ( $forward, $redirect ) = ( 0, 1 );

	%Redirect = (
		Calculator => [ 'http://my.other.host/soap/',            '', $redirect ],
		Xalculator => [ 'http://my.other.host/soap/',  'Calculator', $redirect ],
		Testulator => [ 'http://my.secure.host/soap/', 'Calculator',  $forward ],

		Hello      => [ 'http://my.secure.host/soap/',      'Hello',  $forward ],
		GoodBye    => [ 'http://my.other.host/soap/',  'NewGoodBye', $redirect ]

	);

}


1;


__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::HTTPX testing suite.

Install this module (Redirect.pm) in the deployed modules directory
of the proxy server.  You will edit it later to redirect and forward
your real world queries.
