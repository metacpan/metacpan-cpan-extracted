package POE::Component::Server::Bayeux::Message::Invalid;

=head1 NAME

POE::Component::Server::Bayeux::Message::Invalid - invalid message

=head1 DESCRIPTION

Subclasses L<POE::Component::Server::Bayeux::Message>.  Just an error, really.

=cut

use strict;
use warnings;
use base qw(POE::Component::Server::Bayeux::Message);

sub is_error {
    return "Invalid message";
}

=head1 COPYRIGHT

Copyright (c) 2008 Eric Waters and XMission LLC (http://www.xmission.com/).
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with
this module.

=head1 AUTHOR

Eric Waters <ewaters@uarc.com>

=cut

1;
