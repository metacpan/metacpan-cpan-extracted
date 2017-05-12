package MogileFS::Client::Fuse;

=head1 NAME

MogileFS::Client::Fuse - FUSE binding for MogileFS

=head1 SYNOPSIS

 use MogileFS::Client::Fuse::FilePaths;

 my $fs = MogileFS::Client::Fuse::FilePaths->new(
   'mountpoint' => '/mnt/mogile-fuse',
   'trackers'   => ['tracker1:port', 'tracker2:port'],
   'domain'     => 'fuse.example.com::namespace',
   'class'      => 'default',
 );
 $fs->mount();

=head1 DESCRIPTION

This module provides support for mounting a MogileFS file store as a local
filesystem.

=cut

use strict;
use warnings;
use MRO::Compat;
use mro;
use threads::shared;

our $VERSION = '0.05';

use Errno qw{EACCES EEXIST EIO ENOENT EOPNOTSUPP};
use Fcntl qw{O_WRONLY};
use Fuse 0.11;
use LWP::UserAgent;
use MogileFS::Client;
use MogileFS::Client::Fuse::Constants qw{CALLBACKS :LEVELS THREADS};
use Params::Validate qw{validate_with ARRAYREF BOOLEAN SCALAR UNDEF};
use POSIX qw{strftime};
use Scalar::Util qw{blessed refaddr};

##Private static variables

#variables to track the currently mounted Fuse object
my %unshared;

# custom file class counter (used to autogenerate a file package)
my $fileClassIndex = 0;

##Static Methods

#constructor
#	buffered   => boolean indicating if open file handles should utilize write buffering, defaults to true
#	class      => the class to store files as in MogileFS
#	domain     => the domain to use in MogileFS
#	loglevel   => the log level to use for output
#	mountopts  => options to use when mounting the Fuse filesystem
#	mountpoint => where to mount the filesystem
#	threaded   => flag indicating if this MogileFS file system should be threaded or not
#	trackers   => the addresses for the MogileFS trackers
sub new {
	#create the new MogileFS::Client::Fuse object
	my $self = shift;
	$self = bless(shared_clone({}), ref($self) || $self);

	#initialize and return the new object
	return $self->_init(@_);
}

##Instance Methods

#return the config for this MogileFS::Client::Fuse object
sub _config {
	#cache the config in the local thread for faster access if threads are loaded
	if(THREADS) {
		my $config = $_[0]->_localElem('config');

		#copy the config to a local thread cache of it
		if(!defined $config) {
			#do a shallow copy of the config
			$config = {%{$_[0]->{'config'}}};

			#store the shallow copy
			$_[0]->_localElem('config', $config);
		}

		#return the local cache of this object's config
		return $config;
	}

	#default to returning the noncached config
	return $_[0]->{'config'};
}

#method that will initialize the MogileFS::Client::Fuse object
sub _init {
	my $self = shift;
	my %opt = validate_with(
		'allow_extra' => 1,
		'params' => \@_,
		'spec'   => {
			'buffered'   => {'type' => BOOLEAN, 'default' => 1},
			'class'      => {'type' => SCALAR | UNDEF, 'default' => undef},
			'domain'     => {'type' => SCALAR},
			'loglevel'   => {'type' => SCALAR, 'default' => ERROR},
			'mountopts'  => {'type' => SCALAR | UNDEF, 'default' => undef},
			'mountpoint' => {'type' => SCALAR},
			'readonly'   => {'type' => BOOLEAN, 'default' => undef},
			'threaded'   => {'type' => BOOLEAN, 'default' => THREADS},
			'trackers'   => {'type' => ARRAYREF},
		},
	);

	#die horribly if we are trying to reinit an existing object
	die 'You are trying to reinitialize an existing MogileFS::Client::Fuse object, this could introduce race conditions and is unsupported' if($self->{'initialized'});

	#disable threads if they aren't loaded
	$opt{'threaded'} = 0 if(!THREADS);

	# generate the customized file class
	{
		my @classes;
		push @classes, 'MogileFS::Client::Fuse::BufferedFile' if($opt{'buffered'});
		push @classes, 'MogileFS::Client::Fuse::File';

		# load the specified classes
		eval "require $_;" foreach(@classes);
		die $@ if($@);

		# create file class
		if(@classes > 1) {
			$opt{'fileClass'} = 'MogileFS::Client::Fuse::File::Generated' . $fileClassIndex;
			$fileClassIndex++;

			no strict 'refs';
			push @{$opt{'fileClass'} . '::ISA'}, @classes;
			mro::set_mro($opt{'fileClass'}, 'c3');
			Class::C3::reinitialize();
		}
		else {
			$opt{'fileClass'} = $classes[0];
		}
	}

	#initialize this object
	$self->{'config'} = shared_clone({%opt});
	$self->{'files'} = shared_clone({});
	$self->{'initialized'} = 1;

	#return the initialized object
	return $self;
}

#method that will access unshared object elements
sub _localElem {
	my $self = ($unshared{shift->id} ||= {});
	my $elem = shift;
	my $old = $self->{$elem};
	$self->{$elem} = $_[0] if(@_);
	return $old;
}

sub CLONE {
	#destroy all unshared objects to prevent non-threadsafe objects from being accessed by multiple threads
	%unshared = ();
	return 1;
}

#return the instance id for this object
sub id {
	return is_shared($_[0]) || refaddr($_[0]);
}

#function that will output a log message
sub log {
	my $self = shift;
	my ($level, $msg) = @_;
	return if($level > $self->_config->{'loglevel'});
	print STDERR strftime("[%Y-%m-%d %H:%M:%S] ", localtime), $msg, "\n";
}

#method that will return a MogileFS object
sub MogileFS {
	my $client = $_[0]->_localElem('MogileFS');

	#create and store a new client if one doesn't exist already
	if(!defined $client) {
		my $config = $_[0]->_config;
		$client = MogileFS::Client->new(
			'hosts'  => [@{$config->{'trackers'}}],
			'domain' => $config->{'domain'},
		);
		$_[0]->_localElem('MogileFS', $client);
	}

	#return the MogileFS client
	return $client;
}

#Method to mount the specified MogileFS domain to the filesystem
sub mount {
	my $self = shift;

	#short-circuit if a MogileFS file system is currently mounted
	{
		lock($self);
		return if($self->{'mounted'});
		$self->{'mounted'} = 1;
	}

	#set MogileFS debugging based on the log level
	local $MogileFS::DEBUG = ($self->_config->{'loglevel'} >= DEBUGMFS);

	#generate closures for supported callbacks
	my %callbacks;
	foreach(CALLBACKS) {
		#skip unsupported callbacks
		my $method = 'fuse_' . $_;
		next if(!$self->can($method));

		#create closure for this callback
		no strict "refs";
		if($self->_config->{'loglevel'} >= DEBUG) {
			$callbacks{$_} = sub {
				$self->log(DEBUG, $method . '(' . join(', ', map {defined($_) ? '"' . $_ . '"' : 'undef'} ($method eq 'fuse_write' ? ($_[0], length($_[1]).' bytes', @_[2,3]) : @_)) . ')');
				$self->$method(@_);
			};
		}
		else {
			$callbacks{$_} = sub {
				$self->$method(@_);
			};
		}
	}

	#mount the MogileFS file system
	Fuse::main(
		'mountopts'  => $self->_config->{'mountopts'},
		'mountpoint' => $self->_config->{'mountpoint'},
		'threaded'   => $self->_config->{'threaded'},
		'debug'      => ($self->_config->{'loglevel'} >= DEBUGFUSE),

		#callback functions
		%callbacks,
	);

	#release any files that are still active
	eval{$_->release()} foreach(values %{$self->{'files'}});
	$self->{'files'} = shared_clone({});

	#reset mounted state
	{
		lock($self);
		$self->{'mounted'} = 0;
	}

	#return
	return;
}

#thin wrapper for opening a file
sub openFile {
	my $self = shift;
	my ($path, $flags) = @_;

	#create a file object for the file being opened
	return $self->_config->{'fileClass'}->new(
		'fuse'  => $self,
		'path'  => $path,
		'flags' => $flags,
	);
}

sub sanitize_path {
#	my $self = shift;
#	my ($path) = @_;

	# return the root path if a path wasn't specified
	return '/' if(length($_[1]) == 0 || $_[1] eq '.');

	# make sure the path starts with a /
	return '/' . $_[1] if($_[1] !~ m!^/!s);

	# path doesn't need to be sanitized
	return $_[1];
}

#method that will return an LWP UserAgent object
sub ua {
	my $ua = $_[0]->_localElem('ua');

	#create and store a new ua if one doesn't exist already
	if(!defined $ua) {
		$ua = LWP::UserAgent->new(
			'keep_alive' => 60,
			'timeout'    => 5,
		);
		$_[0]->_localElem('ua', $ua);
	}

	#return the UserAgent
	return $ua;
}

##Callback Functions

sub fuse_flush {
	my $self = shift;
	my ($path, $file) = @_;

	eval {$file->flush()};
	return -EIO() if($@);

	return 0;
}

sub fuse_fsync {
	my $self = shift;
	my ($path, $flags, $file) = @_;

	eval {$file->fsync()};
	return -EIO() if($@);

	return 0;
}

sub fuse_getattr {
	return -EOPNOTSUPP();
}

sub fuse_getdir {
	return -EOPNOTSUPP();
}

sub fuse_getxattr {
	my $self = shift;
	my ($path, $name) = @_;

	if($name =~ /^MogileFS\.(?:class|checksum)$/s) {
		$path = $self->sanitize_path($path);
		my $resp = eval {$self->MogileFS->file_info($path, {'devices' => 0})};
		if($resp) {
			return $resp->{'checksum'} if($name eq 'MogileFS.checksum');
			return $resp->{'class'}    if($name eq 'MogileFS.class');
		}
	}

	return 0;
}

sub fuse_link {
	return -EOPNOTSUPP();
}

sub fuse_listxattr {
	return (
		'MogileFS.checksum',
		'MogileFS.class',
	), 0;
}

sub fuse_mknod {
	my $self = shift;
	my ($path) = @_;
	$path = $self->sanitize_path($path);

	# throw an error if read-only is enabled
	return -EACCES() if($self->_config->{'readonly'});

	#attempt creating an empty file
	eval {$self->openFile($path, O_WRONLY)->release()};
	return -EIO() if($@);

	#return success
	return 0;
}

sub fuse_open {
	my $self = shift;
	my ($path, $flags) = @_;
	$path = $self->sanitize_path($path);

	#open the requested file
	my $file = eval {$self->openFile($path, $flags)};
	return -EIO() if($@);
	return -EEXIST() if(!$file);

	#store the file in the list of open files
	{
		my $files = $self->{'files'};
		lock($files);
		return -EIO() if(defined $files->{$file->id});
		$files->{$file->id} = $file;
	};

	#return success and the open file handle
	return 0, $file;
}

sub fuse_read {
	my $self = shift;
	my ($path, $len, $off, $file) = @_;

	my $buf = eval{$file->read($len, $off)};
	return -EIO() if($@);

	return defined($buf) ? $$buf : '';
}

sub fuse_readlink {
	return 0;
}

sub fuse_release {
	my $self = shift;
	my ($path, $flags, $file) = @_;

	eval {
		#remove the file from the list of active file handles
		delete $self->{'files'}->{$file->id};

		#release the file handle
		$file->release();
	};
	return -EIO() if($@);

	return 0;
}

sub fuse_rename {
	return -EOPNOTSUPP();
}

sub fuse_setxattr {
	my $self = shift;
	my ($path, $name, $value, $flags) = @_;
	$path = $self->sanitize_path($path);

	# switch based on xattr name
	if($name eq 'MogileFS.class') {
		my $resp = eval {$self->MogileFS->update_class($path, $value)};
		return -EIO() if(!$resp || $@);
		return 0;
	}

	return -EOPNOTSUPP();
}

sub fuse_statfs {
	my $self = shift;

	# retrieve all device stats
	my $resp = eval {$self->MogileFS->{'backend'}->do_request('get_devices', {})};

	# calculate the total and free space for the storage cluster in blocks
	my $blkSize = 1024 * 1024;
	my $total = 0;
	my $free = 0;
	for(my $i = 1;$i <= $resp->{'devices'}; $i++) {
		my $dev = 'dev' . $i;
		my $mbFree  = $resp->{$dev . '_mb_free'};
		my $mbTotal = $resp->{$dev . '_mb_total'};
		$free  += $mbFree  if($mbFree && $resp->{$dev . '_status'} eq 'alive' && $resp->{$dev . '_observed_state'} eq 'writeable');
		$total += $mbTotal if($mbTotal);
	}
	$total *= (1024 * 1024) / $blkSize;
	$free *= (1024 * 1024) / $blkSize;

	# return the drive stats
	return (
		255,     # max name length
		1,       # files
		1,       # filesfree
		$total,  # blocks
		$free,   # blocks available
		$blkSize # block size
	);
}

sub fuse_symlink {
	return -EOPNOTSUPP();
}

sub fuse_truncate {
	my $self = shift;
	my ($path, $size) = @_;
	$path = $self->sanitize_path($path);

	# throw an error if read-only is enabled
	return -EACCES() if($self->_config->{'readonly'});

	#attempt to truncate the specified file
	eval{
		my $file = $self->openFile($path, O_WRONLY);
		$file->truncate($size);
		$file->release;
	};
	return -EIO() if($@);

	#return success
	return 0;
}

sub fuse_unlink {
	my $self = shift;
	my ($path) = @_;
	$path = $self->sanitize_path($path);

	# throw an error if read-only is enabled
	return -EACCES() if($self->_config->{'readonly'});

	#attempt deleting the specified file
	my $mogc = $self->MogileFS();
	my ($errcode, $errstr) = (-1, '');
	eval {$mogc->delete($path)};
	if($@) {
		#set the error code and string if we have a MogileFS::Client object
		if($mogc) {
			$errcode = $mogc->errcode || -1;
			$errstr = $mogc->errstr || '';
		}
		$self->log(ERROR, "Error unlinking file: $errcode: $errstr");
		$! = $errstr;
		$? = $errcode;
		return -EIO();
	}

	#return success
	return 0;
}

sub fuse_write {
	my $self = shift;
	my $buf = \$_[1];
	my $offset = $_[2];
	my $file = $_[3];

	# throw an error if read-only is enabled
	return -EACCES() if($self->_config->{'readonly'});

	my $bytesWritten = eval{$file->write($buf, $offset)};
	return -EIO() if($@);

	return $bytesWritten;
}

1;

__END__

=head1 CAVEATS

This module requires MogileFS storage nodes that support partial content PUT
requests using the Content-Range header.

Currently deleting a directory is unsupported because it is not supported in the
FilePaths MogileFS plugin.

Multiple threads/processes simultaneously writing to the same open file handle
is untested, it may work or it may corrupt the file due to unforeseen race
conditions.

=head1 AUTHOR

Daniel Frett

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2012 - Campus Crusade for Christ International

This is free software, licensed under:

  The (three-clause) BSD License

=cut
