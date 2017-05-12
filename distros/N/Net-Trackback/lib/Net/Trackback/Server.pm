# Copyright (c) 2003-2004 Timothy Appnel (cpan@timaoutloud.org)
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
package Net::Trackback::Server;
use strict;
use base qw( Class::ErrorHandler );

use Net::Trackback::Ping;
use Net::Trackback::Message;

sub receive_ping { 
    Net::Trackback::Ping->parse($_[1]) or
        $_[0]->error(Net::Trackback::Ping->errstr);
}

sub send_success { 
    my $msg = Net::Trackback::Message->new( {code=>0, message=>$_[1]} );
    print "Content-Type: text/xml\n\n".$msg->to_xml;
}

sub send_error { 
    my $msg = Net::Trackback::Message->new( {code=>1, message=>$_[1]} );
    print "Content-Type: text/xml\n\n".$msg->to_xml;
}

1;

__END__

=begin

=head1 NAME

Net::Trackback::Server - a super/static class for implementing
Trackback server functionality.

=head1 METHODS

=item Net::Trackback::Server->receive_ping($CGI)

Currently just an alias for Net::Trackback::Ping->parse.

=item Net::Trackback::Server->send_success($string)

Sends a success message (code 0) including the necessary 
Content-Type header and the supplied string parameter as 
its body.

=item Net::Trackback::Server->send_error($string)

Sends an error message (code 1) including the necessary 
Content-Type header and the supplied string parameter as 
its body.

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

=head1 TO DO

=item Way of sending an error message with a code other then 1.

=head1 AUTHOR & COPYRIGHT

Please see the Net::Trackback manpage for author, copyright, and 
license information.

=cut

=end