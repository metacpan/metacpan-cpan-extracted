=head1 NAME

OpenFrame::WebApp::Segment::User::EnvLoader - a pipeline segment to load users
from the environment.

=head1 SYNOPSIS

  # see OpenFrame::WebApp::Segment::User::Loader for usage
  # loads user specified by $ENV{REMOTE_USER}

=cut

package OpenFrame::WebApp::Segment::User::EnvLoader;

use strict;
use warnings::register;

our $VERSION = (split(/ /, '$Revision: 1.2 $'))[1];

use base qw( OpenFrame::WebApp::Segment::User::Loader );

sub find_user_id {
    my $self = shift;
    return $self->look_in_env;
}

sub look_in_env {
    my $self = shift;
    return $ENV{REMOTE_USER};
}


1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Segment::User::EnvLoader> class is a user loader that
gets user id's from the C<REMOTE_USER> environment var.  It inherits its
interface from C<OpenFrame::WebApp::Segment::User::Loader>.

=head1 METHODS

=over 4

=item $id = $obj->find_user_id()

finds user id.

=item $id = $obj->look_in_env()

gets user id from $ENV{REMOTE_USER}.

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::User>,
L<OpenFrame::WebApp::User::Factory>,
L<OpenFrame::WebApp::Segment::User::Loader>

=cut
