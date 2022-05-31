use strict;
use warnings;
package Rubric::WebApp::Login::HTTP 0.157;
# ABSTRACT: process web login from HTTP authentication

use parent qw(Rubric::WebApp::Login);

#pod =head1 DESCRIPTION
#pod
#pod This module checks for information needed to confirm that a user is logged into
#pod the Rubric.
#pod
#pod =head1 METHODS
#pod
#pod =head2 get_login_username
#pod
#pod This method returns the REMOTE_USER environment variable.
#pod
#pod =cut

sub get_login_username { $ENV{REMOTE_USER} }

#pod =head2 authenticate_login
#pod
#pod This method always returns true.  (The assumption, here, is that the HTTP
#pod server has already taken care of authentication.)
#pod
#pod =cut

sub authenticate_login { 1 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::WebApp::Login::HTTP - process web login from HTTP authentication

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

=head2 get_login_username

This method returns the REMOTE_USER environment variable.

=head2 authenticate_login

This method always returns true.  (The assumption, here, is that the HTTP
server has already taken care of authentication.)

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
