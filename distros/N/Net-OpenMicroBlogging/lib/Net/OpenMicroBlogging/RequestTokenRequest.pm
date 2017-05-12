package Net::OpenMicroBlogging::RequestTokenRequest;
use warnings;
use strict;
use base qw(Net::OpenMicroBlogging::Message Net::OAuth::RequestTokenRequest);

__PACKAGE__->init_omb_message;
__PACKAGE__->add_required_message_params(qw/omb_version omb_listener/);

=head1 NAME

Net::OpenMicroBlogging::RequestTokenRequest - An OpenMicroBlogging protocol request for a Request Token

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