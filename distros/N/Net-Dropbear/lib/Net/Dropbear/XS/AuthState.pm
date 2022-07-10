package Net::Dropbear::XS::AuthState;

use strict;
use warnings;

our $VERSION = '0.16';

1;
__END__

=encoding utf-8

=head1 NAME

Net::Dropbear::XS::AuthState - Manage the authentication information of a
user's login attempt.

=head1 DESCRIPTION

This type of object  is created and passed during the on_passwd_fill hook.  See L<Net::Dropbear::SSHd> for details. There is no new method for this object,
it is only created based on the struct from Dropbear.

=head1 ATTRIBUTES

All of these attributes are set to sane defaults. They can be left as-is
or updated to new values.  Note that they should be sane values; the uid and
gid should exist in the system. Otherwise the results will be undefined.

These attributes represent values that are normally read from the passwd file.

=over 

=item pw_uid 

The UID of the user attempting to login.

B<Default:> The current user's UID.

=item pw_gid

The GID of the user attempting to login.

B<Default:> The current user's GID.

=item pw_dir

The user's home directory.

B<Default:> /tmp

=item pw_shell

The login shell of the user. This should be set to a valid shell as defined
by C</etc/shells>. See L<shells(5)>.

B<Default:> The empty string, which is interpreted as C</bin/sh>.

=item pw_name

The name of the user attempting login. Changing this will be seen by later
hooks.

B<Default:> The attempted login username.

=item pw_passwd

The crypted password of the user.  This can be changed to any password that
they system understands. See L<crypt(3)>.

B<Default:> The string "!!", which will indicate a locked account.

=back

=head1 CONSTANTS

=over

=item AUTH_TYPE_NONE

=item AUTH_TYPE_PUBKEY

=item AUTH_TYPE_PASSWORD

=item AUTH_TYPE_INTERACT

=back

=cut
