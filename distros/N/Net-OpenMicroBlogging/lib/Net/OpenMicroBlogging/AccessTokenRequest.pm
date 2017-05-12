package Net::OpenMicroBlogging::AccessTokenRequest;
use warnings;
use strict;
use base qw(Net::OpenMicroBlogging::Message Net::OAuth::AccessTokenRequest);

__PACKAGE__->init_omb_message;

=head1 NAME

Net::OpenMicroBlogging::RequestTokenRequest - An OpenMicroBlogging protocol request for an Access Token

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