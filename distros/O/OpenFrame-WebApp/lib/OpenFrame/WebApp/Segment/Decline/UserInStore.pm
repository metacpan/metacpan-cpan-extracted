=head1 NAME

OpenFrame::WebApp::Segment::Decline::UserInStore - decline if User found in store

=head1 SYNOPSIS

  # see OpenFrame::WebApp::Segment::Decline

=cut

package OpenFrame::WebApp::Segment::Decline::UserInStore;

use strict;
use warnings::register;

use Pipeline::Production;
use OpenFrame::WebApp::Error::Abstract;

our $VERSION = (split(/ /, '$Revision: 1.1 $'))[1];

use base qw( OpenFrame::WebApp::Segment::Decline OpenFrame::WebApp::Segment::User );

use constant message => 'declined: user in store';

sub should_decline {
    my $self = shift;
    return $self->get_user_from_store ? 1 : 0;
}


1;

__END__

=head1 DESCRIPTION

Decline to process this pipe if a registered C<OpenFrame::WebApp::User> is
found in the store.

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::Segment::Decline>, L<OpenFrame::WebApp::Segment::User>

=cut
