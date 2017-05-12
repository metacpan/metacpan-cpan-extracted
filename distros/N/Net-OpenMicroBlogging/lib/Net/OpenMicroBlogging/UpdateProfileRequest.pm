package Net::OpenMicroBlogging::UpdateProfileRequest;
use warnings;
use strict;
use base qw(Net::OpenMicroBlogging::Message Net::OpenMicroBlogging::ProtectedResourceRequest);

__PACKAGE__->init_omb_message;

__PACKAGE__->add_required_message_params(qw/
                                         omb_version
                                         omb_listenee
                                         /);

__PACKAGE__->add_optional_message_params(qw/
                                         omb_listenee_profile
                                         omb_listenee_fullname
                                         omb_listenee_nickname
                                         omb_listenee_homepage
                                         omb_listenee_license
                                         omb_listenee_bio
                                         omb_listenee_location
                                         omb_listenee_avatar
                                         /);

=head1 NAME

Net::OpenMicroBlogging::UpdateProfileRequest - An OpenMicroBlogging protocol request for a profile update

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