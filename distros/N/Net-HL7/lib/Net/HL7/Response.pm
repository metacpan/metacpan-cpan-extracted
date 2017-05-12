################################################################################
#
# File      : Response.pm
# Author    : Duco Dokter
# Created   : Tue Mar  4 13:03:00 2003
# Version   : $Id: Response.pm,v 1.2 2004/02/10 14:31:54 wyldebeast Exp $
# Copyright : Wyldebeast & Wunderliebe
#
################################################################################

package Net::HL7::Response;

use 5.004;
use base qw(Net::HL7::Message);
use strict;
use warnings;

1;

=pod

=head1 NAME

Net::HL7::Response

=head1 SYNOPSIS

In general, this object is created by the
L<Net::HL7::Connection|Net::HL7::Connection>, like:

my $conn = new Net::HL7::Connection('localhost', 8089);
my $request = new Net::HL7::Request();

# ... set the HL7 message for the request

my $response = $conn->send($request);


=head1 DESCRIPTION

The Net::HL7::Response class extends the
L<Net::HL7::Message|Net::HL7::Message> class. In general, it is not
necessary to create instances of this class directly, since it will be
created by the Connection or Daemon when necessary.

=head1 METHODS

See L<Net::HL7::Message|Net::HL7::Message>.

=head1 AUTHOR

D.A.Dokter <dokter@wyldebeast-wunderliebe.com>

=head1 LICENSE

Copyright (c) 2002 D.A.Dokter. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
