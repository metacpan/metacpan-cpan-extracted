################################################################################
#
# File      : Segment.pm
# Author    : Duco Dokter
# Created   : Tue Mar  4 13:03:00 2003
# Version   : $Id: MSH.pm,v 1.6 2004/02/10 14:31:54 wyldebeast Exp $ 
# Copyright : Wyldebeast & Wunderliebe
#
################################################################################

package Net::HL7::Segments::MSH;

use 5.004;
use strict;
use base qw(Net::HL7::Segment);
use POSIX qw(strftime);

=pod

=head1 NAME

Net::HL7::Segments::MSH

=head1 SYNOPSIS

my $seg = new Net::HL7::Segments::MSH();

$seg->setField(9, "ADT^A24");
print $seg->getField(1);


=head1 DESCRIPTION

The Net::HL7::Segments::MSH is an implementation of the
L<Net::HL7::Segment|Net::HL7::Segment> class. The MSH segment is a bit
different from other segments, in that the first field is the field
separator after the segment name. Other fields thus start counting
from 2!  The setting for the field separator for a whole message can
be changed by the setField method on index 1 of the MSH for that
message.  The MSH segment also contains the default settings for field
2, COMPONENT_SEPARATOR, REPETITION_SEPARATOR, ESCAPE_CHARACTER and
SUBCOMPONENT_SEPARATOR. These fields default to ^, ~, \ and &
respectively.


=head1 METHODS

=over 4

=item B<$msh = new Net::HL7::Segments::MSH([$fields])>

Create an instance of the MSH segment. If a reference to an array is
given, all fields will be filled from that array. Note that for
composed fields and subcomponents, the array may hold subarrays and
subsubarrays. If the reference is not given, the MSH segment will be
created with the MSH 1,2,7,10 and 12 fields filled in for convenience.

=cut

sub _init {
    
    my ($self, $fieldsRef) = @_;

    $self->SUPER::_init("MSH", $fieldsRef);

    # Only fill default fields if no fields ref is given 
    #
    if (! $fieldsRef) {
	$self->setField(1, $Net::HL7::FIELD_SEPARATOR);
	$self->setField(
			2, 
			$Net::HL7::COMPONENT_SEPARATOR . 
			$Net::HL7::REPETITION_SEPARATOR .
			$Net::HL7::ESCAPE_CHARACTER .
			$Net::HL7::SUBCOMPONENT_SEPARATOR
			);
	
	$self->setField(7, strftime("%Y%m%d%H%M%S", localtime));
	
	# Set ID field
	#
	my $ext = rand(1);
	$ext =~ s/[^0-9]//g;
	$ext = "." . substr($ext, 1, 5);
	
	$self->setField(10, $self->getField(7) . $ext);
	$self->setField(12, $Net::HL7::HL7_VERSION);
    }
    
    return $self;
}


=pod

=item B<setField($index, $value)>

Set the field specified by index to value. Indices start at 1, to stay
with the HL7 standard. Trying to set the value at index 0 has no
effect. Setting the value on index 1, will effectively change the
value of Net::HL7::Message::FIELD_SEPARATOR for the message containing
this segment, if the value has length 1; setting the field on index 2
will change the values of COMPONENT_SEPARATOR, REPETITION_SEPARATOR,
ESCAPE_CHARACTER and SUBCOMPONENT_SEPARATOR for the message, if the
string is of length 4.

=back

=cut

sub setField {

    my ($self, $index, $value) = @_;
    
    if ($index == 1) {
	if (length($value) != 1) {
	    return undef;
	}
    }
    
    if ($index == 2) {
	if (length($value) != 4) {
	    return undef;
	}
    }
    
    return $self->SUPER::setField($index, $value);
}


1;


=head1 AUTHOR

D.A.Dokter <dokter@wyldebeast-wunderliebe.com>

=head1 LICENSE

Copyright (c) 2002 D.A.Dokter. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
