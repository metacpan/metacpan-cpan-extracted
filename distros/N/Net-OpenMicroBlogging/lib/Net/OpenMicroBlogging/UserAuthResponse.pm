package Net::OpenMicroBlogging::UserAuthResponse;
use warnings;
use strict;
use base qw(Net::OpenMicroBlogging::Message Net::OAuth::UserAuthResponse);

__PACKAGE__->init_omb_message;

__PACKAGE__->add_required_message_params(qw/
                                         omb_version
                                         omb_listener_nickname
                                         omb_listener_profile
                                         /);

__PACKAGE__->add_optional_message_params(qw/
                                         omb_listener_fullname
                                         omb_listener_homepage
                                         omb_listener_bio
                                         omb_listener_location
                                         omb_listener_avatar
                                         /);

=head1 NAME

Net::OpenMicroBlogging::UserAuthResponse - An OpenMicroBlogging protocol response for user authentication

=head1 SEE ALSO

L<Net::OpenMicroBlogging>, L<http://openmicroblogging.org>

=head1 AUTHOR

Keith Grennan, C<< <kgrennan at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Keith Grennan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;