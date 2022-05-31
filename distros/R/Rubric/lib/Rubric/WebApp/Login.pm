use strict;
use warnings;
package Rubric::WebApp::Login 0.157;
# ABSTRACT: web login processing

#pod =head1 DESCRIPTION
#pod
#pod This module checks for information needed to confirm that a user is logged into
#pod the Rubric.
#pod
#pod =head1 METHODS
#pod
#pod =head2 Rubric::WebApp::Login->check_for_login($webapp)
#pod
#pod This method is called by the WebApp's C<cgiapp_init>, and checks for a login
#pod attempt in the submitted request.  
#pod
#pod It looks for a login username by calling C<get_login_username>, then converts
#pod the login name to a Rubric name by calling C<map_username> and returns
#pod immediately if the name can't be shown valid by calling C<valid_username>.
#pod
#pod It retrieves the User object by calling C<get_login_user> or, if needed,
#pod C<autocreate_user>, and returns if it can't get a User object.  It tries to
#pod authenticate by calling C<authenticate_login>.  If the user is authorized but
#pod isn't verified, he won't be logged in and the C<user_pending> parameter will be
#pod set on the Rubric::WebApp object.  Otherwise, he will be logged in with
#pod C<set_current_user>.
#pod
#pod Most of the methods above are virtual methods in this class, and should be
#pod implemented in subclasses.  The bundled L<Rubric::WebApp::Login::Post> (the
#pod default) and L<Rubric::WebApp::Login::HTTP> serve as examples.
#pod
#pod =cut

sub check_for_login {
	my ($self, $webapp) = @_;

	return unless my $username = $self->get_login_username($webapp);

	$username = $self->map_username($username);
	return unless $self->valid_username($username);
	return unless my $user =
		$self->get_login_user($username) || $self->autocreate_user($username);
	return unless $self->authenticate_login($webapp, $user);
	if ($user->verification_code) {
		$webapp->param('user_pending', 1);
	} else {
		$self->set_current_user($webapp, $user);
	}
}

#pod =head2 get_login_username($webapp)
#pod
#pod This method returns the login username taken from the request.  It is not
#pod necessarily the name of a Rubric user (see C<map_username>).
#pod
#pod This must be implemented by the login subclass.
#pod
#pod =cut

sub get_login_username { die "get_login_username unimplemented" }

#pod =head2 map_username($username)
#pod
#pod This method returns the Rubric username to which the login name maps.  By
#pod default, it returns the C<$username> verbatim.
#pod
#pod =cut

sub map_username { $_[1] }

#pod =head2 valid_username($username)
#pod
#pod Returns a true or false value, depending on whether the given username string
#pod is a valid username.
#pod
#pod =cut

sub valid_username {
	my ($self, $username) = @_;
	$username =~ /^[\pL\d_]+$/;
}

#pod =head2 get_login_user($username)
#pod
#pod Given a username, this method returns the Rubric::User object for the user.
#pod
#pod =cut

sub get_login_user {
	my ($self, $username) = @_;
	Rubric::User->retrieve($username);
}

#pod =head2 autocreate_user($username)
#pod
#pod If C<get_login_user> can't find a user, this method is called to try to create
#pod the user automatically.  By default, it always returns nothing.  It may be
#pod subclassed for implementation.  (For example, one could create domain users
#pod from a directory.)
#pod
#pod =cut

sub autocreate_user { }

#pod =head2 authenticate_login($webapp, $user)
#pod
#pod This method attempts to authenticate the user's login, checking the given
#pod password or performing any other needed check.  It returns true or false.
#pod
#pod This must be implemented by the login subclass.
#pod
#pod =cut

sub authenticate_login { die "authenticate_login unimplemented" }

#pod =head2 set_current_user($webapp, $user)
#pod
#pod This method sets the current user on the WebApp by setting the WebApp's
#pod "current_user" attribute to the Rubric::User object.
#pod
#pod =cut

sub set_current_user {
	my ($self, $webapp, $user) = @_;

	$webapp->param(current_user => $user);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::WebApp::Login - web login processing

=head1 VERSION

version 0.157

=head1 DESCRIPTION

This module checks for information needed to confirm that a user is logged into
the Rubric.

=head1 PERL VERSION

This code is effectively abandonware.  Although releases will sometimes be made
to update contact info or to fix packaging flaws, bug reports will mostly be
ignored.  Feature requests are even more likely to be ignored.  (If someone
takes up maintenance of this code, they will presumably remove this notice.)
This means that whatever version of perl is currently required is unlikely to
change -- but also that it might change at any new maintainer's whim.

=head1 METHODS

=head2 Rubric::WebApp::Login->check_for_login($webapp)

This method is called by the WebApp's C<cgiapp_init>, and checks for a login
attempt in the submitted request.  

It looks for a login username by calling C<get_login_username>, then converts
the login name to a Rubric name by calling C<map_username> and returns
immediately if the name can't be shown valid by calling C<valid_username>.

It retrieves the User object by calling C<get_login_user> or, if needed,
C<autocreate_user>, and returns if it can't get a User object.  It tries to
authenticate by calling C<authenticate_login>.  If the user is authorized but
isn't verified, he won't be logged in and the C<user_pending> parameter will be
set on the Rubric::WebApp object.  Otherwise, he will be logged in with
C<set_current_user>.

Most of the methods above are virtual methods in this class, and should be
implemented in subclasses.  The bundled L<Rubric::WebApp::Login::Post> (the
default) and L<Rubric::WebApp::Login::HTTP> serve as examples.

=head2 get_login_username($webapp)

This method returns the login username taken from the request.  It is not
necessarily the name of a Rubric user (see C<map_username>).

This must be implemented by the login subclass.

=head2 map_username($username)

This method returns the Rubric username to which the login name maps.  By
default, it returns the C<$username> verbatim.

=head2 valid_username($username)

Returns a true or false value, depending on whether the given username string
is a valid username.

=head2 get_login_user($username)

Given a username, this method returns the Rubric::User object for the user.

=head2 autocreate_user($username)

If C<get_login_user> can't find a user, this method is called to try to create
the user automatically.  By default, it always returns nothing.  It may be
subclassed for implementation.  (For example, one could create domain users
from a directory.)

=head2 authenticate_login($webapp, $user)

This method attempts to authenticate the user's login, checking the given
password or performing any other needed check.  It returns true or false.

This must be implemented by the login subclass.

=head2 set_current_user($webapp, $user)

This method sets the current user on the WebApp by setting the WebApp's
"current_user" attribute to the Rubric::User object.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
