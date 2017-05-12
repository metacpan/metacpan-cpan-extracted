################################################################################
#
# File      : Request.pm
# Author    : Duco Dokter
# Created   : Tue Mar  4 13:03:00 2003
# Version   : $Id: Request.pm,v 1.3 2005/04/20 07:29:44 wyldebeast Exp $ 
# Copyright : Wyldebeast & Wunderliebe
#
################################################################################

package Net::HL7::Request;

use 5.004;
use base qw(Net::HL7::Message);
use strict;
use warnings;

1;

=pod

=head1 NAME

Net::HL7::Request

=head1 SYNOPSIS

my $request = new Net::HL7::Request();
my $conn = new Net::HL7::Connection('localhost', 8089);

my $msh = new Net::HL7::Segments::MSH();

my $seg1 = new Net::HL7::Segment("PID");

$seg1->setField(1, "foo");

$request->addSegment($msh);
$request->addSegment($seg1);

my $response = $conn->send($request);


=head1 DESCRIPTION

The Net::HL7::Request simply extends the
L<Net::HL7::Message|Net::HL7::Message> class.

=head1 METHODS

See L<Net::HL7::Message>.

=head1 AUTHOR

D.A.Dokter <dokter@wyldebeast-wunderliebe.com>

=head1 LICENSE

Copyright (c) 2002 D.A.Dokter. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

