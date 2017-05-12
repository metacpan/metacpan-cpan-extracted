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

# $Id: Server.pm,v 1.1 2003/09/28 11:50:45 rwmj Exp $

=pod

=head1 NAME

Net::FTPServer::DBeg1::Server - The DB example FTP server personality

=head1 SYNOPSIS

  dbeg1-ftpd [-d] [-v] [-p port] [-s] [-S] [-V] [-C conf_file]

=head1 DESCRIPTION

C<Net::FTPServer::DBeg1::Server> is the example DB-based FTP server
personality. This personality implements a simple
FTP server with a PostgreSQL database back-end.

=head1 METHODS

=over 4

=cut

package Net::FTPServer::DBeg1::Server;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

use DBI;

use Net::FTPServer;
use Net::FTPServer::DBeg1::FileHandle;
use Net::FTPServer::DBeg1::DirHandle;

use vars qw(@ISA);
@ISA = qw(Net::FTPServer);

# Cached statement handles.
use vars qw($sth1 $sth2 $sth3);

# This is called before configuration.

sub pre_configuration_hook
  {
    my $self = shift;

    $self->{version_string} .= " Net::FTPServer::DBeg1/$VERSION";

    # Custom SITE commands.
    $self->{site_command_table}{USAGE} = \&_SITE_USAGE_command;
  }

# This is called just after accepting a new connection. We connect
# to the database here.

sub post_accept_hook
  {
    my $self = shift;

    # Connect to the database.
    my $dbh = DBI->connect ("dbi:Pg(RaiseError=>1,AutoCommit=>0):dbname=ftp",
			    "", "")
      or die "cannot connect to database: ftp: $!";

    # Store the database handle.
    $self->{fs_dbh} = $dbh;
  }

# This is called after executing every command. It commits the transaction
# into the database.

sub post_command_hook
  {
    my $self = shift;

    $self->{fs_dbh}->commit;
  }

# Perform login against the database.

sub authentication_hook
  {
    my $self = shift;
    my $user = shift;
    my $pass = shift;
    my $user_is_anon = shift;

    # Disallow anonymous access.
    return -1 if $user_is_anon;

    # Verify access against the database.
    my $sql = "select password from users where username = ?";
    $sth1 ||= $self->{fs_dbh}->prepare ($sql);
    $sth1->execute ($user);

    my $row = $sth1->fetch or return -1; # No such user.

    # Check password.
    my $hashed_pass = $row->[0];
    return -1 unless crypt ($pass, $hashed_pass) eq $hashed_pass;

    # Successful login.
    return 0;
  }

# Called just after user C<$user> has successfully logged in.

sub user_login_hook
  {
    # Do nothing for now, but in future it would be a good
    # idea to change uid or chroot to a safe place.
  }

#  Return an instance of Net::FTPServer::DBeg1::DirHandle
# corresponding to the root directory.

sub root_directory_hook
  {
    my $self = shift;

    return new Net::FTPServer::DBeg1::DirHandle ($self);
  }

# The SITE USAGE command.

sub _SITE_USAGE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Count the number of files and directories used.
    my $sql = "select count(id) from files";
    $sth2 ||= $self->{fs_dbh}->prepare ($sql);
    $sth2->execute;

    my $row = $sth2->fetch or die "no rows returned from count";

    my $nr_files = $row->[0];

    $sql = "select count(id) from directories";
    $sth3 ||= $self->{fs_dbh}->prepare ($sql);
    $sth3->execute;

    $row = $sth3->fetch or die "no rows returned from count";

    my $nr_dirs = $row->[0];

    $self->reply (200,
		  "There are $nr_files files and $nr_dirs directories.");
  }

1 # So that the require or use succeeds.

__END__

=back 4

=head1 FILES

  /etc/ftpd.conf
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/DirHandle.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/FileHandle.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/Handle.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/DBeg1/Server.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/DBeg1/DirHandle.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/DBeg1/FileHandle.pm

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2000 Biblio@Tech Ltd., Unit 2-3, 50 Carnwath Road,
London, SW6 3EG, UK

=head1 SEE ALSO

L<Net::FTPServer(3)>,
L<Net::FTP(3)>,
L<perl(1)>,
RFC 765,
RFC 959,
RFC 1579,
RFC 2389,
RFC 2428,
RFC 2577,
RFC 2640,
Extensions to FTP Internet Draft draft-ietf-ftpext-mlst-NN.txt.

=cut
