=head1 NAME

OpenFrame::WebApp::User - users for OpenFrame-WebApp

=head1 SYNOPSIS

  use OpenFrame::WebApp::User;

  my $user = new OpenFrame::WebApp::User()->id('fred2003');

=cut

package OpenFrame::WebApp::User;

use strict;
use warnings::register;

our $VERSION = (split(/ /, '$Revision: 1.5 $'))[1];

use base qw( OpenFrame::Object );

our $TYPES = { webapp => __PACKAGE__ };

sub types {
    my $self = shift;
    if (@_) {
	$TYPES = shift;
	return $self;
    } else {
	return $TYPES;
    }
}

sub id {
    my $self = shift;
    if (@_) {
	$self->{user_id} = shift;
	return $self;
    } else {
	return $self->{user_id};
    }
}

1;

=head1 DESCRIPTION

The C<OpenFrame::WebApp::User> class implements a I<very> basic user with an
identifier, and nothing more.  This class exists to be sub-classed to suit
your application's needs.

This class was meant to be used with L<OpenFrame::WebApp::User::Factory>.

=head1 METHODS

=over 4

=item $user->id

set/get the user id.  chosen over 'login' and 'name' as these can have other
menaings & actions associated with them.

=back

=head1 SUB-CLASSING

Read through the source of this package and the known sub-classes first.
The minumum you need to do is this:

  use base qw( OpenFrame::WebApp::User );

  OpenFrame::WebApp::User->types->{my_type} = __PACKAGE__;

You must register your user type if you want to use the User::Factory.

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::User::Factory>,
L<OpenFrame::WebApp::Segment::User::Loader>

=cut
