package Net::POP3::PerMsgHandler::Control;

=head1 NAME

Net::POP3::PerMsgHandler::Control - object for per_message callback

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
    qw/
        delete
        quit
    /
);

=head1 FUNCTIONS

=head2 delete

This is mutator. If true, delete message after callback. The default is false.

=head2 quit

This is mutator. If true, disconnect from server after callback. The default is false.

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
