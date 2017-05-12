################################################################################
#
# File      : Message.pm
# Author    : Duco Dokter
# Created   : Mon Nov 11 17:37:11 2002
# Version   : $Id: Message.pm,v 1.21 2015/01/29 15:30:11 wyldebeast Exp $ 
# Copyright : D.A.Dokter, Wyldebeast & Wunderliebe
#
################################################################################

package Net::HL7::Message;

use 5.004;
use strict;
use warnings;
use Net::HL7::Segment;
use Net::HL7;

=pod

=head1 NAME

Net::HL7::Message

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

In general one needn't create an instance of the Net::HL7::Message
class directly, but use the L<Net::HL7::Request|Net::HL7::Request>
class. When adding segments, note that the segment index starts at 0,
so to get the first segment, segment, do
C<$msg-E<gt>getSegmentByIndex(0)>.

The segment separator defaults to \015. To change this, set the
variable $Net::HL7::SEGMENT_SEPARATOR.


=head1 METHODS

=over 4

=item B<$msg = new Net::HL7::Message([$msg])>

The constructor takes an optional string argument that is a string
representation of a HL7 message. If the string representation is not a
valid HL7 message. according to the specifications, undef is returned
instead of a new instance. This means that segments should be
separated within the message with the segment separator (defaults to
\015) or a newline, and segments should be syntactically correct.
When using the string argument constructor, make sure that you have
escaped any characters that would have special meaning in Perl. For
instance (using a different subcomponent separator):

    C<$msg = new Net::HL7::Message("MSH*^~\\@*1\rPID***x^x@y@z^z\r");>

would actually mean

    C<$msg = new Net::HL7::Message("MSH*^~\\@*1\rPID***x^x^z\r");>

since '@y@z' would be interpreted as two empty arrays, so do:

    C<$msg = new Net::HL7::Message("MSH*^~\\@*1\rPID***x^x\@y\@z^z\r");>

instead.

The control characters and field separator will take the values from
the MSH segment, if set. Otherwise defaults will be used. Changing the
MSH fields specifying the field separator and control characters after
the MSH has been added to the message will result in setting these
values for the message.

If the message couldn't be created, for example due to a erroneous HL7
message string, undef is returned.

=cut

sub new {
    
    my $class = shift;
    bless my $self = {}, $class;
    
    $self->_init(@_) || return undef;
    
    return $self;
}


sub _init {

    my ($self, $hl7str) = @_;

    # Array holding the segments
    #
    $self->{SEGMENTS} = [];

    # Control characters and other HL7 properties
    #
    $self->{SEGMENT_SEPARATOR}      = $Net::HL7::SEGMENT_SEPARATOR;
    $self->{FIELD_SEPARATOR}        = $Net::HL7::FIELD_SEPARATOR;
    $self->{COMPONENT_SEPARATOR}    = $Net::HL7::COMPONENT_SEPARATOR;
    $self->{SUBCOMPONENT_SEPARATOR} = $Net::HL7::SUBCOMPONENT_SEPARATOR;
    $self->{REPETITION_SEPARATOR}   = $Net::HL7::REPETITION_SEPARATOR;
    $self->{ESCAPE_CHARACTER}       = $Net::HL7::ESCAPE_CHARACTER;
    $self->{HL7_VERSION}            = $Net::HL7::HL7_VERSION;

    # If an HL7 string is given to the constructor, parse it.
    if ($hl7str) {

	my @segments = split("[\n\\" . $self->{SEGMENT_SEPARATOR} . "]", $hl7str);

	# the first segment should be the control segment
	#
	$segments[0] =~ /^([A-Z0-9]{3})(.)(.)(.)(.)(.)(.)/;

	my ($hdr, $fldSep, $compSep, $repSep, $esc, $subCompSep, $fldSepCtrl) = 
	    ($1, $2, $3, $4, $5, $6, $7);

	# Check whether field separator is repeated after 4 control characters

	if ($fldSep ne $fldSepCtrl) {

	    return undef;
	}

	# Set field separator based on control segment
	$self->{FIELD_SEPARATOR}        = $fldSep;
	
	# Set other separators
	$self->{COMPONENT_SEPARATOR}    = $compSep; 
	$self->{SUBCOMPONENT_SEPARATOR} = $subCompSep;
	$self->{ESCAPE_CHARACTER}       = $esc;
	$self->{REPETITION_SEPARATOR}   = $repSep;
	
	# Do all segments
	#
	for (my $i = 0; $i < @segments; $i++) {
	    
	    my @fields = split('\\' . $self->{FIELD_SEPARATOR}, $segments[$i]);

	    my $name = shift(@fields);

	    # Now decompose fields if necessary, into refs to arrays
	    #
	    for (my $j = 0; $j < @fields; $j++) {

		# Skip control field
		if ($i == 0 && $j == 0) {
		    
		    next;
		}
		
		my @comps = split('\\' . $self->{COMPONENT_SEPARATOR}, $fields[$j]);
		
		for (my $k = 0; $k < @comps; $k++) {

		    my @subComps = split('\\' . $self->{SUBCOMPONENT_SEPARATOR}, $comps[$k]);
			
		    # Make it a ref or just the value
		    if (@subComps <= 1) {
			$comps[$k] = $subComps[0];
		    }
		    else {
			$comps[$k] = \@subComps;
		    }

		}

		if (@comps <= 1) {
		    $fields[$j] = $comps[0];
		}
		else {
		    $fields[$j] = \@comps;
		}
	    }

	    my $seg;

	    # untaint
	    my $segClass = "";

	    if ($name =~ /^[A-Z][A-Z0-9]{2}$/) {
		$segClass = "Net::HL7::Segments::$name";
		$segClass =~ /^(.*)$/;
		$segClass = $1;
	    }

	    # Let's see whether it's a special segment
            #
	    if ( $segClass && eval("require $segClass;") ) {
		unshift(@fields, $self->{FIELD_SEPARATOR});
		$seg = eval{ "$segClass"->new(\@fields); };
	    }
	    else {
		$seg = new Net::HL7::Segment($name, \@fields);
	    }
	    
	    $seg || return undef;

	    $self->addSegment($seg);
	}
    }

    return 1;
}


=pod

=item B<addSegment($segment)>

Add the segment. to the end of the message. The segment should be an
instance of L<Net::HL7::Segment|Net::HL7::Segment>.

=cut

sub addSegment { 

    my ($self, $segment) = @_;

    if (@{ $self->{SEGMENTS} } == 0) {
	$self->_resetCtrl($segment);
    }

    push( @{ $self->{SEGMENTS} }, $segment);
}


=pod

=item B<insertSegment($segment, $idx)>

Insert the segment. The segment should be an instance of
L<Net::HL7::Segment|Net::HL7::Segment>. If the index is not given,
nothing happens.

=cut

sub insertSegment {

    my ($self, $segment, $idx) = @_;

    (! defined $idx) && return;
    ($idx > @{ $self->{SEGMENTS} }) && return;

    if ($idx == 0) {

	$self->_resetCtrl($segment);
	unshift(@{ $self->{SEGMENTS} }, $segment);
    } 
    elsif ($idx == @{ $self->{SEGMENTS} }) {

	push(@{ $self->{SEGMENTS} }, $segment);
    }
    else {
	@{ $self->{SEGMENTS} } = 
	    (@{ $self->{SEGMENTS} }[0..$idx-1],
	     $segment,
	     @{ $self->{SEGMENTS} }[$idx..@{ $self->{SEGMENTS} } -1]
	     );
    }
}


=pod 

=item B<getSegmentByIndex($index)>

Return the segment specified by $index. Segment count within the
message starts at 0.

=cut 

sub getSegmentByIndex {

    my ($self, $index) = @_;

    return $self->{SEGMENTS}->[$index];
}


=pod

=item B<getSegmentsByName($name)>

Return an array of all segments with the given name

=cut 

sub getSegmentsByName {

    my ($self, $name) = @_;

    my @segments = ();

    foreach (@{ $self->{SEGMENTS} }) {
	($_->getName() eq $name) && push(@segments, $_);
    }

    return @segments;
}


=pod 

=item B<removeSegmentByIndex($index)>

Remove the segment indexed by $index. If it doesn't exist, nothing
happens, if it does, all segments after this one will be moved one
index up.

=cut

sub removeSegmentByIndex {

    my ($self, $index) = @_;

    ($index < @{ $self->{SEGMENTS} }) && splice( @{ $self->{SEGMENTS} }, $index, 1);
}


=pod

=item B<setSegment($seg, $index)>

Set the segment on index. If index is out of range, or not provided,
do nothing. Setting MSH on index 0 will revalidate field separator,
control characters and hl7 version, based on MSH(1), MSH(2) and
MSH(12).

=cut

sub setSegment {

    my ($self, $segment, $idx) = @_;

    (! defined $idx) && return;
    ($idx > @{ $self->{SEGMENTS} }) && return;

    if ($segment->getName() eq "MSH" && $idx == 0) {

	$self->_resetCtrl($segment);
    }
    
    @{ $self->{SEGMENTS} }[$idx] = $segment;
}


# After change of MSH, reset control fields
#
sub _resetCtrl {

    my ($self, $segment) = @_;

    if ($segment->getField(1)) {
	$self->{FIELD_SEPARATOR} = $segment->getField(1);
    }
    
    if ($segment->getField(2) =~ /(.)(.)(.)(.)/) {
	
	$self->{COMPONENT_SEPARATOR}    = $1;
	$self->{REPETITION_SEPARATOR}   = $2;
	$self->{ESCAPE_CHARACTER}       = $3;
	$self->{SUBCOMPONENT_SEPARATOR} = $4;
    }
    
    if ($segment->getField(12)) {
	$self->{HL7_VERSION} = $segment->getField(12);
    }
}


=pod

=item B<getSegments()>

Return an array containing all segments in the right order.

=cut

sub getSegments {

    my $self = shift;

    return @{ $self->{SEGMENTS} };
}


=pod

=item B<toString([$pretty])>

Return a string representation of this message. This can be used to
send the message over a socket to an HL7 server. To print to other
output, use the $pretty argument as some true value. This will not use
the default segment separator, but '\n' instead.

=cut

sub toString {
    
    my ($self, $pretty) = @_;
    my $msg = "";

    # Make sure MSH(1) and MSH(2) are ok, even if someone has changed
    # these values 
    # 
    my $msh = $self->{SEGMENTS}->[0];

    $self->_resetCtrl($msh);

    for (my $i = 0; $i < @{ $self->{SEGMENTS} }; $i++) {
	
        $msg .= $self->getSegmentAsString($i);

        $pretty ? ($msg .= "\n") : ($msg .= $self->{SEGMENT_SEPARATOR});
    }
    
    return $msg;
}


=pod

=item B<getSegmentAsString($index)>

Get the string representation of the segment, in the context of this
message. That means the string representation will use the message's
separators.

=cut

sub getSegmentAsString {

    my ($self, $index) = @_;

    my $seg = $self->getSegmentByIndex($index);

    $seg || return undef;

    my $segStr = $seg->getName() . $self->{FIELD_SEPARATOR};
    
    my $start = $seg->getName() eq "MSH" ? 2 : 1;

    {
        no warnings;
	
        foreach ($start..$seg->size()) {
            
            $segStr .= $self->getSegmentFieldAsString($index, $_);
            $segStr .= $self->{FIELD_SEPARATOR};
        }
    }
	
    return $segStr;
}


=pod

=item B<getSegmentFieldAsString($segmentIndex, $fieldIndex)>


=cut

sub getSegmentFieldAsString {
 
    my ($self, $segIndex, $fldIndex) = @_;

    my $seg = $self->getSegmentByIndex($segIndex);

    $seg || return undef;

    return $seg->getFieldAsString($fldIndex);
}


=pod

=item B<removeSegmentByName($name)>

Remove the segment indexed by $name. If it doesn't exist, nothing
happens, if it does, all segments after this one will be moved one
index up.

=back

=cut

sub removeSegmentByName {

     my ($self, $name) = @_;
     my $i = 0;

     foreach (@{ $self->{SEGMENTS} }) {
         if ($_->getName() eq $name) {
             splice( @{ $self->{SEGMENTS} }, $i, 1);
         }
         else {
             $i++;
         }
     }
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
