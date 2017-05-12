package Net::OpenMicroBlogging::ProtectedResourceRequest;
use warnings;
use strict;
use base qw(Net::OAuth::ProtectedResourceRequest Net::OpenMicroBlogging::Message);

__PACKAGE__->init_omb_message;

=head1 NAME

Net::OpenMicroBlogging::ProtectedResourceRequest - An OpenMicroBlogging protocol request for a Protected Resource

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