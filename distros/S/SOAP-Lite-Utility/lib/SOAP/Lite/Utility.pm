=head1 NAME

SOAP::Lite::Utility

=head1 SYNOPSIS

use SOAP::Lite::Utility;
my $obj = new SOAP::Lite::Utility;

=head1 DESCRIPTION

B<SOAP::Lite::Utility> provides several helpful routines for
implementing a SOAP::Lite-based client.

=head1 FUNCTIONS

=cut
package SOAP::Lite::Utility;
use strict;
use SOAP::Lite;

use Exporter;
use vars qw(@ISA @EXPORT $VERSION);

@ISA = ('Exporter');
@EXPORT = qw(create_soap_instance soap_assert);
$VERSION = '0.01';

=head2 create_soap_instance($resource, $server)

Creates the soap instance

=cut
sub create_soap_instance {
    my $resource = shift || return undef;
    my $server = shift || return undef;

    my $soap = SOAP::Lite
	-> uri($resource)
	-> proxy($server,
		 options => {compress_threshold => 10000});
    return $soap;
};

=head2 soap_assert($response)

Prints out any errors encountered in a soap call.  It takes as its
argument a valid response object returned by SOAP::Lite.  It returns
undef if there is a fault, or $response->result otherwise.

=cut
sub soap_assert {
    my $response = shift || return undef;
    if ($response->fault) {
        warn join ', ',
        $response->faultcode,
        $response->faultstring;
        return undef;
    }
    return $response->result;
}


=head1 PREREQUISITES

This script requires the C<SOAP::Lite> module.

=head1 VERSION

0.01

=head1 SEE ALSO

L<perl(1)>
L< SOAP::Lite | http://www.develop.com/soap/ >

=head1 AUTHOR

Bryce Harrington E<lt>bryce@bryceharrington.orgE<gt>

L<http://www.bryceharrington.org/|http://www.bryceharrington.org/>

=head1 COPYRIGHT

Copyright (C) 2005 Bryce Harrington.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 REVISION

Revision: $Revision: 1.2 $

=cut
1;
