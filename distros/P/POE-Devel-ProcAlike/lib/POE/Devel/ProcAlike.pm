# Declare our package
package POE::Devel::ProcAlike;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.02';

# Import what we need from the POE namespace
use POE;
use POE::Component::Fuse;
use base 'POE::Session::AttributeBased';

# load our modules to manage the filesystem
use Filesys::Virtual::Async::Dispatcher;
use Filesys::Virtual::Async::inMemory;
use POE::Devel::ProcAlike::POEInfo;
use POE::Devel::ProcAlike::PerlInfo;
use POE::Devel::ProcAlike::ModuleInfo;

# portability...
use File::Spec;

# Set some constants
BEGIN {
	if ( ! defined &DEBUG ) { *DEBUG = sub () { 0 } }
}

# starts the component!
sub spawn {
	my $class = shift;

	# are we already created?
	if ( $poe_kernel->alias_resolve( 'poe-devel-procalike' ) ) {
		if ( DEBUG ) {
			warn "Calling " . __PACKAGE__ . "->spawn() multiple times will only result in a singleton!";
		}
		return 1;
	}

	# The options hash
	my %opt;

	# Support passing in a hash ref or a regular hash
	if ( ( @_ & 1 ) and ref $_[0] and ref( $_[0] ) eq 'HASH' ) {
		%opt = %{ $_[0] };
	} else {
		# Sanity checking
		if ( @_ & 1 ) {
			warn __PACKAGE__ . ' requires an even number of options passed to spawn()';
			return 0;
		}

		%opt = @_;
	}

	# lowercase keys
	%opt = map { lc($_) => $opt{$_} } keys %opt;

	# setup the FUSE mount options
	if ( ! exists $opt{'fuseopts'} or ! defined $opt{'fuseopts'} ) {
		if ( DEBUG ) {
			warn 'Using default FUSEOPTS = undef';
		}

		# Set the default
		$opt{'fuseopts'} = undef;
	} else {
		# TODO validate for sanity
	}

	# setup the user-supplied "misc" fsv object
	if ( ! exists $opt{'vfilesys'} or ! defined $opt{'vfilesys'} ) {
		if ( DEBUG ) {
			warn 'Using default VFILESYS = undef';
		}

		# Set the default
		$opt{'vfilesys'} = undef;
	} else {
		# make sure it's a real object
		if ( ! ref $opt{'vfilesys'} ) {
			warn 'The passed-in vfilesys option is not an object';
			return 0;
		} else {
			if ( ! $opt{'vfilesys'}->isa( 'Filesys::Virtual::Async' ) ) {
				warn 'The passed-in vfilesys object is not a subclass of Filesys::Virtual::Async';
				return 0;
			}
		}
	}

	# Create our session
	POE::Session->create(
		__PACKAGE__->inline_states(),
		'heap'	=>	{
			'ALIAS'		=> 'poe-devel-procalike',
			'FUSEOPTS'	=> $opt{'fuseopts'},

			# our filesystem objects
			'DISPATCHER'	=> undef,
			'ROOTFS'	=> undef,
			'PERLFS'	=> POE::Devel::ProcAlike::PerlInfo->new(),
			'POEFS'		=> POE::Devel::ProcAlike::POEInfo->new(),
			'MODULEFS'	=> POE::Devel::ProcAlike::ModuleInfo->new(),
			'MISCFS'	=> $opt{'vfilesys'},
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

	# create the root filesystem for use in the Dispatcher
	my $filesystem = {
		File::Spec->rootdir()	=> {
			'mode'	=> => oct( '040755' ),
			'ctime'	=> time(),
		},
		File::Spec->catdir( File::Spec->rootdir(), 'perl' ) => {
			'mode'	=> => oct( '040755' ),
			'ctime'	=> time(),
		},
		File::Spec->catdir( File::Spec->rootdir(), 'kernel' ) => {
			'mode'	=> => oct( '040755' ),
			'ctime'	=> time(),
		},
		File::Spec->catdir( File::Spec->rootdir(), 'modules' ) => {
			'mode'	=> => oct( '040755' ),
			'ctime'	=> time(),
		},
		File::Spec->catdir( File::Spec->rootdir(), 'misc' ) => {
			'mode'	=> => oct( '040755' ),
			'ctime'	=> time(),
		},
	};
	$_[HEAP]->{'ROOTFS'} = Filesys::Virtual::Async::inMemory->new(
		'filesystem'	=> $filesystem,
		'readonly'	=> 1,
	);

	# finally, tie them all together in the dispatcher!
	$_[HEAP]->{'DISPATCHER'} = Filesys::Virtual::Async::Dispatcher->new(
		'rootfs'	=> $_[HEAP]->{'ROOTFS'},
	);
	$_[HEAP]->{'DISPATCHER'}->mount( File::Spec->catdir( File::Spec->rootdir(), 'perl' ), $_[HEAP]->{'PERLFS'} );
	$_[HEAP]->{'DISPATCHER'}->mount( File::Spec->catdir( File::Spec->rootdir(), 'kernel' ), $_[HEAP]->{'POEFS'} );
	$_[HEAP]->{'DISPATCHER'}->mount( File::Spec->catdir( File::Spec->rootdir(), 'modules' ), $_[HEAP]->{'MODULEFS'} );
	if ( defined $_[HEAP]->{'MISCFS'} ) {
		$_[HEAP]->{'DISPATCHER'}->mount( File::Spec->catdir( File::Spec->rootdir(), 'misc' ), $_[HEAP]->{'MISCFS'} );
	}

	# spawn the fuse poco
	POE::Component::Fuse->spawn(
		'umount'	=> 1,
		'mkdir'		=> 1,
		'mount'		=> "/tmp/poefuse_$$",
		'rmdir'		=> 1,
		( defined $_[HEAP]->{'FUSEOPTS'} ? %{ $_[HEAP]->{'FUSEOPTS'} } : () ),

		# make sure the user cannot override those options
		'alias'		=> $_[HEAP]->{'ALIAS'} . '-fuse',
		'vfilesys'	=> $_[HEAP]->{'DISPATCHER'},
		'session'	=> $_[SESSION]->ID,
	);

	return;
}

# POE Handlers
sub _stop : State {
	if ( DEBUG ) {
		warn 'Stopping alias "' . $_[HEAP]->{'ALIAS'} . '"';
	}

	return;
}

sub shutdown : State {
	# cleanup some stuff
	$_[KERNEL]->alias_remove( $_[HEAP]->{'ALIAS'} );

	# tell poco-fuse to shutdown
	$_[KERNEL]->post( $_[HEAP]->{'ALIAS'} . '-fuse', 'shutdown' );

	return;
}

# handles poco-fuse shutting down
sub fuse_CLOSED : State {
	$_[KERNEL]->yield( 'shutdown' );

	return;
}

# adds a poco to the fs
sub register : State {
	my $fsv = $_[ARG0];

	# determine caller info
	my $module = ( caller(4) )[0];
	if ( $module eq 'POE::Kernel' ) {
		# we were not dispatched via call(), complain!
		warn "Registering a module must be done via call() not post()";
		return;
	}

	# Weed out modules that we know is unable to register
	if ( $module eq 'main' ) {
		warn "Unable to register from package 'main' because it is ambiguous, please do so from a proper package";
		return;
	}

	# is the fsv a valid object?
	if ( ! defined $fsv or ! ref $fsv or ! $fsv->isa( 'Filesys::Virtual::Async' ) ) {
		warn "The FsV object is not a valid subclass of Filesys::Virtual::Async";
		return;
	}

	# Try to register the module!
	my $result = $_[HEAP]->{'MODULEFS'}->register( $module );
	if ( defined $result ) {
		# successfully registered, add it to the dispatcher!
		$_[HEAP]->{'DISPATCHER'}->mount( File::Spec->catdir( File::Spec->rootdir(), 'modules', $result ), $fsv );
		return 1;
	} else {
		warn "The package '$module' is already registered";
		return;
	}
}

# removes a poco from the fs
sub unregister : State {
	# determine caller info
	my $module = ( caller(4) )[0];
	if ( $module eq 'POE::Kernel' ) {
		# we were not dispatched via call(), complain!
		warn "Unregistering a module must be done via call() not post()";
		return;
	}

	# Weed out modules that we know is unable to register
	if ( $module eq 'main' ) {
		warn "Unable to register from package 'main' because it is ambiguous, please do so from a proper package";
		return;
	}

	# Try to register the module!
	my $result = $_[HEAP]->{'MODULEFS'}->unregister( $module );
	if ( defined $result ) {
		# successfully unregistered, remove it from the dispatcher!
		$_[HEAP]->{'DISPATCHER'}->umount( File::Spec->catdir( File::Spec->rootdir(), 'modules', $result ) );
		return 1;
	} else {
		warn "The package '$module' was never registered";
		return;
	}
}

1;
__END__

=head1 NAME

POE::Devel::ProcAlike - Exposing the guts of POE via FUSE

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict; use warnings;
	use POE::Devel::ProcAlike;
	use POE;

	# let it do the work!
	POE::Devel::ProcAlike->spawn();

	# create our own "fake" session
	POE::Session->spawn(
		'inline_states'	=> {
			'_start'	=> sub {
				$_[KERNEL]->alias_set( 'foo' );
				$_[KERNEL]->yield( 'timer' );
			},
			'timer'		=> sub {
				$_[KERNEL]->delay_set( 'timer' => 60 );
			}
		},
		'heap'		=> {
			'fakedata'	=> 1,
			'oomph'		=> 'haha',
		},
	);

	# run the kernel!
	POE::Kernel->run();

=head1 ABSTRACT

Using this module will let you expose the guts of a running POE program to the filesystem via FUSE. This also
includes a lot of debugging information about the running perl process :)

=head1 DESCRIPTION

Really, all you have to do is load the module and call it's spawn() method:

	use POE::Devel::ProcAlike;
	POE::Devel::ProcAlike->spawn( ... );

This method will return failure on errors or return success. Normally you don't need to pass any arguments to it,
but if you want to do zany things, you can! Note: the spawn() method will construct a singleton.

This constructor accepts either a hashref or a hash, valid options are:

=head3 fuseopts

This is a hashref of options to pass to the underlying FUSE component, L<POE::Component::Fuse>'s spawn() method. Useful
to change the default mountpoint, for example. Setting the mountpoint is a MUST if you have multiple scripts running
and want to use this.

The default fuseopts is to enable: umount, mkdir, rmdir, and mountpoint of "/tmp/poefuse_$$". You cannot override those
options: alias, vfilesys, and session.

The default is: undef

=head3 vfilesys

This is a L<Filesys::Virtual::Async> subclass object you can provide to expose your own data in the filesystem. It
will be mounted under /misc in the directory.

The default is: undef

=head2 Commands

There is only a few commands you can use, because this module does nothing except export the data to the filesystem.

This module uses a static alias: "poe-devel-procalike" so you can always interact with it anytime it is loaded.

=head3 shutdown

Tells this module to shut down the underlying FUSE session and terminate itself.

	$_[KERNEL]->post( 'poe-devel-procalike', 'shutdown' );

=head3 register

( ONLY for PoCo module authors! )

Registers your L<Filesys::Virtual::Async> subclass with ProcAlike so you can expose your data in the filesystem.

Note: You MUST call() this event so ProcAlike will get the proper caller() info to determine mountpath. Furthermore,
ProcAlike only allows one registration per module!

	$_[KERNEL]->call( 'poe-devel-procalike', 'register', $myfsv );

=head3 unregister

( ONLY for PoCo module authors! )

Removes your registered object from the filesystem.

Note: You MUST call() this event so ProcAlike will get the proper caller() info to determine mountpath.

	$_[KERNEL]->call( 'poe-devel-procalike', 'unregister' );

=head2 Notes for PoCo module authors

You can expose your own data in any format you want! The way to do this is to create your own L<Filesys::Virtual::Async>
object and give it to ProcAlike. Here's how I would do the logic:

	my $ses = $_[KERNEL]->alias_resolve( 'poe-devel-procalike' );
	if ( $ses ) {
		require My::FsV; # a subclass of Filesys::Virtual::Async
		my $fsv = My::FsV->new( ... );
		if ( ! $_[KERNEL]->call( $ses, 'register', $fsv ) ) {
			warn "unable to register!";
		}
	}

Keep in mind that the alias is static, and you should be executing this code in the "preferred" package. What I mean
by this is that ProcAlike will take the info from caller() and determine the mountpoint from it. Here's an example:

	POE::Component::SimpleHTTP does a register, it will be mounted in:
	/modules/poe-component-simplehttp

	My::Module::SubClass does a register, it will be mounted in:
	/modules/my-module-subclass

Furthermore, ProcAlike only allows each package to register once, so you have to figure out how to create a singleton
and use that if your PoCo has been spawned N times. The reasoning behind this is to have a "uniform" filesystem
that would be valid across multiple invocations. If we allowed module authors to register any name, then we would
end up with possible collisions and wacky schemes like "$pkg$ses->ID" as the name...

Also, here's a tip: you don't have to implement the entire L<Filesys::Virtual::Async> API because FUSE doesn't use
them all! The ones you would have to do is: rmtree, scandir, move, copy, load, readdir, rmdir, mkdir, rename, mknod,
unlink, chmod, truncate, chown, utime, stat, write, open. To save even more time, you can subclass the
L<Filesys::Virtual::Async::inMemory> module and set readonly to true. Then you would have to subclass only those
methods: readdir, stat, open.

=head2 TODO

=over 4

=item * tunable parameters

Various people in #poe@magnet suggested having a system where we could do "sysctl-like" stuff with this filesystem.
I'm not entirely sure what we can "tune" in regards to POE but if you have any ideas please feel free to drop them
my way and we'll see what we can do :)

=item * pipe support

Again, people suggested the idea of "telnetting" into the filesystem via a pipe. The interface could be something
like PoCo-DebugShell, and we could expand it to accept zany commands :)

=item * module memory usage

I talked with some people, and this problem is much more complex than you would think it is. If somebody could
let me know of a snippet that measures this, I would love to include it in the perl output!

=item * POE::API::Peek crashes

There are some functions that causes segfaults for me! They are: session_memory_size, signals_watched_by_session, and
kernel_memory_size. If the situation improves, I would love to reinstate them in ProcAlike and expose the data, so
please let me know if it does.

=item * more stats

More stats are always welcome! If you have any ideas, please drop me a line.

=back

=head1 EXPORT

None.

=head1 SEE ALSO

L<POE>

L<Fuse>

L<Filesys::Virtual::Async>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Devel::ProcAlike

=head2 Websites

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Devel-ProcAlike>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Devel-ProcAlike>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Devel-ProcAlike>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Devel-ProcAlike>

=back

=head2 Bugs

Please report any bugs or feature requests to C<bug-poe-devel-procalike at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Devel-ProcAlike>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to xantus who got me motivated to write this :)

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
