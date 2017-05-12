################################################################################
#
# File      : HL7.pm
# Author    : D.A.Dokter
# Created   : 30 Jan 2004
# Version   : $Id: HL7.pm,v 1.11 2015/01/29 15:30:10 wyldebeast Exp $
# Copyright : Wyldebeast & Wunderliebe
#
################################################################################

package Net::HL7;

use strict;

our $VERSION = "0.81";

=pod

=head1 NAME

Net::HL7

=head1 DESCRIPTION

The Net-HL7 package is a simple Perl API for creating, parsing sending
and receiving HL7 messages. To create an empty HL7 message object, do:

=begin text

    use Net::HL7::Message;

    my $msg = new Net::HL7::Message();

=end text

and add segments like:

=begin text

    my $msh = new Net::HL7::Segments::MSH();
    my $pid = new Net::HL7::Segment("PID");

    $pid->setField(3, "1231313");

    $msg->addSegment($msh);
    $msg->addSegment($pid);

=end text

For details, please consult the man pages of each specific class, or
consult the generated API docs on
I<http://hl7toolkit.sourceforge.net/>. You might also check the test files
in the 't' directory for examples.

The Net::HL7 class is only used for documentation purposes (the stuff
you're reading right now), to set HL7 configuration properties such as
control characters on a global level and to provide a version number
of the package to the Perl installation process. This can be used in a
'require' statement, or to create a dependency from another Perl
package.

=head1 PROPERTIES

Some HL7 properties may be altered on a global level. Altering the
variable makes it changed for this remainder of the lifetime of this
Perl process. All HL7 messages will use the values provided here,
unless something is changed in the MSH segment concerning these
properties.

=over 4

=item B<SEGMENT_SEPARATOR>

Separator for segments within a message. Usually this is \015.

=cut

our $SEGMENT_SEPARATOR = "\015";

=pod

=item B<FIELD_SEPARATOR>

Field separator for this message. In general '|' is used.

=cut

our $FIELD_SEPARATOR = "|";

=pod

=item B<NULL>

HL7 NULL field, defaults to "". This is therefore different from not
setting the fields at all.

=cut

our $NULL = "\"\"";

=pod

=item B<COMPONENT_SEPARATOR>

Separator used in fields supporting components. Usually this is the
'^' character.

=cut

our $COMPONENT_SEPARATOR    = "^";

=pod

=item B<REPETITION_SEPARATOR>

Separator for fields that may be repeated. Defaults to '~'.

=cut

our $REPETITION_SEPARATOR   = "~";

=pod

=item B<ESCAPE_CHARACTER>

Escape character for escaping special characters. Defaults to '\'.

=cut

our $ESCAPE_CHARACTER       = "\\";

=pod

=item B<SUBCOMPONENT_SEPARATOR>

Separator used in fields supporting subcomponents. Usually this is
the '&' character.

=cut

our $SUBCOMPONENT_SEPARATOR = "&";

=pod

=item B<HL7_VERSION>

This is the version used in the MSH(12) field. Defaults to 2.2.

=back

=cut

our $HL7_VERSION            = "2.2";

1;
