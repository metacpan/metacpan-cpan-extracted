package Net::OpenMicroBlogging::PostNoticeRequest;
use warnings;
use strict;
use base qw(Net::OpenMicroBlogging::Message Net::OpenMicroBlogging::ProtectedResourceRequest);

__PACKAGE__->init_omb_message;

__PACKAGE__->add_required_message_params(qw/
                                         omb_version
                                         omb_listenee
                                         omb_notice
                                         omb_notice_content
                                         /);

__PACKAGE__->add_optional_message_params(qw/
                                         omb_notice_url
                                         omb_notice_license
                                         omb_seealso
                                         omb_seealso_disposition
                                         omb_seealso_mediatype
                                         omb_seealso_license
                                         /);

=head1 NAME

Net::OpenMicroBlogging::PostNoticeRequest - An OpenMicroBlogging protocol request for posting a notice

=head1 SEE ALSO

L<Net::OpenMicroBlogging::Request>, L<http://openmicroblogging.org>

=head1 AUTHOR

Keith Grennan, C<< <kgrennan at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Keith Grennan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1;