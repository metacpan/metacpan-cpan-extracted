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

Net::FTPServer::InMem::DirHandle - Store files in local memory

=head1 SYNOPSIS

  use Net::FTPServer::InMem::DirHandle;

=head1 METHODS

=cut

package Net::FTPServer::InMem::DirHandle;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Carp qw(confess croak);
use IO::Scalar;

use Net::FTPServer::DirHandle;

use vars qw(@ISA);

@ISA = qw(Net::FTPServer::DirHandle);

# Global variables.
use vars qw(%dirs $next_dir_id %files $next_file_id);

# The initial directory structure.
$next_dir_id = 2;
$dirs{1} = { name => "", parent => 0 };
$next_file_id = 1;

# Return a new directory handle.

sub new
  {
    my $class = shift;
    my $ftps = shift;		# FTP server object.
    my $pathname = shift || "/"; # (only used in internal calls)
    my $dir_id = shift;		# (only used in internal calls)

    # Create object.
    my $self = Net::FTPServer::DirHandle->new ($ftps, $pathname);
    bless $self, $class;

    if ($dir_id)
      {
	$self->{fs_dir_id} = $dir_id;
      }
    else
      {
	$self->{fs_dir_id} = 1;
      }

    return $self;
  }

# Return a subdirectory handle or a file handle within this directory.

sub get
  {
    my $self = shift;
    my $filename = shift;

    # None of these cases should ever happen.
    confess "no filename" unless defined($filename) && length($filename);
    confess "slash filename" if $filename =~ /\//;
    confess ".. filename"    if $filename eq "..";
    confess ". filename"     if $filename eq ".";

    # Search for the file first, since files are more common than dirs.
    foreach (keys %files)
      {
	if ($files{$_}{dir_id} == $self->{fs_dir_id} &&
	    $files{$_}{name} eq $filename)
	  {
	    # Found a file.
	    return new Net::FTPServer::InMem::FileHandle ($self->{ftps},
							  $self->pathname . $filename,
							  $self->{fs_dir_id},
							  $_,
							  $files{$_}{content});
	  }
      }

    # Search for a directory.
    foreach (keys %dirs)
      {
	if ($dirs{$_}{parent} == $self->{fs_dir_id} &&
	    $dirs{$_}{name} eq $filename)
	  {
	    # Found a directory.
	    return new Net::FTPServer::InMem::DirHandle ($self->{ftps},
							 $self->pathname . $filename . "/",
							 $_);
	  }
      }

    # Not found.
    return undef;
  }

# Get parent of current directory.

sub parent
  {
    my $self = shift;

    return $self if $self->is_root;

    # Get a new directory handle.
    my $dirh = $self->SUPER::parent;

    # Find directory ID of the parent directory.
    $dirh->{fs_dir_id} = $dirs{$self->{fs_dir_id}}{parent};

    return bless $dirh, ref $self;
  }

sub list
  {
    my $self = shift;
    my $wildcard = shift;

    # Convert wildcard to regular expression.
    if ($wildcard)
      {
	if ($wildcard ne "*")
	  {
	    $wildcard = $self->{ftps}->wildcard_to_regex ($wildcard);
	  }
	else
	  {
	    $wildcard = undef;
	  }
      }

    # Get subdirectories.
    my @dirs;
    if ($wildcard)
      {
	@dirs = grep { $dirs{$_}{parent} == $self->{fs_dir_id} &&
		       $dirs{$_}{name} =~ /$wildcard/ } keys %dirs;
      }
    else
      {
	@dirs = grep { $dirs{$_}{parent} == $self->{fs_dir_id} } keys %dirs;
      }

    my @result = ();
    my $username = substr $self->{ftps}{user}, 0, 8;

    foreach (@dirs)
      {
	my $dirh
	  = new Net::FTPServer::InMem::DirHandle ($self->{ftps},
						  $self->pathname . $dirs{$_}{name} . "/",
						  $_);

	push @result, [ $dirs{$_}{name}, $dirh ];
      }

    # Get files.
    my @files;
    if ($wildcard)
      {
	@files = grep { $files{$_}{dir_id} == $self->{fs_dir_id} &&
			$files{$_}{name} =~ /$wildcard/ } keys %files;
      }
    else
      {
	@files = grep { $files{$_}{dir_id} == $self->{fs_dir_id} } keys %files;
      }

    foreach (@files)
      {
	my $fileh
	  = new Net::FTPServer::InMem::FileHandle ($self->{ftps},
						   $self->pathname . $files{$_}{name},
						   $self->{fs_dir_id},
						   $_,
						   $files{$_}{content});

	push @result, [ $files{$_}{name}, $fileh ];
      }

    return \@result;
  }

sub list_status
  {
    my $self = shift;
    my $wildcard = shift;

    # Convert wildcard to regular expression.
    if ($wildcard)
      {
	if ($wildcard ne "*")
	  {
	    $wildcard = $self->{ftps}->wildcard_to_regex ($wildcard);
	  }
	else
	  {
	    $wildcard = undef;
	  }
      }

    # Get subdirectories.
    my @dirs;
    if ($wildcard)
      {
	@dirs = grep { $dirs{$_}{parent} == $self->{fs_dir_id} &&
		       $dirs{$_}{name} =~ /$wildcard/ } keys %dirs;
      }
    else
      {
	@dirs = grep { $dirs{$_}{parent} == $self->{fs_dir_id} } keys %dirs;
      }

    my @result = ();
    my $username = substr $self->{ftps}{user}, 0, 8;

    foreach (@dirs)
      {
	my $dirh
	  = new Net::FTPServer::InMem::DirHandle ($self->{ftps},
						  $self->pathname . $dirs{$_}{name} . "/",
						  $_);

	my @status = $dirh->status;
	push @result, [ $dirs{$_}{name}, $dirh, \@status ];
      }

    # Get files.
    my @files;
    if ($wildcard)
      {
	@files = grep { $files{$_}{dir_id} == $self->{fs_dir_id} &&
			$files{$_}{name} =~ /$wildcard/ } keys %files;
      }
    else
      {
	@files = grep { $files{$_}{dir_id} == $self->{fs_dir_id} } keys %files;
      }

    foreach (@files)
      {
	my $fileh
	  = new Net::FTPServer::InMem::FileHandle ($self->{ftps},
						   $self->pathname . $files{$_}{name},
						   $self->{fs_dir_id},
						   $_,
						   $files{$_}{content});

	my @status = $fileh->status;
	push @result, [ $files{$_}{name}, $fileh, \@status ];
      }

    return \@result;
  }

# Return the status of this directory.

sub status
  {
    my $self = shift;
    my $username = substr $self->{ftps}{user}, 0, 8;

    return ( 'd', 0755, 1, $username, "users", 1024, 0 );
  }

# Move a directory to elsewhere.

sub move
  {
    my $self = shift;
    my $dirh = shift;
    my $filename = shift;

    # You can't move the root directory. That would be bad :-)
    return -1 if $self->is_root;

    $dirs{$self->{fs_dir_id}}{parent} = $dirh->{fs_dir_id};
    $dirs{$self->{fs_dir_id}}{name} = $filename;

    return 0;
  }

sub delete
  {
    my $self = shift;

    delete $dirs{$self->{fs_dir_id}};

    return 0;
  }

# Create a subdirectory.

sub mkdir
  {
    my $self = shift;
    my $dirname = shift;

    $dirs{$next_dir_id++} = { name => $dirname, parent => $self->{fs_dir_id} };

    return 0;
  }

# Open or create a file in this directory.

sub open
  {
    my $self = shift;
    my $filename = shift;
    my $mode = shift;

    if ($mode eq "r")		# Open an existing file for reading.
      {
	foreach (keys %files)
	  {
	    if ($files{$_}{dir_id} == $self->{fs_dir_id} &&
		$files{$_}{name} eq $filename)
	      {
		return new IO::Scalar ($files{$_}{content});
	      }
	  }

	return undef;
      }
    elsif ($mode eq "w")	# Create/overwrite the file.
      {
	# If a file with the same name exists already, erase it.
	foreach (keys %files)
	  {
	    if ($files{$_}{dir_id} == $self->{fs_dir_id} &&
		$files{$_}{name} eq $filename)
	      {
		delete $files{$_};
		last;
	      }
	  }

	my $content = "";

	$files{$next_file_id++} = { dir_id => $self->{fs_dir_id},
				    name => $filename,
				    content => \$content };

	return new IO::Scalar (\$content);
      }
    elsif ($mode eq "a")	# Append to the file.
      {
	foreach (keys %files)
	  {
	    if ($files{$_}{dir_id} == $self->{fs_dir_id} &&
		$files{$_}{name} eq $filename)
	      {
		return new IO::Scalar ($files{$_}{content});
	      }
	  }

	return undef;
      }
    else
      {
	croak "unknown file mode: $mode; use 'r', 'w' or 'a' instead";
      }
  }

1 # So that the require or use succeeds.

__END__

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2000 Biblio@Tech Ltd., Unit 2-3, 50 Carnwath Road,
London, SW6 3EG, UK

=head1 SEE ALSO

C<Net::FTPServer(3)>, C<perl(1)>

=cut
