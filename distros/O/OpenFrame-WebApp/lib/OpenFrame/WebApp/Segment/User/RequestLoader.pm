=head1 NAME

OpenFrame::WebApp::Segment::User::RequestLoader - a pipeline segment to load
users from requests

=head1 SYNOPSIS

  # see OpenFrame::WebApp::Segment::User::Loader for usage

  # get id from request param: http://123.com/?user_id=id
  $OpenFrame::WebApp::Segment::User::RequestLoader::USER_KEY = 'user_id';

=cut

package OpenFrame::WebApp::Segment::User::RequestLoader;

use strict;
use warnings::register;

our $VERSION = (split(/ /, '$Revision: 1.1 $'))[1];

use base qw( OpenFrame::WebApp::Segment::User::Loader );

our $USER_KEY = 'user_id';

sub find_user_id {
    my $self = shift;
    return $self->look_in_request;
}

sub look_in_request {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $args    = $request->arguments || return;
    return $args->{$USER_KEY};
}


1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Segment::User::RequestLoader> class is a user loader
that gets user id's from the C<OpenFrame::Request> object in store.  It
inherits its interface from C<OpenFrame::WebApp::Segment::User::Loader>.

=head1 METHODS

=over 4

=item $id = $obj->find_user_id()

finds user id.

=item $id = $obj->look_in_request()

gets user id from C<OpenFrame::Request> argument named $USER_KEY.

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::User>,
L<OpenFrame::WebApp::User::Factory>
L<OpenFrame::WebApp::Segment::User::Loader>

=cut
