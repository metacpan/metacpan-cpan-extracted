package MogileFS::Client::Fuse::File;

use strict;
use warnings;
use threads::shared;

our $VERSION = '0.05';

use Errno qw{EIO};
use Fcntl;
use HTTP::Request;
use HTTP::Status qw{HTTP_REQUEST_RANGE_NOT_SATISFIABLE};
use MogileFS::Client::Fuse::Constants qw{:LEVELS};
use Scalar::Util qw{refaddr};

##Static Methods

#Constructor
#	flags => the open flags for this file
#	fuse  => the MogileFS::Client::Fuse object controlling this file
#	path  => the path of this file
sub new {
	#create the new MogileFS::Client::Fuse::File object
	my $self = shift;
	$self = bless(shared_clone({}), ref($self) || $self);

	#initialize and return the new object
	return $self->_init(@_);
}

##Instance Methods

#method that will copy existing data from the old handle to the new handle
sub _cow {
	my $self = shift;
	my ($newPtr, $limit) = @_;

	#sanitize limit
	$limit = $newPtr if(defined $limit && $limit < $newPtr);

	while(defined $self->{'cowPtr'} && $self->{'cowPtr'} < $newPtr) {
		#set the buffer size for the next block being copied, limit it as necessary
		my $bufSize = 1024 * 1024;
		$bufSize = $limit - $self->{'cowPtr'} if(defined($limit) && $self->{'cowPtr'} + $bufSize > $limit);

		#copy a block of data
		my $bytes = $self->_write($self->{'cowPtr'}, $self->_read($self->{'cowPtr'}, $bufSize));
		$self->{'cowPtr'} += $bytes;
		delete $self->{'cowPtr'} if(!$bytes);
	}

	return;
}

sub _flush {
	my $self = shift;

	#commit the output file
	my $dest = $self->getOutputDest();
	my $res = eval {
		my $config = $self->fuse->_config;
		$self->MogileFS->{'backend'}->do_request('create_close', {
			'fid'    => $dest->{'fid'},
			'devid'  => $dest->{'devid'},
			'domain' => $config->{'domain'},
			'size'   => $dest->{'size'},
			'key'    => ($dest->{'error'} ? '' : $self->path),
			'path'   => $dest->{'path'},

			# these attributes are specific to MogileFS::Client::FilePaths which utilizes the MetaData MogileFS plugin
			#TODO: move this into a FilePaths specific file object
			'plugin.meta.keys'   => 1,
			'plugin.meta.key0'   => 'mtime',
			'plugin.meta.value0' => scalar time,
		});
	};
	if($@ || !$res || $dest->{'error'}) {
		$self->fuse->log(ERROR, 'Error flushing file: ' . $self->path);
		die;
	}

	#reinitialize I/O attributes
	$self->_initIo;

	return;
}

sub _fsync {
	return 1;
}

#method to initialize this file object
sub _init {
	my $self = shift;
	my (%opt) = @_;

	#set all the specified options
	$self->{'flags'} = $opt{'flags'};
	$self->{'fuse'} = $opt{'fuse'};
	$self->{'path'} = $opt{'path'};

	#initialize the I/O attributes
	$self->_initIo;

	# short-circuit if the file is opened for writing and MogileFS is mounted readonly
	return undef if($self->writable && $self->fuse->_config->{'readonly'});

	#short-circuit if the file isn't opened for writing and doesn't exist in MogileFS
	return undef if(!$self->writable && !$self->getPaths());

	#return the initialized object
	return $self;
}

#method that will (re)initialize various I/O related attributes
sub _initIo {
	my $self = shift;

	#delete any existing I/O attributes
	delete $self->{'paths'};
	delete $self->{'dest'};
	delete $self->{'cowPtr'};
	delete $self->{'dirty'};

	#preset a couple values when we are writing a file
	if($self->writable) {
		#a previous version exists
		if($self->getPaths()) {
			#initialize the cow pointer for COW
			$self->{'cowPtr'} = 0;
		}
		#no previous version exists
		else {
			#mark as dirty to guarantee a flush
			$self->_markAsDirty;
		}
	}

	return;
}

sub _markAsDirty {
	$_[0]->{'dirty'} = 1
}

#method to read the requested data directly from a file in MogileFS
#	output => is this read request being performed on an output file instead of an input file
sub _read {
	my $self = shift;
	my ($offset, $len, %opt) = @_;

	#iterate over all paths attempting to read data
	my $ua = $self->fuse->ua;
	my $headers = ['Range' => 'bytes=' . $offset . '-' . ($offset + $len - 1)];
	my $res;
	foreach my $uri ($opt{'output'} ? $self->getOutputDest->{'path'} : $self->getPaths()) {
		#attempt retrieving the requested data
		$res = $ua->send_request(HTTP::Request->new('GET' => $uri, $headers));

		#check for errors
		if($res->is_error) {
			#have we reached the end of this file?
			return undef if($res->code == HTTP_REQUEST_RANGE_NOT_SATISFIABLE);

			#try the next uri
			next;
		}

		#exit the loop
		last;
	}

	#was there an error satisfying this read request?
	if(!$res || $res->is_error) {
		$self->fuse->log(ERROR, 'Error reading data from: ' . $self->path);
		die;
	}

	#return the fetched content
	$res->decode;
	return $res->content_ref;
}

#method to write the specified data to a file in MogileFS
sub _write {
	my $self = shift;
	my ($offset, $buf) = @_;

	#attempt writing the buffer to the output destination
	if(my $dest = $self->getOutputDest()) {
		#short-circuit if an invalid buffer was provided
		if(defined($buf) && ref($buf) ne 'SCALAR') {
			$self->fuse->log(ERROR, 'Invalid buffer passed to _write');
			$dest->{'error'} = 1;
			die;
		}

		#write buffer if it contains any data
		my $len = 0;
		if(ref($buf) eq 'SCALAR' && ($len = length($$buf))) {
			#build request
			my $req = HTTP::Request->new('PUT' => $dest->{'path'}, [
				'Content-Range' => 'bytes ' . $offset . '-' . ($offset + $len - 1) . '/*',
				'Content-Length' => $len,
			]);
			$req->content_ref($buf);

			#attempt this raw write
			my $res = $self->fuse->ua->send_request($req);
			if(!$res || $res->is_error) {
				$self->fuse->log(ERROR, 'Error writing data to: ' . $self->path);
				$dest->{'error'} = 1;
				die;
			}

			#update the output size
			{
				lock($dest);
				$dest->{'size'} = $offset + $len if($offset + $len > $dest->{'size'});
			}
		}

		#return the number of bytes written
		return $len;
	}
	else {
		$self->fuse->log(ERROR, 'Cannot write to file: ' . $self->path);
		die;
	}
}

sub dirty {
	return $_[0]->{'dirty'};
}

sub flags {
	return $_[0]->{'flags'};
}

sub flush {
	my $self = shift;

	#flush the current I/O handles if we are in a write mode and the output file is dirty
	if($self->writable && $self->dirty) {
		# copy any data that hasn't been copied yet and fsync any buffers
		$self->_cow($self->{'cowPtr'} + 1024*1024) while(defined $self->{'cowPtr'});
		$self->fsync();

		# flush file
		$self->_flush();
	}

	return;
}

sub fsync {
	return $_[0]->_fsync();
}

sub fuse {
	return $_[0]->{'fuse'};
}

#method that will return an output path for writing to this file
sub getOutputDest {
	my $self = shift;

	#short-circuit if we are in a read only mode
	return if(!$self->writable);

	#create an output path if one doesn't exist already
	{
		lock($self);
		if(!$self->{'dest'}) {
			#create a new temporary file in MogileFS
			my $tmpFile = eval{
				my $config = $self->fuse->_config;
				$self->MogileFS->{'backend'}->do_request('create_open', {
					'domain'     => $config->{'domain'},
					'class'      => $config->{'class'},
					'key'        => $self->path,
					'fid'        => 0,
					'multi_dest' => 0,
				});
			};
			if($@ || !$tmpFile) {
				$self->fuse->log(ERROR, 'Error creating file for output in MogileFS tracker: ' . $self->path);
				die;
			}

			#attempt creating a file at the specified location
			my $res = $self->fuse->ua->request(HTTP::Request->new('PUT' => $tmpFile->{'path'}, ['Content-Length' => 0]));
			if(!$res->is_success()) {
				$self->fuse->log(ERROR, 'Error creating file on MogileFS storage node ' . $tmpFile->{'path'} . ' for ' . $self->path);
				die;
			}

			#store the destination
			$self->{'dest'} = shared_clone({
				'devid' => $tmpFile->{'devid'},
				'fid'   => $tmpFile->{'fid'},
				'path'  => $tmpFile->{'path'},
				'size'  => 0,
			});
		}
	}

	return $self->{'dest'};
}

#method that will return the paths for the current file
sub getPaths {
	my $self = shift;

	#load the file paths
	{
		#lock here to make sure the paths are only loaded once and a thread doesn't
		#happen to get different paths for a request than other threads
		lock($self);
		if(!$self->{'paths'}) {
			my $mogc = $self->MogileFS();
			$self->{'paths'} = shared_clone([]);
			push @{$self->{'paths'}}, eval {$mogc->get_paths($self->path)};
			if($@) {
				#set the error code and string if we have a MogileFS::Client object
				($?, $!) = (-1, '');
				if($mogc) {
					$? = $mogc->errcode || -1;
					$! = $mogc->errstr || '';
				}
				$self->fuse->log(ERROR, 'Error retrieving paths for file: ' . $? . ': ' . $!);
				die;
			}
		}
	}

	#return the paths for this file
	return @{$self->{'paths'}};
}

sub id {
	return is_shared($_[0]) || refaddr($_[0]);
}

sub MogileFS {
	return $_[0]->fuse->MogileFS();
}

sub path {
	return $_[0]->{'path'};
}

sub read {
	my $self = shift;
	my ($len, $offset) = @_;

	#should the output file be used for reads
	my $output = $self->writable && $self->dirty;

	#make sure the read request from the output file is satisfiable
	$self->_cow($offset + $len) if($output);

	#issue raw read request
	return $self->_read($offset, $len,
		'output' => $output,
	);
}

sub release {
	my $self = shift;

	#force a final flush
	$self->flush();

	return;
}

#method that will truncate this file to the specified byte
sub truncate {
	my $self = shift;
	my ($size) = @_;

	#throw an error if it is not possible to truncate the file to the specified size
	if(!defined $self->{'cowPtr'} || $self->{'cowPtr'} > $size) {
		$self->fuse->log(ERROR, 'Cannot truncate ' . $self->path . ' to ' . $size);
		die;
	}

	#copy up to $size bytes of the file
	$self->_markAsDirty;
	$self->_cow($size, $size);
	delete $self->{'cowPtr'};

	return;
}

sub writable {
	return $_[0]->flags & (O_WRONLY | O_RDWR);
}

sub write {
	my $self = shift;
	my ($buf, $offset) = @_;

	#short-circuit if no data is actually being written
	my $len = length($$buf);
	return 0 if($len <= 0);

	#mark this file as being dirty and requiring a flush
	$self->_markAsDirty;

	#make sure data is copied from the old file past the specified write buffer
	$self->_cow($offset + $len);

	#write the raw data
	return $self->_write($offset, $buf);
}

1;
