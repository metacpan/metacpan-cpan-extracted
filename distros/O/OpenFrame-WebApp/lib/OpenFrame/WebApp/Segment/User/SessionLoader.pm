=head1 NAME

OpenFrame::WebApp::Segment::User::SessionLoader - a pipeline segment to load
users from sessions

=head1 SYNOPSIS

  # see OpenFrame::WebApp::Segment::User::Loader for usage

  $OpenFrame::WebApp::Segment::User::Session::USER_KEY = 'my_user';

=cut

package OpenFrame::WebApp::Segment::User::SessionLoader;

use strict;
use warnings::register;

use base qw( OpenFrame::WebApp::Segment::User::Loader
	     OpenFrame::WebApp::Segment::User::Session );

our $VERSION = (split(/ /, '$Revision: 1.1 $'))[1];

sub get_user {
    my $self = shift;
    return $self->get_user_from_session;
}

1;

__END__

=head1 DESCRIPTION

Load a User from the stored Session.

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::User>,
L<OpenFrame::WebApp::Segment::User::Loader>,
L<OpenFrame::WebApp::Segment::User::Session>

=cut
