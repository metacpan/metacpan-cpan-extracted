package MogileFS::Client::Fuse::FilePaths;

use strict;
use warnings;
use MRO::Compat;
use mro 'c3';
use threads::shared;
use base qw{MogileFS::Client::Fuse};

Class::C3::initialize();

our $VERSION = '0.05';

use Errno qw{EACCES EEXIST EIO ENOENT};
use MogileFS::Client::FilePaths;
use MogileFS::Client::Fuse::Constants qw{:LEVELS};
use Params::Validate qw{validate_with BOOLEAN SCALAR};

##Instance Methods

#method that will initialize the MogileFS::Client::Fuse::FilePaths object
sub _init {
	my $self = shift;
	my %opt = validate_with(
		'allow_extra' => 1,
		'params' => \@_,
		'spec'   => {
			'filepaths.dircache'          => {'type' => BOOLEAN, 'default' => 1},
			'filepaths.dircache.duration' => {'type' => SCALAR, 'default' => 2},
		},
	);

	#initialize any ancestor classes
	$self = $self->next::method(%opt);

	#initialize this object
	$self->{'dirs'} = shared_clone({});

	#return the initialized object
	return $self;
}

# method that returns a directory listing for the current directory as a HASHREF
sub _listDir {
	my $self = shift;
	my ($path) = @_;
	$path .= '/' if($path !~ m!/$!so);
	my $config = $self->_config;

	#short-circuit if the dir cache is disabled
	return {map {($_->{'name'} => $_)} $self->MogileFS->list($path)} if(!$config->{'filepaths.dircache'});

	#check to see if the specified path is cached
	my $cache = $self->{'dirs'};
	my $dir = $cache->{$path};

	#load the directory listing if the current cached listing is stale
	if(!defined($dir) || $dir->{'expires'} <= time) {
		#fetch and store the files in the dir cache
		$dir = {
			'expires' => time + $config->{'filepaths.dircache.duration'},
			'files' => {
				map {($_->{'name'} => $_)} $self->MogileFS->list($path),
			},
		};
		$cache->{$path} = shared_clone($dir);
	}

	#return the files for the current directory
	return $dir->{'files'};
}

#method that flushes the specified dir from the dir cache
sub _flushDir {
	my $self = shift;
	my ($path, $flushParent) = @_;
	$path .= '/' if($path !~ m!/$!so);
	delete $self->{'dirs'}->{$path};

	#flush the parent directory from the cache as well
	$self->_flushDir($1, 1) if($flushParent && $path =~ m!^(.*/)[^/]*/$!so);

	return;
}

sub _generateAttrs {
	my $self = shift;
	my ($finfo) = @_;

	if(ref($finfo) eq 'HASH') {
		# Cook some permissions since we don't store this information in mogile
		#TODO: how should we set file/dir permissions?
		my $modes = 0444; # read bit
		$modes |= 0222 if(!$self->_config->{'readonly'}); # write bit
		$modes |= 0111 if($finfo->{'is_directory'}); # execute bit
		$modes |= (($finfo->{'is_directory'} ? 0040 : 0100) << 9); # entry type bits

		my $size = $finfo->{'size'} || 0;

		# set some generic attributes
		my $blksize = 1024;
		my $blocks = (($size - 1) / $blksize) + 1;
		my ($atime, $ctime, $mtime);
		$ctime = $mtime = $finfo->{'modified'} || time;
		$atime = time;

		# generate and return the entry attributes
		#TODO: set more sane values for file attributes
		return [
			0,        # device
			0,        # inode
			$modes,   # mode
			1,        # hard links
			0,        # user id
			0,        # group id
			0,        # device identifier (special files)
			$size,    # size (in bytes)
			$atime,   # last access time
			$mtime,   # last modified time
			$ctime,   # inode change time
			$blksize, # block size
			$blocks,  # number of blocks
		];
	}

	return [];
}

#fetch meta-data about the specified file
sub get_file_info($) {
	my $self = shift;
	my ($path) = @_;

	#short-circuit if this is the root directory
	return {
		'name' => '/',
		'is_directory' => 1,
	} if($path eq '/');

	#split the path into the directory and the file
	$path =~ m!^(.*/)([^/]+)$!so;
	my ($dir, $file) = ($1, $2);

	#look up meta-data in the directory containing the specified file
	my $finfo = eval {
		my $files = $self->_listDir($dir);
		return undef if(!(ref($files) eq 'HASH' && exists $files->{$file}));
		return $files->{$file};
	};

	#return the found file info
	return $finfo;
}

#method that will return a MogileFS object
sub MogileFS {
	my $client = $_[0]->_localElem('MogileFS');

	#create and store a new client if one doesn't exist already
	if(!defined $client) {
		my $config = $_[0]->_config;
		$client = MogileFS::Client::FilePaths->new(
			'hosts'  => [@{$config->{'trackers'}}],
			'domain' => $config->{'domain'},
		);
		$_[0]->_localElem('MogileFS', $client);
	}

	#return the MogileFS client
	return $client;
}

##Fuse callbacks

sub fuse_flush {
	my $self = shift;
	my ($path, $file) = @_;

	#does the directory cache need a flush after this file is flushed
	my $needsFlush = eval{$file->writable && $file->dirty};

	#issue actual flush
	my $resp = $self->next::method(@_);

	#flush the directory cache if necessary
	eval {$self->_flushDir($file->path, 1)} if($needsFlush);

	#return the response for the flush
	return $resp;
}

sub fuse_getattr {
	my $self = shift;
	my ($path) = @_;
	$path = $self->sanitize_path($path);

	# short-circuit if the file doesn't exist
	my $finfo = $self->get_file_info($path);
	return -ENOENT() if(!defined $finfo);

	# generate and return the file attributes
	return @{$self->_generateAttrs($finfo)};
}

sub fuse_getdir {
	my $self = shift;
	my ($path) = @_;
	$path = $self->sanitize_path($path);

	#fetch all the files in the specified directory
	my @names = eval {keys %{$self->_listDir($path)}};
	return -EIO() if($@);

	#return this directory listing
	return ('.', '..', @names), 0;
}

sub fuse_mkdir {
	my $self = shift;
	my ($path, $mode) = @_;
	$path = $self->sanitize_path($path);

	# throw an error if read-only is enabled
	return -EACCES() if($self->_config->{'readonly'});

	#create and delete a file to force path vivification
	eval{
		my $file = $path . '/.mkdir_tmp_' . join('', map {chr(int(rand(26)) + 97)} (0..9));
		my $mogc = $self->MogileFS();
		die unless($mogc->new_file($file, $self->_config->{'class'})->close);
		$mogc->delete($file);

		#flush the directory cache
		$self->_flushDir($path, 1);
	};
	if($@) {
		$self->log(ERROR, 'Error creating new directory: ' . $path);
		return -EIO();
	}

	return 0;
}

sub fuse_mknod {
	my $self = shift;
	my ($path) = @_;
	$path = $self->sanitize_path($path);

	# throw an error if read-only is enabled
	return -EACCES() if($self->_config->{'readonly'});

	#issue actual mknod callback
	my $resp = $self->next::method(@_);

	#flush affected entries from the dir cache
	eval {$self->_flushDir($path, 1)};

	#return the actual response
	return $resp;
}

sub fuse_release {
	my $self = shift;
	my ($path, $flags, $file) = @_;

	#does the directory cache need a flush after this file is released
	my $needsFlush = eval{$file->writable && $file->dirty};

	#issue actual release
	my $resp = $self->next::method(@_);

	#flush the directory cache if necessary
	eval {$self->_flushDir($file->path, 1)} if($needsFlush);

	#return the response for the release
	return $resp;
}

sub fuse_rename {
	my $self = shift;
	my ($old, $new) = @_;
	$old = $self->sanitize_path($old);
	$new = $self->sanitize_path($new);

	# throw an error if read-only is enabled
	return -EACCES() if($self->_config->{'readonly'});

	#throw an error if the new file already exists
	return -EEXIST() if(defined $self->get_file_info($new));

	#attempt renaming the specified file
	my $mogc = $self->MogileFS();
	my $response = eval {
		my $resp = $mogc->rename($old, $new);
		if($resp) {
			$self->_flushDir($old, 1);
			$self->_flushDir($new, 1);
		}
		return $resp;
	};
	if($@ || !$response) {
		($?, $!) = (-1, '');
		#set the error code and string if we have a MogileFS::Client object
		if($mogc) {
			$? = $mogc->errcode || -1;
			$! = $mogc->errstr || '';
		}
		$self->log(ERROR, "Error renaming file: $?: $!");
		return -EIO();
	}

	#return success
	return 0;
}

sub fuse_truncate {
	my $self = shift;
	my ($path, $size) = @_;
	$path = $self->sanitize_path($path);

	# throw an error if read-only is enabled
	return -EACCES() if($self->_config->{'readonly'});

	#issue actual truncate callback
	my $resp = $self->next::method(@_);

	#flush affected entries from the dir cache
	eval {$self->_flushDir($path, 1)};

	#return the actual response
	return $resp;
}

sub fuse_unlink {
	my $self = shift;
	my ($path) = @_;
	$path = $self->sanitize_path($path);

	# throw an error if read-only is enabled
	return -EACCES() if($self->_config->{'readonly'});

	#issue actual unlink callback
	my $resp = $self->next::method(@_);

	#flush affected entries from the dir cache
	eval {$self->_flushDir($path, 1)};

	#return the actual response
	return $resp;
}

1;
