package MogileFS::Client::Fuse::Constants;

use strict;
use base qw{Exporter};

our $VERSION = '0.05';

use constant CALLBACKS => qw{
	getattr readlink getdir mknod mkdir unlink rmdir symlink
	rename link chmod chown truncate utime open read write statfs
	flush release fsync setxattr getxattr listxattr removexattr
};

#log levels
use constant LOG_OFF    => -1;
use constant LOG_NOTICE => 0;
use constant ERROR      => 1;
use constant DEBUG      => 2;
use constant DEBUGMFS   => 3;
use constant DEBUGFUSE  => 4;

#are threads enabled
use constant THREADS => $threads::threads;

our @EXPORT_OK = qw{
	CALLBACKS
	LOG_OFF
	LOG_NOTICE
	ERROR
	DEBUG
	DEBUGMFS
	DEBUGFUSE
	THREADS
};
our %EXPORT_TAGS = (
	LEVELS => [qw{
		LOG_OFF
		LOG_NOTICE
		ERROR
		DEBUG
		DEBUGMFS
		DEBUGFUSE
	}],
);

1;
