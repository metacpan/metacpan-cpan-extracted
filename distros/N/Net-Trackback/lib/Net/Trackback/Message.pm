# Copyright (c) 2003-2004 Timothy Appnel (cpan@timaoutloud.org)
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
package Net::Trackback::Message;
use strict;
use base qw( Class::ErrorHandler );

use Net::Trackback qw( encode_xml );

sub new { 
    my $self = bless {}, $_[0];
    # Should we filter out unknown fields?
    $self->{__stash} = $_[1] if $_[1];
    $self;
}

sub parse {
    my($class,$xml) = @_;
    # should use xml parser but...
    my($code) = $xml =~ m!<error>(\d+)</error>!s;
    my($message) = $xml =~ m!<message>(.+?)</message>!s;
    defined $code ? 
        $class->new({code=>$code,message=>$message}) : 
            $class->error('Invalid message.');
}

sub to_hash { %{ $_[0]->{__stash} } }

sub to_xml {
    my $self = shift;
    my $code = $self->{__stash}->{code} || 0;
    my $msg = encode_xml($self->{__stash}->{msg}) || '';
    my $xml = <<MESSAGE;
<?xml version="1.0" encoding="iso-8859-1"?>
<response>
  <error>$code</error>
  <message>$msg</message>
</response>
MESSAGE
    $xml;
}

sub code { $_[0]->{__stash}->{code} = $_[1] if $_[1]; $_[0]->{__stash}->{code}; }
sub message { $_[0]->{__stash}->{msg} = $_[1] if $_[1]; $_[0]->{__stash}->{msg}; }
sub is_success { !$_[0]->{__stash}->{code} }
sub is_error { $_[0]->{__stash}->{code} }

1;

__END__

=begin

=head1 NAME

Net::Trackback::Message - an object representing a Trackback message.

=head1 SYNOPSIS

 use Net::Trackback::Message;
 my $msg = Net::Trackback::Message->new();
 $msg->code(1);
 $msg->message("Live and let foo.")
 print $msg->to_xml;
 print $msg->is_success ? 'go.' : 'stop!';

=head1 METHODS

=item Net::Trackback::Message->new([$hashref])

Constuctor method. It will initialize the object if passed a 
hash reference. Recognized keys are code and message. These keys 
correspond to the methods like named methods.

=item Net::Trackback::Message->parse($xml)

A method that parses (albeit crude using regex) a Trackback message
and returns a message object. In the event a bad or
incomplete message has been passed in the method will return C<undef>.
The error message can be retreived with the C<errstr> method. One
required parameter, a string containing the message XML. 

=item $msg->code([$int])

An accessor to the message code, an integer. If an optional
parameter is passed in the value is set.

The Trackback specification only defines to codes 0 (success) and 
1 (error). This module takes the liberty of passing an HTTP error 
code instead of just a 1 if one occurs during processing.

=item $msg->message([$message])

An accessor to the body of the message. If an optional
parameter is passed in the value is set.

The Trackback specification does not define specific message strings. 
They are generally treated as text to display or log. The message 
body is not required when sending especially when it is a successful 
(code 0) ping, but its a good idea to include as informative a 
message as possible.

=item $msg->is_success

Returns a boolean value indicating whether the message object 
represents a successful ping or not.

=item $msg->is_error

Returns a boolean value indicating whether the message object 
represents an error while pinging or not.

=item $msg->to_hash

Returns a hash of the object's current state.

=item $msg->to_xml

Returns an XML representation of the Trackback message that can 
be sent as a response to a client.

=head2 Errors

This module is a subclass of L<Class::ErrorHandler> and inherits
two methods for passing error message back to a caller.

=item Class->error($message) 

=item $object->error($message)

Sets the error message for either the class Class or the object
$object to the message $message. Returns undef.

=item Class->errstr 

=item $object->errstr

Accesses the last error message set in the class Class or the
object $object, respectively, and returns that error message.

=head1 AUTHOR & COPYRIGHT

Please see the Net::Trackback manpage for author, copyright, and 
license information.

=cut

=end