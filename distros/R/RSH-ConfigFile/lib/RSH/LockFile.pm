# ------------------------------------------------------------------------------
#  Copyright © 2003 by Matt Luker.  All rights reserved.
# 
#  Revision:
# 
#  $Header$
# 
# ------------------------------------------------------------------------------

# LockFile.pm - implements locking via a lock file (NFS safe).
# 
# @author  Matt Luker
# @version $Revision: 3248 $

# LockFile.pm - implements locking via a lock file (NFS safe).
# 
# Copyright (C) 2003, Matt Luker
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. 

# If you have any questions about this software,
# or need to report a bug, please contact me.
# 
# Matt Luker
# Port Angeles, WA
# kostya@redstarhackers.com
# 
# TTGOG

package RSH::LockFile;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw(
					);

our @EXPORT = qw(
	
);

use RSH::FileUtil qw(get_filehandle);
use RSH::Exception;
use Net::Domain qw(hostname hostfqdn hostdomain);

# We don't want to call hostfqdn a ton of times.  The machine name shouldn't change much
# (if at all).  Using an "our" variable should do the trick.  That way it is
# initialized once per machine/script.
our $FQDN = hostfqdn; 

# ******************** PUBLIC Class Methods ********************

# remove_lock
#
# Maintenance method to remove stale locks.  In theory, you should rarely, if ever,
# call this method.  If you call this method a lot, you have a bug or a logic problem.
# Lock files should not be left lying around.
#
sub remove_lock {
	my $filename = shift;

	if (not defined($filename)) { return 0; }

	# Otherwise ...
	my $lock_file = "$filename.lock";
	if (-e $lock_file) {
		my $rc = unlink($lock_file);
		return ($rc != 0);
	} 
	else { return 1; }
}


# ******************** CONSTRUCTOR Methods ********************	

sub new {
	my $class = shift;
	my $filename = shift;
	my %args = @_;
	
	if (not defined($filename)) { die "Cannot create lock file without filename." }

	# Otherwise ...
	my $self = {};

	$self->{filename} = $filename;
    if (defined($args{net_fs_safe}) and ($args{net_fs_safe} eq '1')) {
        $self->{net_fs_safe} = 1;
    }
    else {
        $self->{net_fs_safe} = 0;
    }
	$self->{locked} = 0;
	
	bless $self, $class;

	return $self;
}

# ******************** PUBLIC Instance Methods ********************

# ******************** Accessor Methods ********************

# filename
#
# Read-only accessor for filename attribute.
#
sub filename {
	my $self = shift;

	return $self->{filename};
}

# filename
#
# Read-only accessor for filename attribute.
#
sub lock_filename {
	my $self = shift;

	return $self->{filename}  .".lock";
}

# locked
#
# Read-only accessor for locked flag.
#
sub locked {
	my $self = shift;

	return $self->{locked};
}

# ******************** Function Methods ********************

# lock 
#
# Creates a lock file or dies spectacularly.
#
sub lock {
	my $self = shift;
	my %args = @_;

	my $filename = $self->lock_filename;
	$args{exclusive} = 1;
	eval {
		my $fh = get_filehandle($filename, 'WRITE', %args);
#		if (defined($args{no_follow}) && ($args{no_follow} eq '1')) {
#			# Do not follow symlinks--useful for the paranoid in cases of
#			# sensitive data that should not be moved.
#			#
#			# Since a lock file is created in the same directory as the file, this
#			# would immediately flag a problem where the config file's location 
#			# has been dupped via a symlink to some bogus data somewhere else.
#			eval {
#				$fh = new FileHandle $filename, O_CREAT | O_EXCL | O_NOFOLLOW | O_RDWR;
#			};
#			if ($@) {
#				# catches O_NOFOLLOW not being defined--i.e. on filesystems that have
#				# no concept of symlinks or following.  Paranoid or not, if it isn't
#				# supported we have to just make do
#				$fh = new FileHandle $filename, O_CREAT | O_EXCL |  O_RDWR;
#			}
#		} else {
#			# Just get a file handle and don't worry about whether we are following
#			# symlinks
#			$fh = new FileHandle $filename, O_CREAT | O_EXCL |  O_RDWR;
#		}

		if (not defined($fh)) { die "Unable to create lock file."; }
		if ($self->{net_fs_safe}) {
            print $fh $FQDN, "-", $$;
		}
		else {
            print $fh $$;
		}
        $fh->close;
		$self->{locked} = 1;
	};
	if ($@) { die new RSH::Exception message => $@; }
}

# unlock 
#
# Removes a lock file or dies spectacularly.
#
sub unlock {
	my $self = shift;

	my $filename = $self->{filename} .".lock";

    if (-e $filename) {
        # only try to remove the lock if it is there 
        # TODO should toss a warning?
	    eval {
    		open FH, "<". $filename;

    	   	my $id_val = <FH>;

    		close FH;

            my $id = $$;
            if ($self->{net_fs_safe}) {
                $id = "$FQDN-$$";
            }
            if ($id_val eq $id) { 
                unlink($filename) or die new RSH::Exception message => "Unable to remove lock file for ". $self->filename;
                $self->{locked} = 0;
            } else {
                die new RSH::Exception message => "Do not own lock file for ". $self->filename ."; unlock failed.";
            }
    	};
    	if ($@) { die new RSH::Exception message => $@; }
	}
	
	# you get here and it is unlocked ...
	$self->{locked} = 1;
}


# #################### LockFile.pm ENDS ####################
1;

# ------------------------------------------------------------------------------
# 
#  $Log$
#  Revision 1.3  2003/10/22 20:51:02  kostya
#  Removed OS-specifc assumptions or code
#
#  Revision 1.2  2003/10/15 01:07:00  kostya
#  documentation and license updates--everything is Artistic.
#
#  Revision 1.1.1.1  2003/10/13 01:38:04  kostya
#  First import
#
# 
# ------------------------------------------------------------------------------
