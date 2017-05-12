################################################################################
#
# File      : Segment.pm
# Author    : Duco Dokter
# Created   : Tue Mar  4 13:03:00 2003
# Version   : $Id: Segment.pm,v 1.15 2014/09/11 09:17:20 wyldebeast Exp $
# Copyright : Wyldebeast & Wunderliebe
#
################################################################################

package Net::HL7::Segment;

use 5.004;
use strict;
use Net::HL7::Message;
#use Net::HL7::Segments::CtrlImpl;


=pod

=head1 NAME

Net::HL7::Segment

=head1 SYNOPSIS

my $seg = new Net::HL7::Segment("PID");

$seg->setField(3, "12345678");
print $seg->getField(1);

=head1 DESCRIPTION

The Net::HL7::Segment class represents segments of the HL7 message.

=head1 METHODS

=over 4

=item B<$seg = new Net::HL7::Segment($name, [$fields])>

Create an instance of this segment. A segment may be created with just
a name or a name and a reference to an array of field values. If the
name is not given, no segment is created. The segment name should be
three characters long, and upper case. If it isn't, no segment is
created, and undef is returned.  If a reference to an array is given,
all fields will be filled from that array. Note that for composed
fields and subcomponents, the array may hold subarrays and
subsubarrays. Repeated fields can not be supported the same way, since
we can't distinguish between composed fields and repeated fields.

=cut

sub new {

    my $class = shift;
    bless my $self = {}, $class;

    $self->_init(@_) || return undef;

    return $self;
}


sub _init {

    my ($self, $name, $fieldsRef) = @_;

    # Is the name 3 upper case characters?
    #
    ($name && (length($name) == 3)) || return undef;
    (uc($name) eq $name) || return undef;

    $self->{FIELDS} = [];

    $self->{FIELDS}->[0] = $name;

    if ($fieldsRef && ref($fieldsRef) eq "ARRAY") {

        for (my $i = 0; $i < @{ $fieldsRef }; $i++) {

            $self->setField($i + 1, $fieldsRef->[$i]);
        }
    }

    return 1;
}


=pod

=item B<setField($index, $value)>

Set the field specified by index to value, and return some true value
if the operation succeeded. Indices start at 1, to stay with the HL7
standard. Trying to set the value at index 0 has no effect.  The value
may also be a reference to an array (that may itself contain arrays)
to support composed fields (and subcomponents).

To set a field to the HL7 null value, instead of omitting a field, can
be achieved with the Net::HL7::NULL type, like:

  $segment->setField(8, $Net::HL7::NULL);

This will render the field as the double quote ("").
If values are not provided at all, the method will just return.

=cut

sub setField {

    my ($self, $index, $value) = @_;

    return undef unless ($index and defined($value));

    $self->{FIELDS}->[$index] = $value;

    return 1;
}


=pod

=item B<getField($index)>

Get the field at index. If the field is a composed field, you might
ask for the result to be an array like so:

my @subfields = $seg->getField(9)

otherwise the thing returned will be a reference to an array.

=cut

sub getField {

    my ($self, $index) = @_;

    if (wantarray) {
        if (ref($self->{FIELDS}->[$index]) eq "ARRAY") {
            return @{ $self->{FIELDS}->[$index]};
        }
        else {
            return ($self->{FIELDS}->[$index]);
        }
    }
    else {
        return $self->{FIELDS}->[$index];
    }
}



=pod

=item B<getFieldAsString()>

Get the string representation of the field

=cut

sub getFieldAsString {

    my ($self, $index) = @_;

    my $fieldStr = "";
    my $field = $self->{FIELDS}->[$index];

    if (ref($field) eq "ARRAY") {

        for (my $i = 0; $i < @{ $field }; $i++) {

            if (ref($field->[$i]) eq "ARRAY") {

                $fieldStr .= join($Net::HL7::SUBCOMPONENT_SEPARATOR, @{ $field->[$i] });
            }
            else {
                $fieldStr .= $field->[$i];
            }

            if ($i < (@{ $field } - 1)) {
                $fieldStr .= $Net::HL7::COMPONENT_SEPARATOR;
            }
        }
    }
    else {
        $fieldStr .= $field;
    }

    return $fieldStr;
}


=pod

=item B<size()>

Get the number of fields for this segment, not including the name

=cut

sub size {

    my $self = shift;

    return @{ $self->{FIELDS} } - 1;
}


=pod

=item B<getFields([$from, [$to]])>

Get the fields in the specified range, or all if nothing specified. If
only the 'from' value is provided, all fields from this index till the
end of the segment will be returned.

=cut

sub getFields {

    my ($self, $from, $to) = @_;

    $from || ($from = 0);
    $to || ($to = $#{$self->{FIELDS}});

    return @{ $self->{FIELDS} }[$from..$to];
}


=pod

=item B<getName()>

Get the name of the segment. This is basically the value at index 0

=back

=cut

sub getName {

    my $self = shift;

    return $self->{FIELDS}->[0];
}


1;


=pod

=head1 AUTHOR

D.A.Dokter <dokter@wyldebeast-wunderliebe.com>

=head1 LICENSE

Copyright (c) 2002 D.A.Dokter. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
