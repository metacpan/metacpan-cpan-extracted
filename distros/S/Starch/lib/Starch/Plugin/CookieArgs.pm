package Starch::Plugin::CookieArgs;
use 5.008001;
use strictures 2;
our $VERSION = '0.12';

use Moo;
use namespace::clean;

with qw(
    Starch::Plugin::Bundle
);

sub bundled_plugins {
    return [qw(
        ::CookieArgs::Manager
        ::CookieArgs::State
    )];
}

1;
__END__

=head1 NAME

Starch::Plugin::CookieArgs - Arguments and methods for dealing with
HTTP cookies.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::CookieArgs'],
        cookie_name => 'my_session',
        ...,
    );
    my $state = $starch->state();
    my $cookie_args = $state->cookie_args();
    print $cookie_args->{name}; # my_session

=head1 DESCRIPTION

This plugin adds new arguments to the manager class and new methods to
the state class which are intended to ease the integration of Starch
with existing web frameworks.

=head1 OPTIONAL MANAGER ARGUMENTS

These arguments are added to the L<Starch::Manager> class.

A detailed description of what these arguments mean and what
they can contain is in the L<CGI::Simple::Cookie> documentation.

=head2 cookie_name

The name of the session cookie, defaults to C<session>.

=head2 cookie_domain

The domain name to set the cookie to.  Set this to undef, or just don't set
it, to let the browser figure this out.

=head2 cookie_path

The path within the L</cookie_domain> that the cookie should be
applied to.  Set this to undef, or just don't set it, to let the
browser figure it out.

=head2 cookie_secure

Whether the session cookie can only be transmitted over SSL.
This defaults to true, as doing otherwise is a pretty terrible
idea as a user's session cookie could be easily hijacker by
anyone sniffing network packets.

=head2 cookie_http_only

If this is set to true then JavaScript will not have access to the cookie
data, mitigating certain XSS attacks.  This defaults to true as having
JavaScript that needs access to cookies is a rare case and you should
have to explicitly declare that you want to turn this protection off.

=head1 STATE METHODS

These methods are added to the L<Starch::State> class.

=head2 cookie_args

Returns L</cookie_delete_args> if the L<Starch::State/is_deleted>,
otherwise returns L</cookie_set_args>.

These args are meant to be compatible with L<CGI::Simple::Cookie>, minus
the C<-> in front of the argument names, which is the same format that
both Plack and Catalyst accept for cookies.

=head2 cookie_set_args

Returns a hash ref containing all the cookie args including the
value being set to L<Starch::State/id> and the expires being
set to L<Starch::State/expires>.

=head2 cookie_delete_args

This returns the same thing as L</cookie_set_args>, but overrides the
C<expires> value to be one day in the past which will trigger the client
to remove the cookie immediately.

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHORS> and L<Starch/LICENSE>.

=cut

