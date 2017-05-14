# -*- perl -*-

# Net::FTPServer A Perl FTP Server
# Copyright (C) 2000 Bibliotech Ltd., Unit 2-3, 50 Carnwath Road,
# London, SW6 3EG, United Kingdom.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=pod

=head1 NAME

Net::FTPServer::Full::Server - The full FTP server personality

=head1 SYNOPSIS

  ftpd.sh [-d] [-v] [-p port] [-s] [-S] [-V] [-C conf_file]

=head1 DESCRIPTION

C<Net::FTPServer::Full::Server> is the full FTP server
personality. This personality implements a complete
FTP server with similar functionality to I<wu-ftpd>.

=head1 METHODS

=cut

package Net::FTPServer::Full::Server;

use strict;

# Authen::PAM is an optional module.
BEGIN { eval "use Authen::PAM;"; }

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Net::FTPServer;
use Net::FTPServer::Full::FileHandle;
use Net::FTPServer::Full::DirHandle;

use vars qw(@ISA);
@ISA = qw(Net::FTPServer);

=pod

=over 4

=item $rv = $self->authentication_hook ($user, $pass, $user_is_anon)

Perform login against C</etc/passwd>, the PAM database or the
C<password file>.

=cut

sub authentication_hook
  {
    my $self = shift;
    my $user = shift;
    my $pass = shift;
    my $user_is_anon = shift;

    # Allow anonymous users. By this point we have already checked
    # that allow anonymous is true in the configuration file.
    return 0 if $user_is_anon;

    if ($self->config ("password file"))
      {
	return -1 if $self->_password_file ($user, $pass) < 0;
      }
    elsif (! $self->config ("pam authentication"))
      {
	# Verify user information against the password file.
	my $hashed_pass = (getpwnam $user)[1] or return -1;

	# Check password.
	return -1 if crypt ($pass, $hashed_pass) ne $hashed_pass;
      }
    else
      {
	return -1 if $self->_pam_check_password ($user, $pass) < 0;
      }

    # Successful login.
    return 0;
  }

sub _password_file
  {
    my $self = shift;
    my $user = shift;
    my $pass = shift;

    my $pw_file = $self->config ("password file");

    # Open the password file and parse it.
    open PW_FILE, "<$pw_file"
      or die "Administrator configured a password file, but ",
	     "the file is missing or cannot be opened. The error was:\n",
	     "$pw_file: $!";
    while (<PW_FILE>)
      {
	s/[\n\r]+$//;
	next if /^\s*\#/ || /^\s*$/;

	# Untaint lines from the password file, since we trust it
	# unconditionally. Admin's fault if they make this file
	# world writable or something :-)
	/(.*)/; $_ = $1;

	my ($pw_username, $pw_crypted_pw, $unix_user, $root_directory)
	  = split /:/, $_;

	if ($user eq $pw_username &&
	    $pw_crypted_pw eq crypt ($pass, $pw_crypted_pw))
	  {
	    close PW_FILE;

	    # Successful login. Remember the real Unix user, which
	    # we will substitute below.
	    $self->{full_unix_user} = $unix_user;
	    $self->{full_root_directory} = $root_directory
	      if defined $root_directory;

	    return 0;
	  }
      }
    close PW_FILE;

    # Failed.
    return -1;
  }

sub _pam_check_password
  {
    my $self = shift;
    my $user = shift;
    my $pass = shift;

    # Give a nice error message in the logs if PAM is not available.
    unless (exists $INC{"Authen/PAM.pm"})
      {
	die
	  "Authen::PAM module is not available, yet PAM authentication ",
	  "was requested in the configuration file. You will not be able ",
	  "to log in to this server. Fetch and install Authen::PAM from ",
	  "CPAN."
      }

    # As noted in the source to wu-ftpd, this is something
    # of an abuse of the PAM protocol. However the FTP protocol
    # gives us little choice in the matter.

    eval
      {
	no strict;		# Otherwise Perl complains about barewords.

	my $pam_conv_func = sub
	  {
	    my @res;

	    while (@_)
	      {
		my $msg_type = shift;
		my $msg = shift;

		if ($msg_type == PAM_PROMPT_ECHO_ON)
		  {
		    return ( PAM_CONV_ERR );
		  }
		elsif ($msg_type == PAM_PROMPT_ECHO_OFF)
		  {
		    push @res, PAM_SUCCESS;
		    push @res, $pass;
		  }
		elsif ($msg_type == PAM_TEXT_INFO)
		  {
		    push @res, PAM_SUCCESS;
		    push @res, "";
		  }
		elsif ($msg_type == PAM_ERROR_MSG)
		  {
		    push @res, PAM_SUCCESS;
		    push @res, "";
		  }
		else
		  {
		    return ( PAM_CONV_ERR );
		  }
	      }

	    push @res, PAM_SUCCESS;
	    return @res;
	  };

	my $pam_appl = $self->config ("pam application name") || "ftp";
	my $pamh = Authen::PAM->new ($pam_appl, $user, $pam_conv_func);

	ref ($pamh) || die "PAM error: pam_start: $pamh";

	$pamh->pam_set_item (PAM_RHOST, $self->{peeraddrstring})
	  == PAM_SUCCESS
	    or die "PAM error: pam_set_item";

	$pamh->pam_authenticate (0) == PAM_SUCCESS
	  or die "PAM error: pam_authenticate";

	$pamh->pam_acct_mgmt (0) == PAM_SUCCESS
	  or die "PAM error: pam_acct_mgmt";

	$pamh->pam_setcred (PAM_ESTABLISH_CRED) == PAM_SUCCESS
	  or die "PAM error: pam_setcred";
      }; # eval

    if ($@)
      {
	$self->log ("info", "PAM authentication error: $@");
	return -1;
      }

    return 0;
  }

=pod

=item $self->user_login_hook ($user, $user_is_anon)

Hook: Called just after user C<$user> has successfully logged in.

=cut

sub user_login_hook
  {
    my $self = shift;
    my $user = shift;
    my $user_is_anon = shift;

    my ($login, $pass, $uid, $gid, $quota, $comment, $gecos, $homedir);

    # For non-anonymous users, just get the uid/gid.
    if (! $user_is_anon)
      {
	# Saved real Unix user (from the "password file" option)?
	$user = $self->{full_unix_user} if exists $self->{full_unix_user};

	($login, $pass, $uid, $gid) = getpwnam $user
	  or die "no user $user in password file";

	# Chroot for this non-anonymous user? If using the "password file"
	# option then we might have saved a root directory above.
	my $root_directory =
	  exists $self->{full_root_directory} ?
	         $self->{full_root_directory} :
		 $self->config ("root directory");

	if (defined $root_directory)
	  {
	    $root_directory =~ s/%m/(getpwnam $user)[7]/ge;
	    $root_directory =~ s/%U/$user/ge;
	    $root_directory =~ s/%%/%/g;

	    if ($< == 0)
	      {
		chroot $root_directory
		  or die "cannot chroot: $root_directory: $!";
	      }
	    else
	      {
		chroot $root_directory
		  or die "cannot chroot: $root_directory: $!"
		    . " (you need root privilege to use chroot feature)";
	      }
	  }
      }
    # For anonymous users, chroot to ftp directory.
    else
      {
	($login, $pass, $uid, $gid, $quota, $comment, $gecos, $homedir)
	  = getpwnam "ftp"
	    or die "no ftp user in password file";

	if ($< == 0)
	  {
	    chroot $homedir or die "cannot chroot: $homedir: $!";
	  }
	else
	  {
	    chroot $homedir or die "cannot chroot: $homedir: $!"
	      . " (you need root privilege to use chroot feature)";
	  }
      }

    # We don't allow users to relogin, so completely change to
    # the user specified.
    $self->_drop_privs ($uid, $gid, $login);
  }

=pod

=item $dirh = $self->root_directory_hook;

Hook: Return an instance of Net::FTPServer::FullDirHandle
corresponding to the root directory.

=cut

sub root_directory_hook
  {
    my $self = shift;

    return new Net::FTPServer::Full::DirHandle ($self);
  }

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2000 Biblio@Tech Ltd., Unit 2-3, 50 Carnwath Road,
London, SW6 3EG, UK

=head1 SEE ALSO

C<Net::FTPServer(3)>,
C<Authen::PAM(3)>,
C<Net::FTP(3)>,
C<perl(1)>,
RFC 765,
RFC 959,
RFC 1579,
RFC 2389,
RFC 2428,
RFC 2577,
RFC 2640,
Extensions to FTP Internet Draft draft-ietf-ftpext-mlst-NN.txt.

=cut
