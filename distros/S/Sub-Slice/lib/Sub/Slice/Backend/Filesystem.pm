###############################################################################
# Purpose : Filesystem (default) backend for Sub::Slice
# Author  : John Alden
# Created : Nov 2004
# CVS     : $Header: /home/cvs/software/cvsroot/sub_slice/lib/Sub/Slice/Backend/Filesystem.pm,v 1.13 2005/01/12 16:51:19 simonf Exp $
###############################################################################

package Sub::Slice::Backend::Filesystem;

use strict;
use Storable();
use File::Spec::Functions;
use File::Path;
use File::Temp;
use Carp;

use constant JOBFILE_PREFIX => 'Sub__Slice__';
use constant MASK_LENGTH => 12;
use constant TOKEN_DB => 'sub_slice_job.store';

use vars qw($VERSION);
$VERSION = sprintf"%d.%03d", q$Revision: 1.13 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my($class, $options) = @_;
	
	# Use a subdir within the temp directory by default, so cleanup
	# can walk the tree beneath it rather than having to match
	# everything in the temp dir against a mask
	my $path = $class->default_path($options->{path});
	File::Path::mkpath($path) unless (-d $path);
	
	my $self = {
		path => $path,
		prefix => $options->{prefix} || JOBFILE_PREFIX,
		storable_filename => $options->{job_filename} || TOKEN_DB,
		mask_length => $options->{unique_key_length} || MASK_LENGTH,
		lax => $options->{lax}
	};
	return bless($self, $class);
}

# Given a path (for our temp dir), do any required canonicalization
# eg. make sure there is always a trailing /.
# Use a default path if one is not specified.
sub default_path { 
	my ($class, $path) = @_;
	$path = $path || File::Spec::Functions::tmpdir()."/sub_slice";
	$path =~ s!([^/])$!$1/!; # add a trailing slash
	$path;
}

sub new_id {
	my ($self) = @_;
	my $mask = "X" x $self->{mask_length};
	my ($dir) = File::Temp::mkdtemp($self->{path} . $self->{prefix} . $mask);
	my $id = scalar File::Spec::Functions::splitpath( $dir );
	TRACE("Created new ID: $id");
	return $id;
}

sub load_job {
	my ($self, $id) = @_;
	my $filename = $self->_db_from_id( $self->_check_id($id) );
	TRACE("loading job '$id' from '$filename'");
	return Storable::retrieve( $filename );
}

sub save_job {
	my ($self, $job) = @_;
	croak("job should be a Sub::Slice object") unless(UNIVERSAL::isa($job, 'Sub::Slice'));
	my $filename = $self->_db_from_id( $job->id );
	my $job_id = $job->id;
	TRACE("saving job '$job_id' to '$filename' ($$)");
	TRACE("job_file for '$job_id' already exists and will be overwritten") if (-e $filename);
	Storable::store( $job, $filename );
}

sub delete_job {
	my ($self, $id) = @_;
	my $dir = $self->_dir_from_id( $self->_check_id($id) );
	die("Job $id does not exist") unless(-d $dir);
	TRACE("deleting directory $dir");
	rmtree $dir;
}

sub store {
	my ($self, $job, $key, $value) = @_;
	$job->{'data'}{$key} = $value;
}

sub fetch {
	my ($self, $job, $key) = @_;
	return $job->{'data'}{$key};
}

sub store_blob {
	my ($self, $job, $key, $value) = @_;
	croak("job should be a Sub::Slice object") unless(UNIVERSAL::isa($job, 'Sub::Slice'));
	croak("you must supply a key to store the blob against") unless(defined $key);
	if (my $data_file = $job->{'.blobs'}{$key}) {
		TRACE("Updating blob for $key in $data_file");
		_write_file($data_file, $value);
	} else {
		my $dir = $self->_dir_from_id( $job->id );
		my ($fh, $data_file) = File::Temp::tempfile(DIR => $dir, UNLINK => 0);
		TRACE("Writing blob for $key in $data_file");
		print $fh $value;
		close $fh;
		$job->{'.blobs'}{$key} = $data_file;
	}
	return 1;
}

sub fetch_blob {
	my ($self, $job, $key) = @_;
	croak("job should be a Sub::Slice object") unless(UNIVERSAL::isa($job, 'Sub::Slice'));
	croak("you must supply a key to fetch the blob") unless(defined $key);
	if (my $data_file = $job->{'.blobs'}{$key}) {
		TRACE("Fetching blob for $key from $data_file");
		return _read_file($data_file);
	}
}

sub cleanup {
	my ($self, $maxage) = @_;
	$maxage = 1 if !defined $maxage;
	local $^T = time();
	my $deleted = 0;
	my $cleaner = sub {
		return if /^\.{1,2}$/;
		my $mtime = -M $_;
		TRACE("file $_ mtime $mtime");

		# it may have *just* disappeared
		return unless defined $mtime;

		# only want to clean up if it's old.
		return unless $mtime >= $maxage;
		$deleted++;
		if (-f $_)    { unlink $_ || die "can't delete $_: $!" }
		elsif (-d $_) { rmdir  $_ || die "can't rmdir $_: $!"  }
		else { $deleted-- };
	};
	my $p = $self->{path};
	return if (!-d $p);
	require File::Find;
	TRACE ("Cleaning up ".$p);
	File::Find::finddepth ($cleaner, $self->{path});
	$deleted;
}

#
# Private functions encapsulating:
# - creating the dir from an ID
# - creating the storable db filename from an ID
# - file IO for blob data
#

sub _dir_from_id {
	my($self, $id) = @_;
	return File::Spec::Functions::catfile($self->{path}, $id);	
}

sub _db_from_id {
	my($self, $id) = @_;
	return File::Spec::Functions::catfile($self->{path}, $id, $self->{storable_filename});	
}

sub _check_id {
	my($self, $id) = @_;
	confess("Called without an id") unless(defined $id);
	unless($self->{lax}) {
		my $regex = quotemeta($self->{prefix}) . ('\w' x $self->{mask_length});
		confess("Format of ID '$id' is invalid") unless($id =~ /\A$regex\Z/);
	}
	return $id;
}

sub _read_file {
	my $filename = shift;
	open (FH, $filename) || die("unable to open $filename - $!");
	local $/ = undef;
	my $data = <FH>;
	close FH;
	return $data;
}

sub _write_file {
	my ($filename, $data) = @_;
	local *FH;
	open(FH, ">$filename") or die("Unable to open $filename - $!");
	binmode FH;
	print FH $data;
	close FH;
}


#Log::Trace stubs
sub TRACE{}
sub DUMP{}

1;

=head1 NAME

Sub::Slice::Backend::Filesystem - Default backend for Sub::Slice

=head1 SYNOPSIS

See L<Sub::Slice::Backend>.

=head1 DESCRIPTION

Implementation of the Sub::Slice::Backend API using Filesystem & Storable.
See L<Sub::Slice> and L<Sub::Slice::Backend> for more information.

Data is stored in one directory per job corresponding to the unique job ID.  
Within this directory there is a single storable file containing the job data and possibly other uniquely-named files
containing BLOB data.  The mapping of key to unique filename for BLOBs is stored within the job.

=head1 STORAGE OPTIONS

=over 4

=item path

The directory in which Sub::Slice tokens are stored.  Default is File::Spec::Functions::tmpdir()."/sub_slice". Sub::Slice will create that directory if it
does not exist already.

NB. Beware of running Sub::Slice under multiple users using the default 
path. Unless you are careful with umask settings, you may create a 
directory that only some Sub::Slice users can write to.

=item prefix

Prefix for all IDs generated by the module.  Default is "Sub__Slice__".

=item unique_key_length

Length of the unique part of the key.  Default is 12 characters.

=item job_filename

Filename containing the job data.  The default is "sub_slice_job.store".

=item lax

Relaxes the check that enforces that job ids match the prefix and unique key length specified in the constructor.
This normally prevents you loading a valid Sub::Slice token from another application if 2 applications 
share the same $path but use a different prefix.

=back

=head1 TODO

=over 4

=item locking functionality 

This may be added in a future version and should default to something reasonably safe (ie. only one process should be able to work on a job at any point in time)

=back
			
=head1 VERSION

$Revision: 1.13 $ on $Date: 2005/01/12 16:51:19 $ by $Author: simonf $

=head1 AUTHOR

John Alden and Simon Flack <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut

