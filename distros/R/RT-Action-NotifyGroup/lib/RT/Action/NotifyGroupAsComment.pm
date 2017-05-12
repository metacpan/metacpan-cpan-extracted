package RT::Action::NotifyGroupAsComment;
use strict;

our $VERSION = '0.01';

=head1 NAME

RT::Action::NotifyGroupAsComment - RT Action that sends notifications
to groups and/or users as comment

=head1 DESCRIPTION

This is subclass of RT::Action::NotifyGroup that send comments instead of replies.
See C<rt-notify-group-admin> and C<RT::Action::NotifyGroup> docs for more info.

=cut

use RT::Action::NotifyGroup;
local @RT::Action::NotifyGroup::ISA = qw(RT::Action::NotifyAsComment);

use base qw(RT::Action::NotifyGroup);

=head1 AUTHOR

	Ruslan U. Zakirov
	cubic@wildgate.miee.ru

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with perl distribution.

=cut

1;
