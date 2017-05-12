package Net::POP3::PerMsgHandler::Message;

=head1 NAME

Net::POP3::PerMsgHandler::Message - object for per_message callback

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
    qw/
        size
        rfc2822
        array_ref
        email_mime
        email_mime_stripped
        mail_message
        mail_message_stripped
    /
);

=head1 FUNCTIONS

=head2 size

return message length.

=head2 rfc2822

return message as RFC2822 format strings. (Envelope-from, headers and body)

=head2 array_ref

returns a reference to an array which contains the lines of message read from the server.

=head2 email_mime

returns Email::MIME instance.

=head2 email_mime_stripped

returns Email::MIME instance stripped by Email::MIME::Attachment::Stripper.

=head2 mail_message

returns Mail::Message instance.

=head2 mail_message_stripped

returns Mail::Message instance stripped by Mail::Message::Attachment::Stripper.

=head1 SEE ALSO

L<Net::POP3::PerMsgHandler>, L<Net::POP3>, L<Email::MIME>, L<Email::MIME::Attachment::Stripper>, L<Mail::Message>, L<Mail::Message::Attachment::Stripper>

=head1 AUTHOR

bokutin, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 bokutin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
