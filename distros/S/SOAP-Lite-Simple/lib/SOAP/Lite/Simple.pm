package SOAP::Lite::Simple;

use strict;

use vars qw($VERSION $DEBUG);

use base qw(SOAP::XML::Client);

$DEBUG = 0;

$VERSION = 1.7;

1;

__END__

=head1 NAME

SOAP::Lite::Simple - Please use SOAP::XML::Client instead

=head1 DESCRIPTION

This package has been depreciated - please use SOAP::XML::Client instead.

=head1 SEE ALSO

<SOAP::XML::Client>, <SOAP::XML::Client::DotNet>, <SOAP::XML::Client::Generic>

=head1 AUTHOR

Leo Lapworth <LLAP@cuckoo.org>

=head1 COPYRIGHT

(c) 2005 Leo Lapworth

This library is free software, you can use it under the same 
terms as perl itself.

=head1 THANKS

Thanks to Foxtons for letting me develope this on their time and
to Aaron for his help with understanding SOAP a bit more and
the London.pm list for ideas.

=cut
