package Net::NATS::Streaming::PB;
use Net::NATS::Streaming::PB::StartPosition;
use strict;
use warnings;
use vars qw(@ISA $AUTOLOAD $VERSION);

$VERSION = '0.06';

use Exporter;

require DynaLoader;
require AutoLoader;

@ISA = qw(DynaLoader Exporter);

bootstrap Net::NATS::Streaming::PB $VERSION;

1;

__END__


=pod

=head1 NAME

Net::NATS::Streaming::PB - Perl/XS interface to NATS Streaming Google protobuffers

=head1 AUTHOR

Generated from Net.NATS.Streaming.PB
by the protoxs compiler https://code.google.com/archive/p/protobuf-perlxs/
created by Dave Bailey <dave@daveb.net>.
Adapted for the distribution by Sergey Kolychev <sergeykolychev.github@gmail.com>

=head1 SEE ALSO

http://code.google.com/p/protobuf

=cut


=pod

=head1 NAME

Net::NATS::Streaming::PB::Ack - Perl/XS interface to Net.NATS.Streaming.PB.Ack

=head1 SYNOPSIS

=head2 Serializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::Ack;

 my $Ack = Net::NATS::Streaming::PB::Ack->new;
 # Set fields in $Ack...
 my $packAck = $Ack->pack();

=head2 Unserializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::Ack;

 my $packAck; # Read this from somewhere...
 my $Ack = Net::NATS::Streaming::PB::Ack->new;
 if ( $Ack->unpack($packAck) ) {
   print "OK"
 } else {
   print "NOT OK"
 }

=head1 DESCRIPTION

Net::NATS::Streaming::PB::Ack defines the following classes:

=over 5

=item C<Net::NATS::Streaming::PB::Ack>

A wrapper around the Net.NATS.Streaming.PB.Ack message


=back

=head1 Net::NATS::Streaming::PB::Ack Constructor

=over 4

=item B<$Ack = Net::NATS::Streaming::PB::Ack-E<gt>new( [$arg] )>

Constructs an instance of C<Net::NATS::Streaming::PB::Ack>.  If a hashref argument
is supplied, it is copied into the message instance as if
the copy_from() method were called immediately after
construction.  Otherwise, if a scalar argument is supplied,
it is interpreted as a serialized instance of the message
type, and the scalar is parsed to populate the message
fields.  Otherwise, if no argument is supplied, an empty
message instance is constructed.

=back

=head1 Net::NATS::Streaming::PB::Ack Methods

=over 4

=item B<$Ack2-E<gt>copy_from($Ack1)>

Copies the contents of C<Ack1> into C<Ack2>.
C<Ack2> is another instance of the same message type.

=item B<$Ack2-E<gt>copy_from($hashref)>

Copies the contents of C<hashref> into C<Ack2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$Ack2-E<gt>merge_from($Ack1)>

Merges the contents of C<Ack1> into C<Ack2>.
C<Ack2> is another instance of the same message type.

=item B<$Ack2-E<gt>merge_from($hashref)>

Merges the contents of C<hashref> into C<Ack2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$Ack-E<gt>clear()>

Clears the contents of C<Ack>.

=item B<$init = $Ack-E<gt>is_initialized()>

Returns 1 if C<Ack> has been initialized with data.

=item B<$errstr = $Ack-E<gt>error_string()>

Returns a comma-delimited string of initialization errors.

=item B<$Ack-E<gt>discard_unknown_fields()>

Discards unknown fields from C<Ack>.

=item B<$dstr = $Ack-E<gt>debug_string()>

Returns a string representation of C<Ack>.

=item B<$dstr = $Ack-E<gt>short_debug_string()>

Returns a short string representation of C<Ack>.

=item B<$ok = $Ack-E<gt>unpack($string)>

Attempts to parse C<string> into C<Ack>, returning 1 on success and 0 on failure.

=item B<$string = $Ack-E<gt>pack()>

Serializes C<Ack> into C<string>.

=item B<$length = $Ack-E<gt>length()>

Returns the serialized length of C<Ack>.

=item B<@fields = $Ack-E<gt>fields()>

Returns the defined fields of C<Ack>.

=item B<$hashref = $Ack-E<gt>to_hashref()>

Exports the message to a hashref suitable for use in the
C<copy_from> or C<merge_from> methods.

=item B<$has_subject = $Ack-E<gt>has_subject()>

Returns 1 if the C<subject> element of C<Ack> is set, 0 otherwise.

=item B<$Ack-E<gt>clear_subject()>

Clears the C<subject> element(s) of C<Ack>.

=item B<$subject = $Ack-E<gt>subject()>

Returns C<subject> from C<Ack>.  C<subject> will be a string.

=item B<$Ack-E<gt>set_subject($value)>

Sets the value of C<subject> in C<Ack> to C<value>.  C<value> must be a string.

=item B<$has_sequence = $Ack-E<gt>has_sequence()>

Returns 1 if the C<sequence> element of C<Ack> is set, 0 otherwise.

=item B<$Ack-E<gt>clear_sequence()>

Clears the C<sequence> element(s) of C<Ack>.

=item B<$sequence = $Ack-E<gt>sequence()>

Returns C<sequence> from C<Ack>.  C<sequence> will be a 64-bit unsigned integer.

=item B<$Ack-E<gt>set_sequence($value)>

Sets the value of C<sequence> in C<Ack> to C<value>.  C<value> must be a 64-bit unsigned integer.


=back

=head1 AUTHOR

Generated from Net.NATS.Streaming.PB.Ack by the protoc compiler.

=head1 SEE ALSO

http://code.google.com/p/protobuf

=cut

=pod

=head1 NAME

Net::NATS::Streaming::PB::CloseRequest - Perl/XS interface to Net.NATS.Streaming.PB.CloseRequest

=head1 SYNOPSIS

=head2 Serializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::CloseRequest;

 my $CloseRequest = Net::NATS::Streaming::PB::CloseRequest->new;
 # Set fields in $CloseRequest...
 my $packCloseRequest = $CloseRequest->pack();

=head2 Unserializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::CloseRequest;

 my $packCloseRequest; # Read this from somewhere...
 my $CloseRequest = Net::NATS::Streaming::PB::CloseRequest->new;
 if ( $CloseRequest->unpack($packCloseRequest) ) {
   print "OK"
 } else {
   print "NOT OK"
 }

=head1 DESCRIPTION

Net::NATS::Streaming::PB::CloseRequest defines the following classes:

=over 5

=item C<Net::NATS::Streaming::PB::CloseRequest>

A wrapper around the Net.NATS.Streaming.PB.CloseRequest message


=back

=head1 Net::NATS::Streaming::PB::CloseRequest Constructor

=over 4

=item B<$CloseRequest = Net::NATS::Streaming::PB::CloseRequest-E<gt>new( [$arg] )>

Constructs an instance of C<Net::NATS::Streaming::PB::CloseRequest>.  If a hashref argument
is supplied, it is copied into the message instance as if
the copy_from() method were called immediately after
construction.  Otherwise, if a scalar argument is supplied,
it is interpreted as a serialized instance of the message
type, and the scalar is parsed to populate the message
fields.  Otherwise, if no argument is supplied, an empty
message instance is constructed.

=back

=head1 Net::NATS::Streaming::PB::CloseRequest Methods

=over 4

=item B<$CloseRequest2-E<gt>copy_from($CloseRequest1)>

Copies the contents of C<CloseRequest1> into C<CloseRequest2>.
C<CloseRequest2> is another instance of the same message type.

=item B<$CloseRequest2-E<gt>copy_from($hashref)>

Copies the contents of C<hashref> into C<CloseRequest2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$CloseRequest2-E<gt>merge_from($CloseRequest1)>

Merges the contents of C<CloseRequest1> into C<CloseRequest2>.
C<CloseRequest2> is another instance of the same message type.

=item B<$CloseRequest2-E<gt>merge_from($hashref)>

Merges the contents of C<hashref> into C<CloseRequest2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$CloseRequest-E<gt>clear()>

Clears the contents of C<CloseRequest>.

=item B<$init = $CloseRequest-E<gt>is_initialized()>

Returns 1 if C<CloseRequest> has been initialized with data.

=item B<$errstr = $CloseRequest-E<gt>error_string()>

Returns a comma-delimited string of initialization errors.

=item B<$CloseRequest-E<gt>discard_unknown_fields()>

Discards unknown fields from C<CloseRequest>.

=item B<$dstr = $CloseRequest-E<gt>debug_string()>

Returns a string representation of C<CloseRequest>.

=item B<$dstr = $CloseRequest-E<gt>short_debug_string()>

Returns a short string representation of C<CloseRequest>.

=item B<$ok = $CloseRequest-E<gt>unpack($string)>

Attempts to parse C<string> into C<CloseRequest>, returning 1 on success and 0 on failure.

=item B<$string = $CloseRequest-E<gt>pack()>

Serializes C<CloseRequest> into C<string>.

=item B<$length = $CloseRequest-E<gt>length()>

Returns the serialized length of C<CloseRequest>.

=item B<@fields = $CloseRequest-E<gt>fields()>

Returns the defined fields of C<CloseRequest>.

=item B<$hashref = $CloseRequest-E<gt>to_hashref()>

Exports the message to a hashref suitable for use in the
C<copy_from> or C<merge_from> methods.

=item B<$has_clientID = $CloseRequest-E<gt>has_clientID()>

Returns 1 if the C<clientID> element of C<CloseRequest> is set, 0 otherwise.

=item B<$CloseRequest-E<gt>clear_clientID()>

Clears the C<clientID> element(s) of C<CloseRequest>.

=item B<$clientID = $CloseRequest-E<gt>clientID()>

Returns C<clientID> from C<CloseRequest>.  C<clientID> will be a string.

=item B<$CloseRequest-E<gt>set_clientID($value)>

Sets the value of C<clientID> in C<CloseRequest> to C<value>.  C<value> must be a string.


=back

=head1 AUTHOR

Generated from Net.NATS.Streaming.PB.CloseRequest by the protoc compiler.

=head1 SEE ALSO

http://code.google.com/p/protobuf

=cut

=pod

=head1 NAME

Net::NATS::Streaming::PB::CloseResponse - Perl/XS interface to Net.NATS.Streaming.PB.CloseResponse

=head1 SYNOPSIS

=head2 Serializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::CloseResponse;

 my $CloseResponse = Net::NATS::Streaming::PB::CloseResponse->new;
 # Set fields in $CloseResponse...
 my $packCloseResponse = $CloseResponse->pack();

=head2 Unserializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::CloseResponse;

 my $packCloseResponse; # Read this from somewhere...
 my $CloseResponse = Net::NATS::Streaming::PB::CloseResponse->new;
 if ( $CloseResponse->unpack($packCloseResponse) ) {
   print "OK"
 } else {
   print "NOT OK"
 }

=head1 DESCRIPTION

Net::NATS::Streaming::PB::CloseResponse defines the following classes:

=over 5

=item C<Net::NATS::Streaming::PB::CloseResponse>

A wrapper around the Net.NATS.Streaming.PB.CloseResponse message


=back

=head1 Net::NATS::Streaming::PB::CloseResponse Constructor

=over 4

=item B<$CloseResponse = Net::NATS::Streaming::PB::CloseResponse-E<gt>new( [$arg] )>

Constructs an instance of C<Net::NATS::Streaming::PB::CloseResponse>.  If a hashref argument
is supplied, it is copied into the message instance as if
the copy_from() method were called immediately after
construction.  Otherwise, if a scalar argument is supplied,
it is interpreted as a serialized instance of the message
type, and the scalar is parsed to populate the message
fields.  Otherwise, if no argument is supplied, an empty
message instance is constructed.

=back

=head1 Net::NATS::Streaming::PB::CloseResponse Methods

=over 4

=item B<$CloseResponse2-E<gt>copy_from($CloseResponse1)>

Copies the contents of C<CloseResponse1> into C<CloseResponse2>.
C<CloseResponse2> is another instance of the same message type.

=item B<$CloseResponse2-E<gt>copy_from($hashref)>

Copies the contents of C<hashref> into C<CloseResponse2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$CloseResponse2-E<gt>merge_from($CloseResponse1)>

Merges the contents of C<CloseResponse1> into C<CloseResponse2>.
C<CloseResponse2> is another instance of the same message type.

=item B<$CloseResponse2-E<gt>merge_from($hashref)>

Merges the contents of C<hashref> into C<CloseResponse2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$CloseResponse-E<gt>clear()>

Clears the contents of C<CloseResponse>.

=item B<$init = $CloseResponse-E<gt>is_initialized()>

Returns 1 if C<CloseResponse> has been initialized with data.

=item B<$errstr = $CloseResponse-E<gt>error_string()>

Returns a comma-delimited string of initialization errors.

=item B<$CloseResponse-E<gt>discard_unknown_fields()>

Discards unknown fields from C<CloseResponse>.

=item B<$dstr = $CloseResponse-E<gt>debug_string()>

Returns a string representation of C<CloseResponse>.

=item B<$dstr = $CloseResponse-E<gt>short_debug_string()>

Returns a short string representation of C<CloseResponse>.

=item B<$ok = $CloseResponse-E<gt>unpack($string)>

Attempts to parse C<string> into C<CloseResponse>, returning 1 on success and 0 on failure.

=item B<$string = $CloseResponse-E<gt>pack()>

Serializes C<CloseResponse> into C<string>.

=item B<$length = $CloseResponse-E<gt>length()>

Returns the serialized length of C<CloseResponse>.

=item B<@fields = $CloseResponse-E<gt>fields()>

Returns the defined fields of C<CloseResponse>.

=item B<$hashref = $CloseResponse-E<gt>to_hashref()>

Exports the message to a hashref suitable for use in the
C<copy_from> or C<merge_from> methods.

=item B<$has_error = $CloseResponse-E<gt>has_error()>

Returns 1 if the C<error> element of C<CloseResponse> is set, 0 otherwise.

=item B<$CloseResponse-E<gt>clear_error()>

Clears the C<error> element(s) of C<CloseResponse>.

=item B<$error = $CloseResponse-E<gt>error()>

Returns C<error> from C<CloseResponse>.  C<error> will be a string.

=item B<$CloseResponse-E<gt>set_error($value)>

Sets the value of C<error> in C<CloseResponse> to C<value>.  C<value> must be a string.


=back

=head1 AUTHOR

Generated from Net.NATS.Streaming.PB.CloseResponse by the protoc compiler.

=head1 SEE ALSO

http://code.google.com/p/protobuf

=cut

=pod

=head1 NAME

Net::NATS::Streaming::PB::ConnectRequest - Perl/XS interface to Net.NATS.Streaming.PB.ConnectRequest

=head1 SYNOPSIS

=head2 Serializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::ConnectRequest;

 my $ConnectRequest = Net::NATS::Streaming::PB::ConnectRequest->new;
 # Set fields in $ConnectRequest...
 my $packConnectRequest = $ConnectRequest->pack();

=head2 Unserializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::ConnectRequest;

 my $packConnectRequest; # Read this from somewhere...
 my $ConnectRequest = Net::NATS::Streaming::PB::ConnectRequest->new;
 if ( $ConnectRequest->unpack($packConnectRequest) ) {
   print "OK"
 } else {
   print "NOT OK"
 }

=head1 DESCRIPTION

Net::NATS::Streaming::PB::ConnectRequest defines the following classes:

=over 5

=item C<Net::NATS::Streaming::PB::ConnectRequest>

A wrapper around the Net.NATS.Streaming.PB.ConnectRequest message


=back

=head1 Net::NATS::Streaming::PB::ConnectRequest Constructor

=over 4

=item B<$ConnectRequest = Net::NATS::Streaming::PB::ConnectRequest-E<gt>new( [$arg] )>

Constructs an instance of C<Net::NATS::Streaming::PB::ConnectRequest>.  If a hashref argument
is supplied, it is copied into the message instance as if
the copy_from() method were called immediately after
construction.  Otherwise, if a scalar argument is supplied,
it is interpreted as a serialized instance of the message
type, and the scalar is parsed to populate the message
fields.  Otherwise, if no argument is supplied, an empty
message instance is constructed.

=back

=head1 Net::NATS::Streaming::PB::ConnectRequest Methods

=over 4

=item B<$ConnectRequest2-E<gt>copy_from($ConnectRequest1)>

Copies the contents of C<ConnectRequest1> into C<ConnectRequest2>.
C<ConnectRequest2> is another instance of the same message type.

=item B<$ConnectRequest2-E<gt>copy_from($hashref)>

Copies the contents of C<hashref> into C<ConnectRequest2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$ConnectRequest2-E<gt>merge_from($ConnectRequest1)>

Merges the contents of C<ConnectRequest1> into C<ConnectRequest2>.
C<ConnectRequest2> is another instance of the same message type.

=item B<$ConnectRequest2-E<gt>merge_from($hashref)>

Merges the contents of C<hashref> into C<ConnectRequest2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$ConnectRequest-E<gt>clear()>

Clears the contents of C<ConnectRequest>.

=item B<$init = $ConnectRequest-E<gt>is_initialized()>

Returns 1 if C<ConnectRequest> has been initialized with data.

=item B<$errstr = $ConnectRequest-E<gt>error_string()>

Returns a comma-delimited string of initialization errors.

=item B<$ConnectRequest-E<gt>discard_unknown_fields()>

Discards unknown fields from C<ConnectRequest>.

=item B<$dstr = $ConnectRequest-E<gt>debug_string()>

Returns a string representation of C<ConnectRequest>.

=item B<$dstr = $ConnectRequest-E<gt>short_debug_string()>

Returns a short string representation of C<ConnectRequest>.

=item B<$ok = $ConnectRequest-E<gt>unpack($string)>

Attempts to parse C<string> into C<ConnectRequest>, returning 1 on success and 0 on failure.

=item B<$string = $ConnectRequest-E<gt>pack()>

Serializes C<ConnectRequest> into C<string>.

=item B<$length = $ConnectRequest-E<gt>length()>

Returns the serialized length of C<ConnectRequest>.

=item B<@fields = $ConnectRequest-E<gt>fields()>

Returns the defined fields of C<ConnectRequest>.

=item B<$hashref = $ConnectRequest-E<gt>to_hashref()>

Exports the message to a hashref suitable for use in the
C<copy_from> or C<merge_from> methods.

=item B<$has_clientID = $ConnectRequest-E<gt>has_clientID()>

Returns 1 if the C<clientID> element of C<ConnectRequest> is set, 0 otherwise.

=item B<$ConnectRequest-E<gt>clear_clientID()>

Clears the C<clientID> element(s) of C<ConnectRequest>.

=item B<$clientID = $ConnectRequest-E<gt>clientID()>

Returns C<clientID> from C<ConnectRequest>.  C<clientID> will be a string.

=item B<$ConnectRequest-E<gt>set_clientID($value)>

Sets the value of C<clientID> in C<ConnectRequest> to C<value>.  C<value> must be a string.

=item B<$has_heartbeatInbox = $ConnectRequest-E<gt>has_heartbeatInbox()>

Returns 1 if the C<heartbeatInbox> element of C<ConnectRequest> is set, 0 otherwise.

=item B<$ConnectRequest-E<gt>clear_heartbeatInbox()>

Clears the C<heartbeatInbox> element(s) of C<ConnectRequest>.

=item B<$heartbeatInbox = $ConnectRequest-E<gt>heartbeatInbox()>

Returns C<heartbeatInbox> from C<ConnectRequest>.  C<heartbeatInbox> will be a string.

=item B<$ConnectRequest-E<gt>set_heartbeatInbox($value)>

Sets the value of C<heartbeatInbox> in C<ConnectRequest> to C<value>.  C<value> must be a string.


=back

=head1 AUTHOR

Generated from Net.NATS.Streaming.PB.ConnectRequest by the protoc compiler.

=head1 SEE ALSO

http://code.google.com/p/protobuf

=cut

=pod

=head1 NAME

Net::NATS::Streaming::PB::ConnectResponse - Perl/XS interface to Net.NATS.Streaming.PB.ConnectResponse

=head1 SYNOPSIS

=head2 Serializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::ConnectResponse;

 my $ConnectResponse = Net::NATS::Streaming::PB::ConnectResponse->new;
 # Set fields in $ConnectResponse...
 my $packConnectResponse = $ConnectResponse->pack();

=head2 Unserializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::ConnectResponse;

 my $packConnectResponse; # Read this from somewhere...
 my $ConnectResponse = Net::NATS::Streaming::PB::ConnectResponse->new;
 if ( $ConnectResponse->unpack($packConnectResponse) ) {
   print "OK"
 } else {
   print "NOT OK"
 }

=head1 DESCRIPTION

Net::NATS::Streaming::PB::ConnectResponse defines the following classes:

=over 5

=item C<Net::NATS::Streaming::PB::ConnectResponse>

A wrapper around the Net.NATS.Streaming.PB.ConnectResponse message


=back

=head1 Net::NATS::Streaming::PB::ConnectResponse Constructor

=over 4

=item B<$ConnectResponse = Net::NATS::Streaming::PB::ConnectResponse-E<gt>new( [$arg] )>

Constructs an instance of C<Net::NATS::Streaming::PB::ConnectResponse>.  If a hashref argument
is supplied, it is copied into the message instance as if
the copy_from() method were called immediately after
construction.  Otherwise, if a scalar argument is supplied,
it is interpreted as a serialized instance of the message
type, and the scalar is parsed to populate the message
fields.  Otherwise, if no argument is supplied, an empty
message instance is constructed.

=back

=head1 Net::NATS::Streaming::PB::ConnectResponse Methods

=over 4

=item B<$ConnectResponse2-E<gt>copy_from($ConnectResponse1)>

Copies the contents of C<ConnectResponse1> into C<ConnectResponse2>.
C<ConnectResponse2> is another instance of the same message type.

=item B<$ConnectResponse2-E<gt>copy_from($hashref)>

Copies the contents of C<hashref> into C<ConnectResponse2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$ConnectResponse2-E<gt>merge_from($ConnectResponse1)>

Merges the contents of C<ConnectResponse1> into C<ConnectResponse2>.
C<ConnectResponse2> is another instance of the same message type.

=item B<$ConnectResponse2-E<gt>merge_from($hashref)>

Merges the contents of C<hashref> into C<ConnectResponse2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$ConnectResponse-E<gt>clear()>

Clears the contents of C<ConnectResponse>.

=item B<$init = $ConnectResponse-E<gt>is_initialized()>

Returns 1 if C<ConnectResponse> has been initialized with data.

=item B<$errstr = $ConnectResponse-E<gt>error_string()>

Returns a comma-delimited string of initialization errors.

=item B<$ConnectResponse-E<gt>discard_unknown_fields()>

Discards unknown fields from C<ConnectResponse>.

=item B<$dstr = $ConnectResponse-E<gt>debug_string()>

Returns a string representation of C<ConnectResponse>.

=item B<$dstr = $ConnectResponse-E<gt>short_debug_string()>

Returns a short string representation of C<ConnectResponse>.

=item B<$ok = $ConnectResponse-E<gt>unpack($string)>

Attempts to parse C<string> into C<ConnectResponse>, returning 1 on success and 0 on failure.

=item B<$string = $ConnectResponse-E<gt>pack()>

Serializes C<ConnectResponse> into C<string>.

=item B<$length = $ConnectResponse-E<gt>length()>

Returns the serialized length of C<ConnectResponse>.

=item B<@fields = $ConnectResponse-E<gt>fields()>

Returns the defined fields of C<ConnectResponse>.

=item B<$hashref = $ConnectResponse-E<gt>to_hashref()>

Exports the message to a hashref suitable for use in the
C<copy_from> or C<merge_from> methods.

=item B<$has_pubPrefix = $ConnectResponse-E<gt>has_pubPrefix()>

Returns 1 if the C<pubPrefix> element of C<ConnectResponse> is set, 0 otherwise.

=item B<$ConnectResponse-E<gt>clear_pubPrefix()>

Clears the C<pubPrefix> element(s) of C<ConnectResponse>.

=item B<$pubPrefix = $ConnectResponse-E<gt>pubPrefix()>

Returns C<pubPrefix> from C<ConnectResponse>.  C<pubPrefix> will be a string.

=item B<$ConnectResponse-E<gt>set_pubPrefix($value)>

Sets the value of C<pubPrefix> in C<ConnectResponse> to C<value>.  C<value> must be a string.

=item B<$has_subRequests = $ConnectResponse-E<gt>has_subRequests()>

Returns 1 if the C<subRequests> element of C<ConnectResponse> is set, 0 otherwise.

=item B<$ConnectResponse-E<gt>clear_subRequests()>

Clears the C<subRequests> element(s) of C<ConnectResponse>.

=item B<$subRequests = $ConnectResponse-E<gt>subRequests()>

Returns C<subRequests> from C<ConnectResponse>.  C<subRequests> will be a string.

=item B<$ConnectResponse-E<gt>set_subRequests($value)>

Sets the value of C<subRequests> in C<ConnectResponse> to C<value>.  C<value> must be a string.

=item B<$has_unsubRequests = $ConnectResponse-E<gt>has_unsubRequests()>

Returns 1 if the C<unsubRequests> element of C<ConnectResponse> is set, 0 otherwise.

=item B<$ConnectResponse-E<gt>clear_unsubRequests()>

Clears the C<unsubRequests> element(s) of C<ConnectResponse>.

=item B<$unsubRequests = $ConnectResponse-E<gt>unsubRequests()>

Returns C<unsubRequests> from C<ConnectResponse>.  C<unsubRequests> will be a string.

=item B<$ConnectResponse-E<gt>set_unsubRequests($value)>

Sets the value of C<unsubRequests> in C<ConnectResponse> to C<value>.  C<value> must be a string.

=item B<$has_closeRequests = $ConnectResponse-E<gt>has_closeRequests()>

Returns 1 if the C<closeRequests> element of C<ConnectResponse> is set, 0 otherwise.

=item B<$ConnectResponse-E<gt>clear_closeRequests()>

Clears the C<closeRequests> element(s) of C<ConnectResponse>.

=item B<$closeRequests = $ConnectResponse-E<gt>closeRequests()>

Returns C<closeRequests> from C<ConnectResponse>.  C<closeRequests> will be a string.

=item B<$ConnectResponse-E<gt>set_closeRequests($value)>

Sets the value of C<closeRequests> in C<ConnectResponse> to C<value>.  C<value> must be a string.

=item B<$has_error = $ConnectResponse-E<gt>has_error()>

Returns 1 if the C<error> element of C<ConnectResponse> is set, 0 otherwise.

=item B<$ConnectResponse-E<gt>clear_error()>

Clears the C<error> element(s) of C<ConnectResponse>.

=item B<$error = $ConnectResponse-E<gt>error()>

Returns C<error> from C<ConnectResponse>.  C<error> will be a string.

=item B<$ConnectResponse-E<gt>set_error($value)>

Sets the value of C<error> in C<ConnectResponse> to C<value>.  C<value> must be a string.

=item B<$has_subCloseRequests = $ConnectResponse-E<gt>has_subCloseRequests()>

Returns 1 if the C<subCloseRequests> element of C<ConnectResponse> is set, 0 otherwise.

=item B<$ConnectResponse-E<gt>clear_subCloseRequests()>

Clears the C<subCloseRequests> element(s) of C<ConnectResponse>.

=item B<$subCloseRequests = $ConnectResponse-E<gt>subCloseRequests()>

Returns C<subCloseRequests> from C<ConnectResponse>.  C<subCloseRequests> will be a string.

=item B<$ConnectResponse-E<gt>set_subCloseRequests($value)>

Sets the value of C<subCloseRequests> in C<ConnectResponse> to C<value>.  C<value> must be a string.

=item B<$has_publicKey = $ConnectResponse-E<gt>has_publicKey()>

Returns 1 if the C<publicKey> element of C<ConnectResponse> is set, 0 otherwise.

=item B<$ConnectResponse-E<gt>clear_publicKey()>

Clears the C<publicKey> element(s) of C<ConnectResponse>.

=item B<$publicKey = $ConnectResponse-E<gt>publicKey()>

Returns C<publicKey> from C<ConnectResponse>.  C<publicKey> will be a string.

=item B<$ConnectResponse-E<gt>set_publicKey($value)>

Sets the value of C<publicKey> in C<ConnectResponse> to C<value>.  C<value> must be a string.


=back

=head1 AUTHOR

Generated from Net.NATS.Streaming.PB.ConnectResponse by the protoc compiler.

=head1 SEE ALSO

http://code.google.com/p/protobuf

=cut

=pod

=head1 NAME

Net::NATS::Streaming::PB::MsgProto - Perl/XS interface to Net.NATS.Streaming.PB.MsgProto

=head1 SYNOPSIS

=head2 Serializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::MsgProto;

 my $MsgProto = Net::NATS::Streaming::PB::MsgProto->new;
 # Set fields in $MsgProto...
 my $packMsgProto = $MsgProto->pack();

=head2 Unserializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::MsgProto;

 my $packMsgProto; # Read this from somewhere...
 my $MsgProto = Net::NATS::Streaming::PB::MsgProto->new;
 if ( $MsgProto->unpack($packMsgProto) ) {
   print "OK"
 } else {
   print "NOT OK"
 }

=head1 DESCRIPTION

Net::NATS::Streaming::PB::MsgProto defines the following classes:

=over 5

=item C<Net::NATS::Streaming::PB::MsgProto>

A wrapper around the Net.NATS.Streaming.PB.MsgProto message


=back

=head1 Net::NATS::Streaming::PB::MsgProto Constructor

=over 4

=item B<$MsgProto = Net::NATS::Streaming::PB::MsgProto-E<gt>new( [$arg] )>

Constructs an instance of C<Net::NATS::Streaming::PB::MsgProto>.  If a hashref argument
is supplied, it is copied into the message instance as if
the copy_from() method were called immediately after
construction.  Otherwise, if a scalar argument is supplied,
it is interpreted as a serialized instance of the message
type, and the scalar is parsed to populate the message
fields.  Otherwise, if no argument is supplied, an empty
message instance is constructed.

=back

=head1 Net::NATS::Streaming::PB::MsgProto Methods

=over 4

=item B<$MsgProto2-E<gt>copy_from($MsgProto1)>

Copies the contents of C<MsgProto1> into C<MsgProto2>.
C<MsgProto2> is another instance of the same message type.

=item B<$MsgProto2-E<gt>copy_from($hashref)>

Copies the contents of C<hashref> into C<MsgProto2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$MsgProto2-E<gt>merge_from($MsgProto1)>

Merges the contents of C<MsgProto1> into C<MsgProto2>.
C<MsgProto2> is another instance of the same message type.

=item B<$MsgProto2-E<gt>merge_from($hashref)>

Merges the contents of C<hashref> into C<MsgProto2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$MsgProto-E<gt>clear()>

Clears the contents of C<MsgProto>.

=item B<$init = $MsgProto-E<gt>is_initialized()>

Returns 1 if C<MsgProto> has been initialized with data.

=item B<$errstr = $MsgProto-E<gt>error_string()>

Returns a comma-delimited string of initialization errors.

=item B<$MsgProto-E<gt>discard_unknown_fields()>

Discards unknown fields from C<MsgProto>.

=item B<$dstr = $MsgProto-E<gt>debug_string()>

Returns a string representation of C<MsgProto>.

=item B<$dstr = $MsgProto-E<gt>short_debug_string()>

Returns a short string representation of C<MsgProto>.

=item B<$ok = $MsgProto-E<gt>unpack($string)>

Attempts to parse C<string> into C<MsgProto>, returning 1 on success and 0 on failure.

=item B<$string = $MsgProto-E<gt>pack()>

Serializes C<MsgProto> into C<string>.

=item B<$length = $MsgProto-E<gt>length()>

Returns the serialized length of C<MsgProto>.

=item B<@fields = $MsgProto-E<gt>fields()>

Returns the defined fields of C<MsgProto>.

=item B<$hashref = $MsgProto-E<gt>to_hashref()>

Exports the message to a hashref suitable for use in the
C<copy_from> or C<merge_from> methods.

=item B<$has_sequence = $MsgProto-E<gt>has_sequence()>

Returns 1 if the C<sequence> element of C<MsgProto> is set, 0 otherwise.

=item B<$MsgProto-E<gt>clear_sequence()>

Clears the C<sequence> element(s) of C<MsgProto>.

=item B<$sequence = $MsgProto-E<gt>sequence()>

Returns C<sequence> from C<MsgProto>.  C<sequence> will be a 64-bit unsigned integer.

=item B<$MsgProto-E<gt>set_sequence($value)>

Sets the value of C<sequence> in C<MsgProto> to C<value>.  C<value> must be a 64-bit unsigned integer.

=item B<$has_subject = $MsgProto-E<gt>has_subject()>

Returns 1 if the C<subject> element of C<MsgProto> is set, 0 otherwise.

=item B<$MsgProto-E<gt>clear_subject()>

Clears the C<subject> element(s) of C<MsgProto>.

=item B<$subject = $MsgProto-E<gt>subject()>

Returns C<subject> from C<MsgProto>.  C<subject> will be a string.

=item B<$MsgProto-E<gt>set_subject($value)>

Sets the value of C<subject> in C<MsgProto> to C<value>.  C<value> must be a string.

=item B<$has_reply = $MsgProto-E<gt>has_reply()>

Returns 1 if the C<reply> element of C<MsgProto> is set, 0 otherwise.

=item B<$MsgProto-E<gt>clear_reply()>

Clears the C<reply> element(s) of C<MsgProto>.

=item B<$reply = $MsgProto-E<gt>reply()>

Returns C<reply> from C<MsgProto>.  C<reply> will be a string.

=item B<$MsgProto-E<gt>set_reply($value)>

Sets the value of C<reply> in C<MsgProto> to C<value>.  C<value> must be a string.

=item B<$has_data = $MsgProto-E<gt>has_data()>

Returns 1 if the C<data> element of C<MsgProto> is set, 0 otherwise.

=item B<$MsgProto-E<gt>clear_data()>

Clears the C<data> element(s) of C<MsgProto>.

=item B<$data = $MsgProto-E<gt>data()>

Returns C<data> from C<MsgProto>.  C<data> will be a string.

=item B<$MsgProto-E<gt>set_data($value)>

Sets the value of C<data> in C<MsgProto> to C<value>.  C<value> must be a string.

=item B<$has_timestamp = $MsgProto-E<gt>has_timestamp()>

Returns 1 if the C<timestamp> element of C<MsgProto> is set, 0 otherwise.

=item B<$MsgProto-E<gt>clear_timestamp()>

Clears the C<timestamp> element(s) of C<MsgProto>.

=item B<$timestamp = $MsgProto-E<gt>timestamp()>

Returns C<timestamp> from C<MsgProto>.  C<timestamp> will be a 64-bit signed integer.

=item B<$MsgProto-E<gt>set_timestamp($value)>

Sets the value of C<timestamp> in C<MsgProto> to C<value>.  C<value> must be a 64-bit signed integer.

=item B<$has_redelivered = $MsgProto-E<gt>has_redelivered()>

Returns 1 if the C<redelivered> element of C<MsgProto> is set, 0 otherwise.

=item B<$MsgProto-E<gt>clear_redelivered()>

Clears the C<redelivered> element(s) of C<MsgProto>.

=item B<$redelivered = $MsgProto-E<gt>redelivered()>

Returns C<redelivered> from C<MsgProto>.  C<redelivered> will be a Boolean value.

=item B<$MsgProto-E<gt>set_redelivered($value)>

Sets the value of C<redelivered> in C<MsgProto> to C<value>.  C<value> must be a Boolean value.

=item B<$has_CRC32 = $MsgProto-E<gt>has_CRC32()>

Returns 1 if the C<CRC32> element of C<MsgProto> is set, 0 otherwise.

=item B<$MsgProto-E<gt>clear_CRC32()>

Clears the C<CRC32> element(s) of C<MsgProto>.

=item B<$CRC32 = $MsgProto-E<gt>CRC32()>

Returns C<CRC32> from C<MsgProto>.  C<CRC32> will be a 32-bit unsigned integer.

=item B<$MsgProto-E<gt>set_CRC32($value)>

Sets the value of C<CRC32> in C<MsgProto> to C<value>.  C<value> must be a 32-bit unsigned integer.


=back

=head1 AUTHOR

Generated from Net.NATS.Streaming.PB.MsgProto by the protoc compiler.

=head1 SEE ALSO

http://code.google.com/p/protobuf

=cut

=pod

=head1 NAME

Net::NATS::Streaming::PB::PubAck - Perl/XS interface to Net.NATS.Streaming.PB.PubAck

=head1 SYNOPSIS

=head2 Serializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::PubAck;

 my $PubAck = Net::NATS::Streaming::PB::PubAck->new;
 # Set fields in $PubAck...
 my $packPubAck = $PubAck->pack();

=head2 Unserializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::PubAck;

 my $packPubAck; # Read this from somewhere...
 my $PubAck = Net::NATS::Streaming::PB::PubAck->new;
 if ( $PubAck->unpack($packPubAck) ) {
   print "OK"
 } else {
   print "NOT OK"
 }

=head1 DESCRIPTION

Net::NATS::Streaming::PB::PubAck defines the following classes:

=over 5

=item C<Net::NATS::Streaming::PB::PubAck>

A wrapper around the Net.NATS.Streaming.PB.PubAck message


=back

=head1 Net::NATS::Streaming::PB::PubAck Constructor

=over 4

=item B<$PubAck = Net::NATS::Streaming::PB::PubAck-E<gt>new( [$arg] )>

Constructs an instance of C<Net::NATS::Streaming::PB::PubAck>.  If a hashref argument
is supplied, it is copied into the message instance as if
the copy_from() method were called immediately after
construction.  Otherwise, if a scalar argument is supplied,
it is interpreted as a serialized instance of the message
type, and the scalar is parsed to populate the message
fields.  Otherwise, if no argument is supplied, an empty
message instance is constructed.

=back

=head1 Net::NATS::Streaming::PB::PubAck Methods

=over 4

=item B<$PubAck2-E<gt>copy_from($PubAck1)>

Copies the contents of C<PubAck1> into C<PubAck2>.
C<PubAck2> is another instance of the same message type.

=item B<$PubAck2-E<gt>copy_from($hashref)>

Copies the contents of C<hashref> into C<PubAck2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$PubAck2-E<gt>merge_from($PubAck1)>

Merges the contents of C<PubAck1> into C<PubAck2>.
C<PubAck2> is another instance of the same message type.

=item B<$PubAck2-E<gt>merge_from($hashref)>

Merges the contents of C<hashref> into C<PubAck2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$PubAck-E<gt>clear()>

Clears the contents of C<PubAck>.

=item B<$init = $PubAck-E<gt>is_initialized()>

Returns 1 if C<PubAck> has been initialized with data.

=item B<$errstr = $PubAck-E<gt>error_string()>

Returns a comma-delimited string of initialization errors.

=item B<$PubAck-E<gt>discard_unknown_fields()>

Discards unknown fields from C<PubAck>.

=item B<$dstr = $PubAck-E<gt>debug_string()>

Returns a string representation of C<PubAck>.

=item B<$dstr = $PubAck-E<gt>short_debug_string()>

Returns a short string representation of C<PubAck>.

=item B<$ok = $PubAck-E<gt>unpack($string)>

Attempts to parse C<string> into C<PubAck>, returning 1 on success and 0 on failure.

=item B<$string = $PubAck-E<gt>pack()>

Serializes C<PubAck> into C<string>.

=item B<$length = $PubAck-E<gt>length()>

Returns the serialized length of C<PubAck>.

=item B<@fields = $PubAck-E<gt>fields()>

Returns the defined fields of C<PubAck>.

=item B<$hashref = $PubAck-E<gt>to_hashref()>

Exports the message to a hashref suitable for use in the
C<copy_from> or C<merge_from> methods.

=item B<$has_guid = $PubAck-E<gt>has_guid()>

Returns 1 if the C<guid> element of C<PubAck> is set, 0 otherwise.

=item B<$PubAck-E<gt>clear_guid()>

Clears the C<guid> element(s) of C<PubAck>.

=item B<$guid = $PubAck-E<gt>guid()>

Returns C<guid> from C<PubAck>.  C<guid> will be a string.

=item B<$PubAck-E<gt>set_guid($value)>

Sets the value of C<guid> in C<PubAck> to C<value>.  C<value> must be a string.

=item B<$has_error = $PubAck-E<gt>has_error()>

Returns 1 if the C<error> element of C<PubAck> is set, 0 otherwise.

=item B<$PubAck-E<gt>clear_error()>

Clears the C<error> element(s) of C<PubAck>.

=item B<$error = $PubAck-E<gt>error()>

Returns C<error> from C<PubAck>.  C<error> will be a string.

=item B<$PubAck-E<gt>set_error($value)>

Sets the value of C<error> in C<PubAck> to C<value>.  C<value> must be a string.


=back

=head1 AUTHOR

Generated from Net.NATS.Streaming.PB.PubAck by the protoc compiler.

=head1 SEE ALSO

http://code.google.com/p/protobuf

=cut

=pod

=head1 NAME

Net::NATS::Streaming::PB::PubMsg - Perl/XS interface to Net.NATS.Streaming.PB.PubMsg

=head1 SYNOPSIS

=head2 Serializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::PubMsg;

 my $PubMsg = Net::NATS::Streaming::PB::PubMsg->new;
 # Set fields in $PubMsg...
 my $packPubMsg = $PubMsg->pack();

=head2 Unserializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::PubMsg;

 my $packPubMsg; # Read this from somewhere...
 my $PubMsg = Net::NATS::Streaming::PB::PubMsg->new;
 if ( $PubMsg->unpack($packPubMsg) ) {
   print "OK"
 } else {
   print "NOT OK"
 }

=head1 DESCRIPTION

Net::NATS::Streaming::PB::PubMsg defines the following classes:

=over 5

=item C<Net::NATS::Streaming::PB::PubMsg>

A wrapper around the Net.NATS.Streaming.PB.PubMsg message


=back

=head1 Net::NATS::Streaming::PB::PubMsg Constructor

=over 4

=item B<$PubMsg = Net::NATS::Streaming::PB::PubMsg-E<gt>new( [$arg] )>

Constructs an instance of C<Net::NATS::Streaming::PB::PubMsg>.  If a hashref argument
is supplied, it is copied into the message instance as if
the copy_from() method were called immediately after
construction.  Otherwise, if a scalar argument is supplied,
it is interpreted as a serialized instance of the message
type, and the scalar is parsed to populate the message
fields.  Otherwise, if no argument is supplied, an empty
message instance is constructed.

=back

=head1 Net::NATS::Streaming::PB::PubMsg Methods

=over 4

=item B<$PubMsg2-E<gt>copy_from($PubMsg1)>

Copies the contents of C<PubMsg1> into C<PubMsg2>.
C<PubMsg2> is another instance of the same message type.

=item B<$PubMsg2-E<gt>copy_from($hashref)>

Copies the contents of C<hashref> into C<PubMsg2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$PubMsg2-E<gt>merge_from($PubMsg1)>

Merges the contents of C<PubMsg1> into C<PubMsg2>.
C<PubMsg2> is another instance of the same message type.

=item B<$PubMsg2-E<gt>merge_from($hashref)>

Merges the contents of C<hashref> into C<PubMsg2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$PubMsg-E<gt>clear()>

Clears the contents of C<PubMsg>.

=item B<$init = $PubMsg-E<gt>is_initialized()>

Returns 1 if C<PubMsg> has been initialized with data.

=item B<$errstr = $PubMsg-E<gt>error_string()>

Returns a comma-delimited string of initialization errors.

=item B<$PubMsg-E<gt>discard_unknown_fields()>

Discards unknown fields from C<PubMsg>.

=item B<$dstr = $PubMsg-E<gt>debug_string()>

Returns a string representation of C<PubMsg>.

=item B<$dstr = $PubMsg-E<gt>short_debug_string()>

Returns a short string representation of C<PubMsg>.

=item B<$ok = $PubMsg-E<gt>unpack($string)>

Attempts to parse C<string> into C<PubMsg>, returning 1 on success and 0 on failure.

=item B<$string = $PubMsg-E<gt>pack()>

Serializes C<PubMsg> into C<string>.

=item B<$length = $PubMsg-E<gt>length()>

Returns the serialized length of C<PubMsg>.

=item B<@fields = $PubMsg-E<gt>fields()>

Returns the defined fields of C<PubMsg>.

=item B<$hashref = $PubMsg-E<gt>to_hashref()>

Exports the message to a hashref suitable for use in the
C<copy_from> or C<merge_from> methods.

=item B<$has_clientID = $PubMsg-E<gt>has_clientID()>

Returns 1 if the C<clientID> element of C<PubMsg> is set, 0 otherwise.

=item B<$PubMsg-E<gt>clear_clientID()>

Clears the C<clientID> element(s) of C<PubMsg>.

=item B<$clientID = $PubMsg-E<gt>clientID()>

Returns C<clientID> from C<PubMsg>.  C<clientID> will be a string.

=item B<$PubMsg-E<gt>set_clientID($value)>

Sets the value of C<clientID> in C<PubMsg> to C<value>.  C<value> must be a string.

=item B<$has_guid = $PubMsg-E<gt>has_guid()>

Returns 1 if the C<guid> element of C<PubMsg> is set, 0 otherwise.

=item B<$PubMsg-E<gt>clear_guid()>

Clears the C<guid> element(s) of C<PubMsg>.

=item B<$guid = $PubMsg-E<gt>guid()>

Returns C<guid> from C<PubMsg>.  C<guid> will be a string.

=item B<$PubMsg-E<gt>set_guid($value)>

Sets the value of C<guid> in C<PubMsg> to C<value>.  C<value> must be a string.

=item B<$has_subject = $PubMsg-E<gt>has_subject()>

Returns 1 if the C<subject> element of C<PubMsg> is set, 0 otherwise.

=item B<$PubMsg-E<gt>clear_subject()>

Clears the C<subject> element(s) of C<PubMsg>.

=item B<$subject = $PubMsg-E<gt>subject()>

Returns C<subject> from C<PubMsg>.  C<subject> will be a string.

=item B<$PubMsg-E<gt>set_subject($value)>

Sets the value of C<subject> in C<PubMsg> to C<value>.  C<value> must be a string.

=item B<$has_reply = $PubMsg-E<gt>has_reply()>

Returns 1 if the C<reply> element of C<PubMsg> is set, 0 otherwise.

=item B<$PubMsg-E<gt>clear_reply()>

Clears the C<reply> element(s) of C<PubMsg>.

=item B<$reply = $PubMsg-E<gt>reply()>

Returns C<reply> from C<PubMsg>.  C<reply> will be a string.

=item B<$PubMsg-E<gt>set_reply($value)>

Sets the value of C<reply> in C<PubMsg> to C<value>.  C<value> must be a string.

=item B<$has_data = $PubMsg-E<gt>has_data()>

Returns 1 if the C<data> element of C<PubMsg> is set, 0 otherwise.

=item B<$PubMsg-E<gt>clear_data()>

Clears the C<data> element(s) of C<PubMsg>.

=item B<$data = $PubMsg-E<gt>data()>

Returns C<data> from C<PubMsg>.  C<data> will be a string.

=item B<$PubMsg-E<gt>set_data($value)>

Sets the value of C<data> in C<PubMsg> to C<value>.  C<value> must be a string.

=item B<$has_sha256 = $PubMsg-E<gt>has_sha256()>

Returns 1 if the C<sha256> element of C<PubMsg> is set, 0 otherwise.

=item B<$PubMsg-E<gt>clear_sha256()>

Clears the C<sha256> element(s) of C<PubMsg>.

=item B<$sha256 = $PubMsg-E<gt>sha256()>

Returns C<sha256> from C<PubMsg>.  C<sha256> will be a string.

=item B<$PubMsg-E<gt>set_sha256($value)>

Sets the value of C<sha256> in C<PubMsg> to C<value>.  C<value> must be a string.


=back

=head1 AUTHOR

Generated from Net.NATS.Streaming.PB.PubMsg by the protoc compiler.

=head1 SEE ALSO

http://code.google.com/p/protobuf

=cut

=pod

=head1 NAME

Net::NATS::Streaming::PB::SubscriptionRequest - Perl/XS interface to Net.NATS.Streaming.PB.SubscriptionRequest

=head1 SYNOPSIS

=head2 Serializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::SubscriptionRequest;

 my $SubscriptionRequest = Net::NATS::Streaming::PB::SubscriptionRequest->new;
 # Set fields in $SubscriptionRequest...
 my $packSubscriptionRequest = $SubscriptionRequest->pack();

=head2 Unserializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::SubscriptionRequest;

 my $packSubscriptionRequest; # Read this from somewhere...
 my $SubscriptionRequest = Net::NATS::Streaming::PB::SubscriptionRequest->new;
 if ( $SubscriptionRequest->unpack($packSubscriptionRequest) ) {
   print "OK"
 } else {
   print "NOT OK"
 }

=head1 DESCRIPTION

Net::NATS::Streaming::PB::SubscriptionRequest defines the following classes:

=over 5

=item C<Net::NATS::Streaming::PB::SubscriptionRequest>

A wrapper around the Net.NATS.Streaming.PB.SubscriptionRequest message


=back

=head1 Net::NATS::Streaming::PB::SubscriptionRequest Constructor

=over 4

=item B<$SubscriptionRequest = Net::NATS::Streaming::PB::SubscriptionRequest-E<gt>new( [$arg] )>

Constructs an instance of C<Net::NATS::Streaming::PB::SubscriptionRequest>.  If a hashref argument
is supplied, it is copied into the message instance as if
the copy_from() method were called immediately after
construction.  Otherwise, if a scalar argument is supplied,
it is interpreted as a serialized instance of the message
type, and the scalar is parsed to populate the message
fields.  Otherwise, if no argument is supplied, an empty
message instance is constructed.

=back

=head1 Net::NATS::Streaming::PB::SubscriptionRequest Methods

=over 4

=item B<$SubscriptionRequest2-E<gt>copy_from($SubscriptionRequest1)>

Copies the contents of C<SubscriptionRequest1> into C<SubscriptionRequest2>.
C<SubscriptionRequest2> is another instance of the same message type.

=item B<$SubscriptionRequest2-E<gt>copy_from($hashref)>

Copies the contents of C<hashref> into C<SubscriptionRequest2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$SubscriptionRequest2-E<gt>merge_from($SubscriptionRequest1)>

Merges the contents of C<SubscriptionRequest1> into C<SubscriptionRequest2>.
C<SubscriptionRequest2> is another instance of the same message type.

=item B<$SubscriptionRequest2-E<gt>merge_from($hashref)>

Merges the contents of C<hashref> into C<SubscriptionRequest2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$SubscriptionRequest-E<gt>clear()>

Clears the contents of C<SubscriptionRequest>.

=item B<$init = $SubscriptionRequest-E<gt>is_initialized()>

Returns 1 if C<SubscriptionRequest> has been initialized with data.

=item B<$errstr = $SubscriptionRequest-E<gt>error_string()>

Returns a comma-delimited string of initialization errors.

=item B<$SubscriptionRequest-E<gt>discard_unknown_fields()>

Discards unknown fields from C<SubscriptionRequest>.

=item B<$dstr = $SubscriptionRequest-E<gt>debug_string()>

Returns a string representation of C<SubscriptionRequest>.

=item B<$dstr = $SubscriptionRequest-E<gt>short_debug_string()>

Returns a short string representation of C<SubscriptionRequest>.

=item B<$ok = $SubscriptionRequest-E<gt>unpack($string)>

Attempts to parse C<string> into C<SubscriptionRequest>, returning 1 on success and 0 on failure.

=item B<$string = $SubscriptionRequest-E<gt>pack()>

Serializes C<SubscriptionRequest> into C<string>.

=item B<$length = $SubscriptionRequest-E<gt>length()>

Returns the serialized length of C<SubscriptionRequest>.

=item B<@fields = $SubscriptionRequest-E<gt>fields()>

Returns the defined fields of C<SubscriptionRequest>.

=item B<$hashref = $SubscriptionRequest-E<gt>to_hashref()>

Exports the message to a hashref suitable for use in the
C<copy_from> or C<merge_from> methods.

=item B<$has_clientID = $SubscriptionRequest-E<gt>has_clientID()>

Returns 1 if the C<clientID> element of C<SubscriptionRequest> is set, 0 otherwise.

=item B<$SubscriptionRequest-E<gt>clear_clientID()>

Clears the C<clientID> element(s) of C<SubscriptionRequest>.

=item B<$clientID = $SubscriptionRequest-E<gt>clientID()>

Returns C<clientID> from C<SubscriptionRequest>.  C<clientID> will be a string.

=item B<$SubscriptionRequest-E<gt>set_clientID($value)>

Sets the value of C<clientID> in C<SubscriptionRequest> to C<value>.  C<value> must be a string.

=item B<$has_subject = $SubscriptionRequest-E<gt>has_subject()>

Returns 1 if the C<subject> element of C<SubscriptionRequest> is set, 0 otherwise.

=item B<$SubscriptionRequest-E<gt>clear_subject()>

Clears the C<subject> element(s) of C<SubscriptionRequest>.

=item B<$subject = $SubscriptionRequest-E<gt>subject()>

Returns C<subject> from C<SubscriptionRequest>.  C<subject> will be a string.

=item B<$SubscriptionRequest-E<gt>set_subject($value)>

Sets the value of C<subject> in C<SubscriptionRequest> to C<value>.  C<value> must be a string.

=item B<$has_qGroup = $SubscriptionRequest-E<gt>has_qGroup()>

Returns 1 if the C<qGroup> element of C<SubscriptionRequest> is set, 0 otherwise.

=item B<$SubscriptionRequest-E<gt>clear_qGroup()>

Clears the C<qGroup> element(s) of C<SubscriptionRequest>.

=item B<$qGroup = $SubscriptionRequest-E<gt>qGroup()>

Returns C<qGroup> from C<SubscriptionRequest>.  C<qGroup> will be a string.

=item B<$SubscriptionRequest-E<gt>set_qGroup($value)>

Sets the value of C<qGroup> in C<SubscriptionRequest> to C<value>.  C<value> must be a string.

=item B<$has_inbox = $SubscriptionRequest-E<gt>has_inbox()>

Returns 1 if the C<inbox> element of C<SubscriptionRequest> is set, 0 otherwise.

=item B<$SubscriptionRequest-E<gt>clear_inbox()>

Clears the C<inbox> element(s) of C<SubscriptionRequest>.

=item B<$inbox = $SubscriptionRequest-E<gt>inbox()>

Returns C<inbox> from C<SubscriptionRequest>.  C<inbox> will be a string.

=item B<$SubscriptionRequest-E<gt>set_inbox($value)>

Sets the value of C<inbox> in C<SubscriptionRequest> to C<value>.  C<value> must be a string.

=item B<$has_maxInFlight = $SubscriptionRequest-E<gt>has_maxInFlight()>

Returns 1 if the C<maxInFlight> element of C<SubscriptionRequest> is set, 0 otherwise.

=item B<$SubscriptionRequest-E<gt>clear_maxInFlight()>

Clears the C<maxInFlight> element(s) of C<SubscriptionRequest>.

=item B<$maxInFlight = $SubscriptionRequest-E<gt>maxInFlight()>

Returns C<maxInFlight> from C<SubscriptionRequest>.  C<maxInFlight> will be a 32-bit signed integer.

=item B<$SubscriptionRequest-E<gt>set_maxInFlight($value)>

Sets the value of C<maxInFlight> in C<SubscriptionRequest> to C<value>.  C<value> must be a 32-bit signed integer.

=item B<$has_ackWaitInSecs = $SubscriptionRequest-E<gt>has_ackWaitInSecs()>

Returns 1 if the C<ackWaitInSecs> element of C<SubscriptionRequest> is set, 0 otherwise.

=item B<$SubscriptionRequest-E<gt>clear_ackWaitInSecs()>

Clears the C<ackWaitInSecs> element(s) of C<SubscriptionRequest>.

=item B<$ackWaitInSecs = $SubscriptionRequest-E<gt>ackWaitInSecs()>

Returns C<ackWaitInSecs> from C<SubscriptionRequest>.  C<ackWaitInSecs> will be a 32-bit signed integer.

=item B<$SubscriptionRequest-E<gt>set_ackWaitInSecs($value)>

Sets the value of C<ackWaitInSecs> in C<SubscriptionRequest> to C<value>.  C<value> must be a 32-bit signed integer.

=item B<$has_durableName = $SubscriptionRequest-E<gt>has_durableName()>

Returns 1 if the C<durableName> element of C<SubscriptionRequest> is set, 0 otherwise.

=item B<$SubscriptionRequest-E<gt>clear_durableName()>

Clears the C<durableName> element(s) of C<SubscriptionRequest>.

=item B<$durableName = $SubscriptionRequest-E<gt>durableName()>

Returns C<durableName> from C<SubscriptionRequest>.  C<durableName> will be a string.

=item B<$SubscriptionRequest-E<gt>set_durableName($value)>

Sets the value of C<durableName> in C<SubscriptionRequest> to C<value>.  C<value> must be a string.

=item B<$has_startPosition = $SubscriptionRequest-E<gt>has_startPosition()>

Returns 1 if the C<startPosition> element of C<SubscriptionRequest> is set, 0 otherwise.

=item B<$SubscriptionRequest-E<gt>clear_startPosition()>

Clears the C<startPosition> element(s) of C<SubscriptionRequest>.

=item B<$startPosition = $SubscriptionRequest-E<gt>startPosition()>

Returns C<startPosition> from C<SubscriptionRequest>.  C<startPosition> will be a value of Net::NATS::Streaming::PB::StartPosition.

=item B<$SubscriptionRequest-E<gt>set_startPosition($value)>

Sets the value of C<startPosition> in C<SubscriptionRequest> to C<value>.  C<value> must be a value of Net::NATS::Streaming::PB::StartPosition.

=item B<$has_startSequence = $SubscriptionRequest-E<gt>has_startSequence()>

Returns 1 if the C<startSequence> element of C<SubscriptionRequest> is set, 0 otherwise.

=item B<$SubscriptionRequest-E<gt>clear_startSequence()>

Clears the C<startSequence> element(s) of C<SubscriptionRequest>.

=item B<$startSequence = $SubscriptionRequest-E<gt>startSequence()>

Returns C<startSequence> from C<SubscriptionRequest>.  C<startSequence> will be a 64-bit unsigned integer.

=item B<$SubscriptionRequest-E<gt>set_startSequence($value)>

Sets the value of C<startSequence> in C<SubscriptionRequest> to C<value>.  C<value> must be a 64-bit unsigned integer.

=item B<$has_startTimeDelta = $SubscriptionRequest-E<gt>has_startTimeDelta()>

Returns 1 if the C<startTimeDelta> element of C<SubscriptionRequest> is set, 0 otherwise.

=item B<$SubscriptionRequest-E<gt>clear_startTimeDelta()>

Clears the C<startTimeDelta> element(s) of C<SubscriptionRequest>.

=item B<$startTimeDelta = $SubscriptionRequest-E<gt>startTimeDelta()>

Returns C<startTimeDelta> from C<SubscriptionRequest>.  C<startTimeDelta> will be a 64-bit signed integer.

=item B<$SubscriptionRequest-E<gt>set_startTimeDelta($value)>

Sets the value of C<startTimeDelta> in C<SubscriptionRequest> to C<value>.  C<value> must be a 64-bit signed integer.


=back

=head1 AUTHOR

Generated from Net.NATS.Streaming.PB.SubscriptionRequest by the protoc compiler.

=head1 SEE ALSO

http://code.google.com/p/protobuf

=cut

=pod

=head1 NAME

Net::NATS::Streaming::PB::SubscriptionResponse - Perl/XS interface to Net.NATS.Streaming.PB.SubscriptionResponse

=head1 SYNOPSIS

=head2 Serializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::SubscriptionResponse;

 my $SubscriptionResponse = Net::NATS::Streaming::PB::SubscriptionResponse->new;
 # Set fields in $SubscriptionResponse...
 my $packSubscriptionResponse = $SubscriptionResponse->pack();

=head2 Unserializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::SubscriptionResponse;

 my $packSubscriptionResponse; # Read this from somewhere...
 my $SubscriptionResponse = Net::NATS::Streaming::PB::SubscriptionResponse->new;
 if ( $SubscriptionResponse->unpack($packSubscriptionResponse) ) {
   print "OK"
 } else {
   print "NOT OK"
 }

=head1 DESCRIPTION

Net::NATS::Streaming::PB::SubscriptionResponse defines the following classes:

=over 5

=item C<Net::NATS::Streaming::PB::SubscriptionResponse>

A wrapper around the Net.NATS.Streaming.PB.SubscriptionResponse message


=back

=head1 Net::NATS::Streaming::PB::SubscriptionResponse Constructor

=over 4

=item B<$SubscriptionResponse = Net::NATS::Streaming::PB::SubscriptionResponse-E<gt>new( [$arg] )>

Constructs an instance of C<Net::NATS::Streaming::PB::SubscriptionResponse>.  If a hashref argument
is supplied, it is copied into the message instance as if
the copy_from() method were called immediately after
construction.  Otherwise, if a scalar argument is supplied,
it is interpreted as a serialized instance of the message
type, and the scalar is parsed to populate the message
fields.  Otherwise, if no argument is supplied, an empty
message instance is constructed.

=back

=head1 Net::NATS::Streaming::PB::SubscriptionResponse Methods

=over 4

=item B<$SubscriptionResponse2-E<gt>copy_from($SubscriptionResponse1)>

Copies the contents of C<SubscriptionResponse1> into C<SubscriptionResponse2>.
C<SubscriptionResponse2> is another instance of the same message type.

=item B<$SubscriptionResponse2-E<gt>copy_from($hashref)>

Copies the contents of C<hashref> into C<SubscriptionResponse2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$SubscriptionResponse2-E<gt>merge_from($SubscriptionResponse1)>

Merges the contents of C<SubscriptionResponse1> into C<SubscriptionResponse2>.
C<SubscriptionResponse2> is another instance of the same message type.

=item B<$SubscriptionResponse2-E<gt>merge_from($hashref)>

Merges the contents of C<hashref> into C<SubscriptionResponse2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$SubscriptionResponse-E<gt>clear()>

Clears the contents of C<SubscriptionResponse>.

=item B<$init = $SubscriptionResponse-E<gt>is_initialized()>

Returns 1 if C<SubscriptionResponse> has been initialized with data.

=item B<$errstr = $SubscriptionResponse-E<gt>error_string()>

Returns a comma-delimited string of initialization errors.

=item B<$SubscriptionResponse-E<gt>discard_unknown_fields()>

Discards unknown fields from C<SubscriptionResponse>.

=item B<$dstr = $SubscriptionResponse-E<gt>debug_string()>

Returns a string representation of C<SubscriptionResponse>.

=item B<$dstr = $SubscriptionResponse-E<gt>short_debug_string()>

Returns a short string representation of C<SubscriptionResponse>.

=item B<$ok = $SubscriptionResponse-E<gt>unpack($string)>

Attempts to parse C<string> into C<SubscriptionResponse>, returning 1 on success and 0 on failure.

=item B<$string = $SubscriptionResponse-E<gt>pack()>

Serializes C<SubscriptionResponse> into C<string>.

=item B<$length = $SubscriptionResponse-E<gt>length()>

Returns the serialized length of C<SubscriptionResponse>.

=item B<@fields = $SubscriptionResponse-E<gt>fields()>

Returns the defined fields of C<SubscriptionResponse>.

=item B<$hashref = $SubscriptionResponse-E<gt>to_hashref()>

Exports the message to a hashref suitable for use in the
C<copy_from> or C<merge_from> methods.

=item B<$has_ackInbox = $SubscriptionResponse-E<gt>has_ackInbox()>

Returns 1 if the C<ackInbox> element of C<SubscriptionResponse> is set, 0 otherwise.

=item B<$SubscriptionResponse-E<gt>clear_ackInbox()>

Clears the C<ackInbox> element(s) of C<SubscriptionResponse>.

=item B<$ackInbox = $SubscriptionResponse-E<gt>ackInbox()>

Returns C<ackInbox> from C<SubscriptionResponse>.  C<ackInbox> will be a string.

=item B<$SubscriptionResponse-E<gt>set_ackInbox($value)>

Sets the value of C<ackInbox> in C<SubscriptionResponse> to C<value>.  C<value> must be a string.

=item B<$has_error = $SubscriptionResponse-E<gt>has_error()>

Returns 1 if the C<error> element of C<SubscriptionResponse> is set, 0 otherwise.

=item B<$SubscriptionResponse-E<gt>clear_error()>

Clears the C<error> element(s) of C<SubscriptionResponse>.

=item B<$error = $SubscriptionResponse-E<gt>error()>

Returns C<error> from C<SubscriptionResponse>.  C<error> will be a string.

=item B<$SubscriptionResponse-E<gt>set_error($value)>

Sets the value of C<error> in C<SubscriptionResponse> to C<value>.  C<value> must be a string.


=back

=head1 AUTHOR

Generated from Net.NATS.Streaming.PB.SubscriptionResponse by the protoc compiler.

=head1 SEE ALSO

http://code.google.com/p/protobuf

=cut

=pod

=head1 NAME

Net::NATS::Streaming::PB::UnsubscribeRequest - Perl/XS interface to Net.NATS.Streaming.PB.UnsubscribeRequest

=head1 SYNOPSIS

=head2 Serializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::UnsubscribeRequest;

 my $UnsubscribeRequest = Net::NATS::Streaming::PB::UnsubscribeRequest->new;
 # Set fields in $UnsubscribeRequest...
 my $packUnsubscribeRequest = $UnsubscribeRequest->pack();

=head2 Unserializing messages

 #!/usr/bin/perl

 use strict;
 use warnings;
 use Net::NATS::Streaming::PB::UnsubscribeRequest;

 my $packUnsubscribeRequest; # Read this from somewhere...
 my $UnsubscribeRequest = Net::NATS::Streaming::PB::UnsubscribeRequest->new;
 if ( $UnsubscribeRequest->unpack($packUnsubscribeRequest) ) {
   print "OK"
 } else {
   print "NOT OK"
 }

=head1 DESCRIPTION

Net::NATS::Streaming::PB::UnsubscribeRequest defines the following classes:

=over 5

=item C<Net::NATS::Streaming::PB::UnsubscribeRequest>

A wrapper around the Net.NATS.Streaming.PB.UnsubscribeRequest message


=back

=head1 Net::NATS::Streaming::PB::UnsubscribeRequest Constructor

=over 4

=item B<$UnsubscribeRequest = Net::NATS::Streaming::PB::UnsubscribeRequest-E<gt>new( [$arg] )>

Constructs an instance of C<Net::NATS::Streaming::PB::UnsubscribeRequest>.  If a hashref argument
is supplied, it is copied into the message instance as if
the copy_from() method were called immediately after
construction.  Otherwise, if a scalar argument is supplied,
it is interpreted as a serialized instance of the message
type, and the scalar is parsed to populate the message
fields.  Otherwise, if no argument is supplied, an empty
message instance is constructed.

=back

=head1 Net::NATS::Streaming::PB::UnsubscribeRequest Methods

=over 4

=item B<$UnsubscribeRequest2-E<gt>copy_from($UnsubscribeRequest1)>

Copies the contents of C<UnsubscribeRequest1> into C<UnsubscribeRequest2>.
C<UnsubscribeRequest2> is another instance of the same message type.

=item B<$UnsubscribeRequest2-E<gt>copy_from($hashref)>

Copies the contents of C<hashref> into C<UnsubscribeRequest2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$UnsubscribeRequest2-E<gt>merge_from($UnsubscribeRequest1)>

Merges the contents of C<UnsubscribeRequest1> into C<UnsubscribeRequest2>.
C<UnsubscribeRequest2> is another instance of the same message type.

=item B<$UnsubscribeRequest2-E<gt>merge_from($hashref)>

Merges the contents of C<hashref> into C<UnsubscribeRequest2>.
C<hashref> is a Data::Dumper-style representation of an
instance of the message type.

=item B<$UnsubscribeRequest-E<gt>clear()>

Clears the contents of C<UnsubscribeRequest>.

=item B<$init = $UnsubscribeRequest-E<gt>is_initialized()>

Returns 1 if C<UnsubscribeRequest> has been initialized with data.

=item B<$errstr = $UnsubscribeRequest-E<gt>error_string()>

Returns a comma-delimited string of initialization errors.

=item B<$UnsubscribeRequest-E<gt>discard_unknown_fields()>

Discards unknown fields from C<UnsubscribeRequest>.

=item B<$dstr = $UnsubscribeRequest-E<gt>debug_string()>

Returns a string representation of C<UnsubscribeRequest>.

=item B<$dstr = $UnsubscribeRequest-E<gt>short_debug_string()>

Returns a short string representation of C<UnsubscribeRequest>.

=item B<$ok = $UnsubscribeRequest-E<gt>unpack($string)>

Attempts to parse C<string> into C<UnsubscribeRequest>, returning 1 on success and 0 on failure.

=item B<$string = $UnsubscribeRequest-E<gt>pack()>

Serializes C<UnsubscribeRequest> into C<string>.

=item B<$length = $UnsubscribeRequest-E<gt>length()>

Returns the serialized length of C<UnsubscribeRequest>.

=item B<@fields = $UnsubscribeRequest-E<gt>fields()>

Returns the defined fields of C<UnsubscribeRequest>.

=item B<$hashref = $UnsubscribeRequest-E<gt>to_hashref()>

Exports the message to a hashref suitable for use in the
C<copy_from> or C<merge_from> methods.

=item B<$has_clientID = $UnsubscribeRequest-E<gt>has_clientID()>

Returns 1 if the C<clientID> element of C<UnsubscribeRequest> is set, 0 otherwise.

=item B<$UnsubscribeRequest-E<gt>clear_clientID()>

Clears the C<clientID> element(s) of C<UnsubscribeRequest>.

=item B<$clientID = $UnsubscribeRequest-E<gt>clientID()>

Returns C<clientID> from C<UnsubscribeRequest>.  C<clientID> will be a string.

=item B<$UnsubscribeRequest-E<gt>set_clientID($value)>

Sets the value of C<clientID> in C<UnsubscribeRequest> to C<value>.  C<value> must be a string.

=item B<$has_subject = $UnsubscribeRequest-E<gt>has_subject()>

Returns 1 if the C<subject> element of C<UnsubscribeRequest> is set, 0 otherwise.

=item B<$UnsubscribeRequest-E<gt>clear_subject()>

Clears the C<subject> element(s) of C<UnsubscribeRequest>.

=item B<$subject = $UnsubscribeRequest-E<gt>subject()>

Returns C<subject> from C<UnsubscribeRequest>.  C<subject> will be a string.

=item B<$UnsubscribeRequest-E<gt>set_subject($value)>

Sets the value of C<subject> in C<UnsubscribeRequest> to C<value>.  C<value> must be a string.

=item B<$has_inbox = $UnsubscribeRequest-E<gt>has_inbox()>

Returns 1 if the C<inbox> element of C<UnsubscribeRequest> is set, 0 otherwise.

=item B<$UnsubscribeRequest-E<gt>clear_inbox()>

Clears the C<inbox> element(s) of C<UnsubscribeRequest>.

=item B<$inbox = $UnsubscribeRequest-E<gt>inbox()>

Returns C<inbox> from C<UnsubscribeRequest>.  C<inbox> will be a string.

=item B<$UnsubscribeRequest-E<gt>set_inbox($value)>

Sets the value of C<inbox> in C<UnsubscribeRequest> to C<value>.  C<value> must be a string.

=item B<$has_durableName = $UnsubscribeRequest-E<gt>has_durableName()>

Returns 1 if the C<durableName> element of C<UnsubscribeRequest> is set, 0 otherwise.

=item B<$UnsubscribeRequest-E<gt>clear_durableName()>

Clears the C<durableName> element(s) of C<UnsubscribeRequest>.

=item B<$durableName = $UnsubscribeRequest-E<gt>durableName()>

Returns C<durableName> from C<UnsubscribeRequest>.  C<durableName> will be a string.

=item B<$UnsubscribeRequest-E<gt>set_durableName($value)>

Sets the value of C<durableName> in C<UnsubscribeRequest> to C<value>.  C<value> must be a string.


=back

=head1 AUTHOR

Generated from Net.NATS.Streaming.PB.UnsubscribeRequest by the protoc compiler.

=head1 SEE ALSO

http://code.google.com/p/protobuf

=cut

=head1 REPOSITORY

L<https://github.com/sergeykolychev/perl-nats-streaming>

=head1 COPYRIGHT & LICENSE

    Copyright (C) 2017 by Sergey Kolychev <sergeykolychev.github@gmail.com>

    This library is licensed under Apache 2.0 license https://www.apache.org/licenses/LICENSE-2.0

=cut
