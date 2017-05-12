package SOAP::Transport::ActiveWorks::Defs;
use base qw( Exporter );


BEGIN:
{
	use strict;
	use vars qw(
		$VERSION
		$AW_DEFAULT_HOST
		$AW_DEFAULT_PORT
		$AW_DEFAULT_BROKER
		$AW_DEFAULT_CLIENT_GROUP
		$AW_DEFAULT_METHOD_URI
		$AW_REQUEST_TIMEOUT
		@EXPORT
	);

	$VERSION = '0.10';

	$AW_DEFAULT_HOST         = "localhost";
	$AW_DEFAULT_PORT         = 6849;
	$AW_DEFAULT_BROKER       = "test_broker";
	$AW_DEFAULT_CLIENT_GROUP = "SOAP";
	$AW_DEFAULT_METHOD_URI   = "urn:com-name-your";
	$AW_REQUEST_TIMEOUT      = 10000;

	@EXPORT = qw(
		$AW_DEFAULT_HOST
		$AW_DEFAULT_PORT
		$AW_DEFAULT_BROKER
		$AW_DEFAULT_CLIENT_GROUP
		$AW_DEFAULT_METHOD_URI
		$AW_REQUEST_TIMEOUT
	);
}

1;

__END__

=head1 NAME

SOAP::Transport::ActiveWorks::Defs - Spec-defined constants

=head1 SYNOPSIS

    use SOAP::Transport::ActiveWorks::Defs;

=head1 DESCRIPTION

This is an internal class that exports global symbols needed
by various SOAP/ActiveWorks/Perl classes. You don't need to import this module
directly unless you happen to be building SOAP plumbing (as opposed
to simply writing a SOAP client or server).

=head1 AUTHOR

Daniel Yacob, L<yacob@rcn.com|mailto:yacob@rcn.com>

=head1 SEE ALSO

S<perl(1). SOAP(3). SOAP::Transport::ActiveWorks::Server(3).>

