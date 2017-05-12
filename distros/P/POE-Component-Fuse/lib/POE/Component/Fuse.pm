# Declare our package
package POE::Component::Fuse;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.05';

# Import what we need from the POE namespace
use POE;
use POE::Session;
use POE::Wheel::Run;
use POE::Filter::Reference;
use POE::Filter::Line;
use base 'POE::Session::AttributeBased';

# get some system constants
use Errno qw( :POSIX );		# ENOENT EISDIR etc

# Set some constants
BEGIN {
	if ( ! defined &DEBUG ) { *DEBUG = sub () { 0 } }
}

# starts the component!
sub spawn {
	my $class = shift;

	# The options hash
	my %opt;

	# Support passing in a hash ref or a regular hash
	if ( ( @_ & 1 ) and ref $_[0] and ref( $_[0] ) eq 'HASH' ) {
		%opt = %{ $_[0] };
	} else {
		# Sanity checking
		if ( @_ & 1 ) {
			warn 'PoCo-Fuse requires an even number of options passed to spawn()';
			return 0;
		}

		%opt = @_;
	}

	# lowercase keys
	%opt = map { lc($_) => $opt{$_} } keys %opt;

	# Get the session alias
	if ( ! exists $opt{'alias'} or ! defined $opt{'alias'} ) {
		if ( DEBUG ) {
			warn 'Using default ALIAS = fuse';
		}

		# Set the default
		$opt{'alias'} = 'fuse';
	} else {
		# TODO validate for sanity
	}

	# are we using a Filesys::Virtual object?
	if ( ! exists $opt{'vfilesys'} or ! defined $opt{'vfilesys'} ) {
		if ( DEBUG ) {
			warn 'Using default VFILESYS = false';
		}
	} else {
		# make sure it's a real object
		if ( ! ref $opt{'vfilesys'} ) {
			warn 'The passed-in vfilesys option is not an object';
			return 0;
		} else {
			if ( $opt{'vfilesys'}->isa( 'Filesys::Virtual' ) ) {
				# Wrap the vfilesys object around the FUSE <-> Filesys::Virtual wrapper
				require Fuse::Filesys::Virtual;
				$opt{'vfilesys'} = Fuse::Filesys::Virtual->new( $opt{'vfilesys'}, { 'debug' => 0 } );
			} else {
				if ( $opt{'vfilesys'}->isa( 'Filesys::Virtual::Async' ) ) {
					# wrap it around our internal wrapper
					require POE::Component::Fuse::AsyncFsV;
					$opt{'vfilesys'} = POE::Component::Fuse::AsyncFsV->new( $opt{'vfilesys'} );
				} else {
					warn 'The passed-in vfilesys object is not a subclass of Filesys::Virtual or Filesys::Virtual::Async';
					return 0;
				}
			}
		}
	}

	# setup the session
	if ( ! exists $opt{'session'} or ! defined $opt{'session'} ) {
		# did we select vfilesys?
		if ( ! exists $opt{'vfilesys'} ) {
			# if we're running under POE, grab the active session
			$opt{'session'} = $poe_kernel->get_active_session();
			if ( ! defined $opt{'session'} or $opt{'session'}->isa( 'POE::Kernel' ) ) {
				warn 'PoCo-Fuse needs a session to send the callbacks to!';
				return 0;
			} else {
				$opt{'session'} = $opt{'session'}->ID;
			}
		}
	} else {
		# TODO validate for sanity
	}

	# setup the callback prefix
	if ( ! exists $opt{'prefix'} or ! defined $opt{'prefix'} ) {
		# do we even need to set this?
		if ( exists $opt{'session'} ) {
			if ( DEBUG ) {
				warn 'Using default event PREFIX = fuse_';
			}

			# Set the default
			$opt{'prefix'} = 'fuse_';
		}
	} else {
		# TODO validate for sanity
	}

	# should we automatically umount?
	if ( exists $opt{'umount'} ) {
		$opt{'umount'} = $opt{'umount'} ? 1 : 0;
	} else {
		if ( DEBUG ) {
			warn 'Using default UMOUNT = false';
		}

		$opt{'umount'} = 0;
	}

	# verify the mountpoint
	if ( ! exists $opt{'mount'} or ! defined $opt{'mount'} ) {
		if ( DEBUG ) {
			warn 'Using default MOUNT = /tmp/poefuse';
		}

		# set the default
		$opt{'mount'} = '/tmp/poefuse';
	} else {
		# TODO validate for sanity
	}

	# setup the FUSE mount options
	if ( ! exists $opt{'mountopts'} or ! defined $opt{'mountopts'} ) {
		if ( DEBUG ) {
			warn 'Using default MOUNTOPTS = undef';
		}

		# Set the default
		$opt{'mountopts'} = undef;
	} else {
		# TODO validate for sanity
	}

	# should we automatically create the mountpoint?
	if ( exists $opt{'mkdir'} ) {
		$opt{'mkdir'} = $opt{'mkdir'} ? 1 : 0;
	} else {
		if ( DEBUG ) {
			warn 'Using default MKDIR = false';
		}

		# set the default
		$opt{'mkdir'} = 0;
	}

	# should we automatically remove the mountpoint?
	if ( exists $opt{'rmdir'} ) {
		$opt{'rmdir'} = $opt{'rmdir'} ? 1 : 0;
	} else {
		if ( DEBUG ) {
			warn 'Using default RMDIR = false';
		}

		# set the default
		$opt{'rmdir'} = 0;
	}

	# make sure the mountpoint exists
	if ( ! -d $opt{'mount'} ) {
		# does it exist?
		if ( -e _ ) {
			# gaah, just let the caller know
			if ( exists $opt{'session'} ) {
				$poe_kernel->post( $opt{'session'}, $opt{'prefix'} . 'CLOSED', 'Mountpoint at ' . $opt{'mount'} . ' is not a directory!' );
			}
			if ( DEBUG ) {
				warn 'Mountpoint at ' . $opt{'mount'} . ' is not a directory!';
			}
			return 0;
		} else {
			# should we try to create it?
			if ( $opt{'mkdir'} ) {
				if ( ! mkdir( $opt{'mount'} ) ) {
					# gaah, just let the caller know
					if ( exists $opt{'session'} ) {
						$poe_kernel->post( $opt{'session'}, $opt{'prefix'} . 'CLOSED', 'Unable to create directory at ' . $opt{'mount'} . ' - ' . $! );
					}
					if ( DEBUG ) {
						warn 'Unable to create directory at ' . $opt{'mount'} . ' - ' . $!;
					}
					return 0;
				}
			} else {
				# gaah, just let the caller know
				if ( exists $opt{'session'} ) {
					$poe_kernel->post( $opt{'session'}, $opt{'prefix'} . 'CLOSED', 'Mountpoint at ' . $opt{'mount'} . ' does not exist!' );
				}
				if ( DEBUG ) {
					warn 'Mountpoint at ' . $opt{'mount'} . ' does not exist!';
				}
				return 0;
			}
		}
	}

	# Create our session
	POE::Session->create(
		__PACKAGE__->inline_states(),	## no critic ( RequireExplicitInclusion )
		'heap'	=>	{
			'ALIAS'		=> $opt{'alias'},
			'MOUNT'		=> $opt{'mount'},
			'MOUNTOPTS'	=> $opt{'mountopts'},
			'UMOUNT'	=> $opt{'umount'},
			'RMDIR'		=> $opt{'rmdir'},
			( exists $opt{'session'} ? ( 'SESSION' => $opt{'session'} ) : () ),
			( exists $opt{'prefix'} ? ( 'PREFIX' => $opt{'prefix'} ) : () ),

			( exists $opt{'vfilesys'} ? ( 'VFILESYS' => $opt{'vfilesys'} ) : () ),

			# The Wheel::Run object
			'WHEEL'		=> undef,

			# Are we shutting down?
			'SHUTDOWN'	=> 0,
		},
	);

	# return success
	return 1;
}

# This starts the component
sub _start : State {
	if ( DEBUG ) {
		warn 'Starting alias "' . $_[HEAP]->{'ALIAS'} . '"';
	}

	# Set up the alias for ourself
	$_[KERNEL]->alias_set( $_[HEAP]->{'ALIAS'} );

	# spawn the subprocess
	$_[KERNEL]->yield( 'wheel_setup' );

	# increment the refcount for calling session
	if ( exists $_[HEAP]->{'SESSION'} ) {
		$_[KERNEL]->refcount_increment( $_[HEAP]->{'SESSION'}, 'fuse' );
	}

	return;
}

# POE Handlers
sub _stop : State {
	if ( DEBUG ) {
		warn 'Stopping alias "' . $_[HEAP]->{'ALIAS'} . '"';
	}

	# fire off the umount command
	if ( $_[HEAP]->{'UMOUNT'} ) {
		# FIXME this is bad because it blocks POE but a good temporary solution :(
		# FIXME make this portable!
		system("fusermount -u -z $_[HEAP]->{'MOUNT'} >/dev/null 2>&1");
	}

	# remove the mountpoint?
	if ( $_[HEAP]->{'RMDIR'} ) {
		if ( ! rmdir( $_[HEAP]->{'MOUNT'} ) ) {
			warn "unable to rmdir mountpoint: $!";
		}
	}

	return;
}
sub _parent : State {
	return;
}

sub shutdown : State {
	if ( DEBUG ) {
		warn "received shutdown signal";
	}

	# okay, let's shutdown now!
	$_[HEAP]->{'SHUTDOWN'} = 1;

	# cleanup some stuff
	$_[KERNEL]->alias_remove( $_[HEAP]->{'ALIAS'} );
	if ( defined $_[HEAP]->{'WHEEL'} ) {
		$_[HEAP]->{'WHEEL'}->pause_stdout;
		$_[HEAP]->{'WHEEL'}->pause_stderr;
		$_[HEAP]->{'WHEEL'}->kill( 9 );
		undef $_[HEAP]->{'WHEEL'};
	}

	# Do we have a session to inform?
	if ( exists $_[HEAP]->{'SESSION'} ) {
		# decrement the refcount for calling session
		$_[KERNEL]->refcount_decrement( $_[HEAP]->{'SESSION'}, 'fuse' );

		# let it know we shutdown
		if ( exists $_[HEAP]->{'ERROR'} ) {
			$_[KERNEL]->call( $_[HEAP]->{'SESSION'}, $_[HEAP]->{'PREFIX'} . 'CLOSED', $_[HEAP]->{'ERROR'} );
		} else {
			$_[KERNEL]->call( $_[HEAP]->{'SESSION'}, $_[HEAP]->{'PREFIX'} . 'CLOSED', 'shutdown' );
		}
	}

	return;
}

# creates the subprocess
sub wheel_setup : State {
	if ( DEBUG ) {
		warn 'Attempting creation of SubProcess wheel now...';
	}

	# Are we shutting down?
	if ( $_[HEAP]->{'SHUTDOWN'} ) {
		# Do not re-create the wheel...
		if ( DEBUG ) {
			warn 'Hmm, we are shutting down but got setup_wheel event...';
		}
		return;
	}

	# Add the windows method
	if ( $^O eq 'MSWin32' ) {
		# make sure we load the subprocess
		require POE::Component::Fuse::SubProcess;

		# Set up the SubProcess we communicate with
		$_[HEAP]->{'WHEEL'} = POE::Wheel::Run->new(
			# What we will run in the separate process
			'Program'	=>	\&POE::Component::Fuse::SubProcess::main(),

			# Kill off existing FD's
			'CloseOnCall'	=>	0,

			# events
			'ErrorEvent'	=>	'wheel_error',
			'CloseEvent'	=>	'wheel_close',
			'StdoutEvent'	=>	'wheel_stdout',
			'StderrEvent'	=>	'wheel_stderr',

			# Set our filters
			'StdinFilter'	=>	POE::Filter::Reference->new(),		# Communicate with child via Storable::nfreeze
			'StdoutFilter'	=>	POE::Filter::Reference->new(),		# Receive input via Storable::nfreeze
			'StderrFilter'	=>	POE::Filter::Line->new(),		# Plain ol' error lines
		);
	} else {
		# Set up the SubProcess we communicate with
		$_[HEAP]->{'WHEEL'} = POE::Wheel::Run->new(
			# What we will run in the separate process
			#'Program'	=>	"valgrind --suppressions=/home/apoc/perl.supp --leak-check=full --leak-resolution=high --num-callers=50 $^X -MPOE::Component::Fuse::SubProcess -e 'POE::Component::Fuse::SubProcess::main()'",
			'Program'	=>	"$^X -MPOE::Component::Fuse::SubProcess -e 'POE::Component::Fuse::SubProcess::main()'",

			# Kill off existing FD's
			'CloseOnCall'	=>	1,

			# events
			'ErrorEvent'	=>	'wheel_error',
			'CloseEvent'	=>	'wheel_close',
			'StdoutEvent'	=>	'wheel_stdout',
			'StderrEvent'	=>	'wheel_stderr',

			# Set our filters
			'StdinFilter'	=>	POE::Filter::Reference->new(),		# Communicate with child via Storable::nfreeze
			'StdoutFilter'	=>	POE::Filter::Reference->new(),		# Receive input via Storable::nfreeze
			'StderrFilter'	=>	POE::Filter::Line->new(),		# Plain ol' error lines
		);
	}

	# Check for errors
	if ( ! defined $_[HEAP]->{'WHEEL'} ) {
		# flag the error
		$_[HEAP]->{'ERROR'} = 'Unable to create the FUSE subprocess';

		# shut ourself down
		$_[KERNEL]->yield( 'shutdown' );
	} else {
		# smart CHLD handling
		if ( $_[KERNEL]->can( 'sig_child' ) ) {
			$_[KERNEL]->sig_child( $_[HEAP]->{'WHEEL'}->PID => 'Wheel_CHLD' );
		} else {
			$_[KERNEL]->sig( 'CHLD' => 'Wheel_CHLD' );
		}

		# push the data the subprocess needs to initialize
		$_[HEAP]->{'WHEEL'}->put( {
			'ACTION'	=> 'INIT',
			'MOUNT'		=> $_[HEAP]->{'MOUNT'},
			'MOUNTOPTS'	=> $_[HEAP]->{'MOUNTOPTS'},
		} );
	}

	return;
}

sub wheel_error : State {
	if ( DEBUG ) {
		my( $rv, $errno, $error, $id, $handle ) = @_[ ARG0 .. ARG4 ];
		warn "wheel error: $rv - $errno - $error - $id - $handle";
	}

	return;
}

sub wheel_close : State {
	# was this expected?
	if ( ! $_[HEAP]->{'SHUTDOWN'} ) {
		# set the error flag
		$_[HEAP]->{'ERROR'} = 'FUSE closed on us ( possibly umounted )';
	}

	# arg, cleanup!
	undef $_[HEAP]->{'WHEEL'};
	$_[KERNEL]->call( $_[SESSION], 'shutdown' );

	return;
}

sub wheel_stderr : State {
	my $line = $_[ARG0];

	# skip empty lines
	if ( $line ne '' ) {
		if ( DEBUG ) {
			print "received stderr from subprocess: $line\n";
		}
	}

	return;
}

sub wheel_stdout : State {
	my $data = $_[ARG0];

	if ( defined $data and ref $data and ref( $data ) eq 'HASH' ) {
		if ( DEBUG ) {
			require Data::Dumper;
			warn "received from subprocess: " . Data::Dumper::Dumper( $data );
		}

		# TODO generate some way of matching request with response when we go multithreaded...

		# vfilesys or session?
		if ( exists $_[HEAP]->{'VFILESYS'} ) {
			my $subname = $_[HEAP]->{'VFILESYS'}->can( $data->{'TYPE'} );
			if ( ! defined $subname ) {
				$_[KERNEL]->yield( 'reply', [ $data->{'TYPE'}, $data->{'CONTEXT'} ], [ -EIO() ] );
			} else {
				if ( $_[HEAP]->{'VFILESYS'}->isa( 'POE::Component::Fuse::AsyncFsV' ) ) {
					$subname->( $_[HEAP]->{'VFILESYS'}, $data->{'CONTEXT'}, @{ $data->{'ARGS'} } );
				} else {
					my @result = $subname->( $_[HEAP]->{'VFILESYS'}, @{ $data->{'ARGS'} } );
					$_[KERNEL]->yield( 'reply', [ $data->{'TYPE'}, $data->{'CONTEXT'} ], \@result );
				}
			}
		} else {
			# make the postback
			my $postback = $_[SESSION]->postback( 'reply', $data->{'TYPE'}, $data->{'CONTEXT'} );

			# send it to the session!
			$_[KERNEL]->post( $_[HEAP]->{'SESSION'}, $_[HEAP]->{'PREFIX'} . $data->{'TYPE'}, $postback, $data->{'CONTEXT'}, @{ $data->{'ARGS'} } );
		}
	} else {
		if ( DEBUG ) {
			warn "received malformed input from subprocess";
		}
	}

	return;
}

sub reply : State {
	my( $orig_data, $result ) = @_[ ARG0, ARG1 ];

	# send it down the pipe!
	if ( defined $_[HEAP]->{'WHEEL'} ) {
		# build the data struct
		my $data = {
			'ACTION'	=> 'REPLY',
			'TYPE'		=> $orig_data->[0],
			'RESULT'	=> $result,
		};

		# we pass it back down in case somebody changed fh
		if ( defined $orig_data->[1] and exists $orig_data->[1]->{'fh'} and defined $orig_data->[1]->{'fh'} ) {
			$data->{'FH'} = $orig_data->[1]->{'fh'};
		}

		if ( DEBUG ) {
			require Data::Dumper;
			warn "sending to subprocess: " . Data::Dumper::Dumper( $data );
		}

		# capture it in an eval block - sometimes the wheel disappears!
		eval {
			$_[HEAP]->{'WHEEL'}->put( $data );
		};
		if ( DEBUG and $@ ) {
			warn "error sending to subprocess: $@";
		}
	} else {
		if ( DEBUG ) {
			warn "wheel disappeared, unable to send reply!";
		}
	}

	return;
}

1;
__END__
=head1 NAME

POE::Component::Fuse - Using FUSE in POE asynchronously

=head1 SYNOPSIS

	#!/usr/bin/perl
	# a simple example to illustrate directory listings
	use strict; use warnings;

	use POE qw( Component::Fuse );
	use base 'POE::Session::AttributeBased';

	# constants we need to interact with FUSE
	use Errno qw( :POSIX );		# ENOENT EISDIR etc

	my %files = (
		'/' => {	# a directory
			type => 0040,
			mode => 0755,
			ctime => time()-1000,
		},
		'/a' => {	# a file
			type => 0100,
			mode => 0644,
			ctime => time()-2000,
		},
		'/foo' => {	# a directory
			type => 0040,
			mode => 0755,
			ctime => time()-3000,
		},
		'/foo/bar' => {	# a file
			type => 0100,
			mode => 0755,
			ctime => time()-4000,
		},
	);

	POE::Session->create(
		__PACKAGE__->inline_states(),
	);

	POE::Kernel->run();
	exit;

	sub _start : State {
		# create the fuse session
		POE::Component::Fuse->spawn;
		print "Check us out at the default place: /tmp/poefuse\n";
		print "You can navigate the directory, but no I/O operations are supported!\n";
	}
	sub _child : State {
		return;
	}
	sub _stop : State {
		return;
	}

	# return unimplemented for the rest of the FUSE api
	sub _default : State {
		if ( $_[ARG0] =~ /^fuse/ ) {
			$_[ARG1]->[0]->( -ENOSYS() );
		}
		return;
	}

	sub fuse_CLOSED : State {
		print "shutdown: $_[ARG0]\n";
		return;
	}

	sub fuse_getattr : State {
		my( $postback, $context, $path ) = @_[ ARG0 .. ARG2 ];

		if ( exists $files{ $path } ) {
			my $size = exists( $files{ $path }{'cont'} ) ? length( $files{ $path }{'cont'} ) : 0;
			$size = $files{ $path }{'size'} if exists $files{ $path }{'size'};
			my $modes = ( $files{ $path }{'type'} << 9 ) + $files{ $path }{'mode'};
			my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = ( 0, 0, 0, 1, (split( /\s+/, $) ))[0], $>, 1, 1024 );
			my ($atime, $ctime, $mtime);
			$atime = $ctime = $mtime = $files{ $path }{'ctime'};

			# finally, return the darn data!
			$postback->( $dev, $ino, $modes, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks );
		} else {
			# path does not exist
			$postback->( -ENOENT() );
		}

		return;
	}

	sub fuse_getdir : State {
		my( $postback, $context, $path ) = @_[ ARG0 .. ARG2 ];

		if ( exists $files{ $path } ) {
			if ( $files{ $path }{'type'} & 0040 ) {
				# construct all the data in this directory
				my @list = map { $_ =~ s/^$path\/?//; $_ }
					grep { $_ =~ /^$path\/?[^\/]+$/ } ( keys %files );

				# no need to add "." and ".." - FUSE handles it automatically!

				# return the list with a success code on the end
				$postback->( @list, 0 );
			} else {
				# path is not a directory!
				$postback->( -ENOTDIR() );
			}
		} else {
			# path does not exist!
			$postback->( -ENOENT() );
		}

		return;
	}

	sub fuse_getxattr : State {
		my( $postback, $context, $path, $attr ) = @_[ ARG0 .. ARG3 ];

		# we don't have any extended attribute support
		$postback->( 0 );

		return;
	}

=head1 ABSTRACT

Using this module will enable you to asynchronously process FUSE requests from the kernel in POE. Think of
this module as a simple wrapper around L<Fuse> to POEify it.

=head1 DESCRIPTION

This module allows you to use FUSE filesystems in POE. Basically, it is a wrapper around L<Fuse> and exposes
it's API via events. Furthermore, you can use L<Filesys::Virtual> to handle the filesystem.

The standard way to use this module is to do this:

	use POE;
	use POE::Component::Fuse;

	POE::Component::Fuse->spawn( ... );

	POE::Session->create( ... );

	POE::Kernel->run();

Naturally, the best way to quickly get up to speed is to study other implementations of FUSE to see what
they have done. Furthermore, please look at the scripts in the examples/ directory in the tarball!

=head2 Starting Fuse

To start Fuse, just call it's spawn method:

	POE::Component::Fuse->spawn( ... );

This method will return failure on errors or return success.

NOTE: The act of starting/stopping PoCo-Fuse fires off _child events, read the POE documentation on
what to do with them :)

This constructor accepts either a hashref or a hash, valid options are:

=head3 alias

This sets the session alias in POE.

The default is: "fuse"

=head3 mount

This sets the mountpoint for FUSE.

If this mountpoint doesn't exist ( and the "mkdir" option isn't set ) spawn() will return failure.

The default is: "/tmp/poefuse"

=head3 mountoptions

This passes the options to FUSE for mounting.

NOTE: this is a comma-separated string!

The default is: undef

=head3 mkdir

If true, PoCo-Fuse will attempt to mkdir the mountpoint if it doesn't exist.

If the mkdir attempt fails, spawn() will return failure.

The default is: false

=head3 umount

If true, PoCo-Fuse will attempt to umount the filesystem on exit/shutdown.

This basically calls "fusermount -u -z $mountpoint"

WARNING: This is not exactly portable and is in the testing stage. Feedback would be much appreciated!

The default is: false

=head3 rmdir

If true, PoCo-Fuse will attempt to rmdir the mountpoint on exit/shutdown. Extremely useful when you specify a mountpoint
that was randomly-generated ( e.x. "/tmp/poe$$" ) so we don't "leave behind" lots of empty directories.

WARNING: Be careful when using this or your directory could vanish!

=head3 prefix

The prefix for all events generated by this module when using the "session" method.

The default is: "fuse_"

=head3 session

The session to send all FUSE events to. Used in conjunction with the "prefix" option, you can control
where the events arrive.

If this option is missing ( or POE is not running ) and "vfilesys" isn't enabled spawn() will return failure.

NOTE: You cannot use this and "vfilesys" at the same time! PoCo-Fuse will pick vfilesys over this! If this is the
case, then the session will only get the CLOSE event, not API requests.

The default is: calling session ( if POE is running ) when "vfilesys" isn't specified or error

=head3 vfilesys

The L<Filesys::Virtual> object to use as our filesystem. PoCo-Fuse will proceed to use L<Fuse::Filesys::Virtual>
to wrap around it and process the events internally.

Furthermore, you can also use L<Filesys::Virtual::Async> subclasses, this module understands their callback API
and will process it properly!

If this option is missing and "session" isn't enabled spawn() will return failure.

NOTE: You cannot use this and "session" at the same time! PoCo-Fuse will pick this over session!

Compatibility has not been tested with all Filesys::Virtual::XYZ subclasses, so please let me know if some isn't
working properly!

The default is: not used

=head2 Commands

There is only one command you can use, because this module does nothing except process FUSE events.

=head3 shutdown

Tells this module to kill the FUSE mount and terminates the session. Due to the semantics of FUSE, this
will often result in a wedged filesystem. You would need to either umount it manually ( via "fusermount -u $mount" )
or by enabling the "umount" option.

=head2 Events

If you aren't using the Filesys::Virtual interface, the FUSE api will be exposed to you in it's glory via
events to your session. You can process them, and send the data back via the supplied postback. All the arguments
are identical to the one in L<Fuse> so please take a good look at that module for more information!

The only place where this differs is the additional arguments. All events will receive 2 extra arguments in front
of the standard FUSE args. They are the postback and context info. The postback is self-explanatory, you
supply the return data to it and it'll fire an event back to PoCo-Fuse for processing. The context is the
calling context received from FUSE. It is a hashref with the 3 keys in it: uid, gid, pid. It is received via
the fuse_get_context() sub from L<Fuse>.

Remember that the events are the fuse methods with the prefix tacked on to them. A typical FUSE handler would
look something like the example below. ( it is sugared via POE::Session::AttributeBased hah )

	sub fuse_getdir : State {
		my( $postback, $context, $path ) = @_[ ARG0 .. ARG2 ];

		# somehow get our data, we fake it here for instructional reasons
		$postback->( 'foo', 'bar', 0 );
		return;
	}

Again, pretty please read the L<Fuse> documentation for all the events you can receive. Here's the list
as of Fuse v0.09: getattr readlink getdir mknod mkdir unlink rmdir symlink rename link chmod chown truncate
utime open read write statfs flush release fsync setxattr getxattr listxattr removexattr.

=head3 CLOSED

This is a special event sent to the session notifying it of component shutdown. As usual, it will be prefixed by the
prefix set in the options.

The event handler will get one argument, the error string. If you shut down the component, it will be "shutdown",
otherwise it will contain some error string. A sample handler is below.

	sub fuse_CLOSED : State {
		my $error = $_[ARG0];
		if ( $error ne 'shutdown' ) {
			print "AIEE: $error\n";

			# do some actions like emailing the sysadmin, restarting the component, etc...
		} else {
			# we told it to shutdown, so what do we want to do next?
		}

		return;
	}

=head2 Internals

=head3 XSification

This module does it's magic by spawning a subprocess via Wheel::Run and passing events back and forth to
the L<Fuse> module loaded in it. This isn't exactly optimal which is obvious, but it works perfectly!

I'm working on improving this by using XS but it will take me some time seeing how I'm a n00b :( Furthermore,
FUSE doesn't really help because I have to figure out how to get at the filehandle buried deep in it and expose
it to POE...

If anybody have the time and knowledge, please help me out and we can have fun converting this to a pure XS module!

=head3 Debugging

You can enable debug mode which prints out some information ( and especially error messages ) by doing this:

	sub POE::Component::Fuse::DEBUG () { 1 }
	use POE::Component::Fuse;


=head1 EXPORT

None.

=head1 SEE ALSO

L<POE>

L<Fuse>

L<Filesys::Virtual>

L<Fuse::Filesys::Virtual>

L<Filesys::Virtual::Async>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::Fuse

=head2 Websites

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-Fuse>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-Fuse>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Fuse>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-Fuse>

=back

=head2 Bugs

Please report any bugs or feature requests to C<bug-poe-component-fuse at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-Fuse>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to xantus who got me motivated to write this :)

Also, this module couldn't have gotten off the ground if not for L<Fuse> which did the heavy XS lifting!

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
