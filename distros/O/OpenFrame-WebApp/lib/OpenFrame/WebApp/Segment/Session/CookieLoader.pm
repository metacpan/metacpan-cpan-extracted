=head1 NAME

OpenFrame::WebApp::Segment::Session::CookieLoader - a pipeline segment to load
sessions from cookies

=head1 SYNOPSIS

  # see OpenFrame::WebApp::Segment::Session::Loader

=cut

package OpenFrame::WebApp::Segment::Session::CookieLoader;

use strict;
use warnings::register;

use OpenFrame::Cookie;
use OpenFrame::Cookies;

our $VERSION = (split(/ /, '$Revision: 1.3 $'))[1];

use base qw( OpenFrame::WebApp::Segment::Session::Loader );

our $COOKIE_NAME = 'session';

sub create_saver_segment {
    my $self    = shift;
    my $session = shift;
    $self->create_session_cookie( $session );
    return $self->SUPER::create_saver_segment( $session );
}

sub find_session_id {
    my $self = shift;
    return $self->look_in_ctin;
}

sub look_in_ctin {
    my $self   = shift;
    my $ctin   = $self->store->get('OpenFrame::Cookies') || return;
    my $cookie = $ctin->get( $COOKIE_NAME ) || return;
    return $cookie->value();
}

sub create_session_cookie {
    my $self    = shift;
    my $session = shift;
    my $ctin    = $self->get_or_create_ctin;
    my $cookie  = new OpenFrame::Cookie;

    $cookie->name( $COOKIE_NAME );
    $cookie->value( [ $session->id ] );

    $ctin->set( $cookie );

    return $self;
}

sub get_or_create_ctin {
    my $self = shift;
    my $ctin = $self->store->get('OpenFrame::Cookies');

    unless ($ctin) {
	$ctin = new OpenFrame::Cookies;
	$self->store->set( $ctin );
    }

    return $ctin;
}


1;


__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Segment::Session::CookieLoader> class is a session
loader that uses C<OpenFrame::Cookies>.  It inherits its interface from
C<OpenFrame::WebApp::Segment::Session::Loader>.

You can access the cookie name that it uses like this:

  $OpenFrame::WebApp::Segment::Session::CookieLoader::COOKIE_NAME

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

Based on C<OpenFrame::AppKit::Segment::SessionLoader>, by James A. Duncan

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::Session>,
L<OpenFrame::WebApp::Segment::Session::Loader>

=cut
