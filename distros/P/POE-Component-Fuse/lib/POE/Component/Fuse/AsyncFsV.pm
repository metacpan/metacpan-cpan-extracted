# Declare our package
package POE::Component::Fuse::AsyncFsV;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.05';

# load the aio helper
use POE::Component::AIO { no_auto_bootstrap => 1, no_auto_export => 1 };

# we need access to the kernel
use POE;

# constants we need to interact with FUSE
use Errno qw( :POSIX );   	# ENOENT EISDIR etc
use Fcntl qw( :DEFAULT :mode );	# S_IFREG S_IFDIR, O_SYNC O_LARGEFILE etc

# get the refaddr of our FHs
use Scalar::Util qw( openhandle );

# creates a new instance
sub new {
	my $class = shift;
	my $fsv   = shift;

	# init PoCo-AIO
	POE::Component::AIO->new();

	# Create our obj and return it
	return bless {
		'fsv'	=> $fsv,
		'fhmap'	=> {},
	}, $class;
}

# shutdown PoCo-AIO
sub DESTROY {
	POE::Component::AIO->new()->shutdown();

	return;
}

# simple accessor
sub fsv {
	return shift->{'fsv'};
}

# simple callback that returns 0 for FUSE
sub _cb {
	my( $self, $name ) = @_;

	# make our custom wrapper
	my $cb = $poe_kernel->get_active_session->postback( 'reply', $name );
	my $callback = sub {
		if ( defined $_[0] ) {
			# IO::AIO returns 0 as successful...
			if ( $_[0] == 0 ) {
				# FUSE needs 0 as retval
				$cb->( 0 );
			} else {
				# error code
				$cb->( $_[0] );
			}
		} else {
			$cb->( -EINVAL() );
		}
	};

	return $callback;
}

sub getattr {
	my ( $self, $context, $path ) = @_;

	# make a special wrapper
	my $cb = $poe_kernel->get_active_session->postback( 'reply', 'getattr' );
	my $callback = sub {
		if ( defined $_[0] ) {
			if ( ref $_[0] ) {
				$cb->( @{ $_[0] } );
			} else {
				# error code
				$cb->( $_[0] );
			}
		} else {
			# not found
			$cb->( -ENOENT() );
		}
	};

	$self->fsv->stat( $path, $callback );
	return;
}

sub getdir {
	my ( $self, $context, $path ) = @_;

	# make a special wrapper
	my $cb = $poe_kernel->get_active_session->postback( 'reply', 'getdir' );
	my $callback = sub {
		if ( defined $_[0] ) {
			if ( ref $_[0] ) {
				# FUSE needs 0 at the end of list to signify success
				$cb->( @{ $_[0] }, 0 );
			} else {
				# error code or empty list = 0
				$cb->( $_[0] );
			}
		} else {
			$cb->( -EINVAL() );
		}
	};

	$self->fsv->readdir( $path, $callback );
	return;
}

sub getxattr {
	my ( $self, $context, $path, $attr ) = @_;

	# we don't have any extended attribute support
	$poe_kernel->yield( 'reply', [ 'getxattr' ], [ 0 ] );
	return;
}

sub setxattr {
	my ( $self, $context, $path, $attr, $value, $flags ) = @_;

	# we don't have any extended attribute support
	$poe_kernel->yield( 'reply', [ 'setxattr' ], [ -ENOSYS() ] );
	return;

}

sub listxattr {
	my ( $self, $context, $path ) = @_;

	# we don't have any extended attribute support
	$poe_kernel->yield( 'reply', [ 'listxattr' ], [ 0 ] );
	return;
}

sub removexattr {
	my ( $self, $context, $path, $attr ) = @_;

	# we don't have any extended attribute support
	$poe_kernel->yield( 'reply', [ 'removexattr' ], [ -ENOSYS() ] );
	return;
}

sub open {
	my ( $self, $context, $path, $flags ) = @_;

	# make a special wrapper
	my $cb = $poe_kernel->get_active_session->postback( 'reply', 'open', $context );
	my $callback = sub {
		my $fh = shift;
		if ( defined $fh ) {
			if ( openhandle( $fh ) ) {
				# arg, generate our own ID
				my $id = 0;
				1 while exists $self->{'fhmap'}->{ ++$id };
				$self->{'fhmap'}->{ $id } = $fh;
				$context->{'fh'} = $id;
				$cb->( 0 );
			} else {
				# error code
				$cb->( $fh );
			}
		} else {
			$cb->( -EIO() );
		}
	};

	# figure out the mode and set it
	# FIXME we use 0666 as default, should we change this or something?
	my $mode = 0;
	if ( $flags & O_CREAT ) {
		$mode = oct( 666 );
	}

	# actually open it!
	$self->fsv->open( $path, $flags, $mode, $callback );
	return;
}

sub read {
	my ( $self, $context, $path, $len, $offset ) = @_;

	# get the fh
	my $fh = undef;
	if ( exists $self->{'fhmap'}->{ $context->{'fh'} } ) {
		$fh = $self->{'fhmap'}->{ $context->{'fh'} };
	}

	if ( ! defined $fh ) {
		$poe_kernel->yield( 'reply', [ 'read' ], [ -EINVAL() ] );
	} else {
		# make our custom wrapper
		my $cb = $poe_kernel->get_active_session->postback( 'reply', 'read' );
		my $buf = '';
		my $callback = sub {
			if ( ! defined $_[0] ) {
				$cb->( -EIO() );
			} else {
				$cb->( $buf );
			}
		};

		# aio_read $fh,$offset,$length, $data,$dataoffset, $callback->($retval)
		$self->fsv->read( $fh, $offset, $len, $buf, 0, $callback );
	}

	return;
}

sub flush {
	my ( $self, $context, $path ) = @_;

	# get the fh
	my $fh = undef;
	if ( exists $self->{'fhmap'}->{ $context->{'fh'} } ) {
		$fh = $self->{'fhmap'}->{ $context->{'fh'} };
	}

	if ( ! defined $fh ) {
		$poe_kernel->yield( 'reply', [ 'flush' ], [ -EINVAL() ] );
	} else {
		# we map flush to fsync and hope all will be well :)
		$self->fsv->fsync( $fh, $self->_cb( 'flush' ) );
	}

	return;
}

sub release {
	my ( $self, $context, $path, $flags ) = @_;

	# get the fh
	my $fh = undef;
	if ( exists $self->{'fhmap'}->{ $context->{'fh'} } ) {
		$fh = $self->{'fhmap'}->{ $context->{'fh'} };
	}

	# FUSE sometimes calls release multiple times per file
	if ( ! defined $fh ) {
		# assume success
		$poe_kernel->yield( 'reply', [ 'release' ], [ 0 ] );
	} else {
		# make our custom wrapper
		my $cb = $poe_kernel->get_active_session->postback( 'reply', 'release' );
		my $callback = sub {
			# IO::AIO returns 0 as successful close...
			if ( $_[0] == 0 ) {
				# get rid of our mapping
				if ( exists $self->{'fhmap'}->{ $context->{'fh'} } ) {
					delete $self->{'fhmap'}->{ $context->{'fh'} };
				}

				# FUSE needs 0 as retval
				$cb->( 0 );
			} else {
				$cb->( $_[0] );
			}
		};

		$self->fsv->close( $fh, $callback );
	}

	return;
}

sub truncate {
	my ( $self, $context, $path, $offset ) = @_;

	$self->fsv->truncate( $path, $offset, $self->_cb( 'truncate' ) );
	return;
}

sub write {
	my ( $self, $context, $path, $buffer, $offset ) = @_;

	# get the fh
	my $fh = undef;
	if ( exists $self->{'fhmap'}->{ $context->{'fh'} } ) {
		$fh = $self->{'fhmap'}->{ $context->{'fh'} };
	}

	if ( ! defined $fh ) {
		$poe_kernel->yield( 'reply', [ 'write' ], [ -EINVAL() ] );
	} else {
		# make a special wrapper
		my $cb = $poe_kernel->get_active_session->postback( 'reply', 'write' );
		my $callback = sub {
			if ( defined $_[0] ) {
				$cb->( $_[0] );
			} else {
				# error
				$cb->( -EIO() );
			}
		};

		# aio_write $fh,$offset,$length, $data,$dataoffset, $callback->($retval)
		$self->fsv->write( $fh, $offset, length( $buffer ), $buffer, 0, $callback );
	}

	return;
}

sub mknod {
	my ( $self, $context, $path, $modes, $device ) = @_;

	$self->fsv->mknod( $path, $modes, $device, $self->_cb( 'mknod' ) );
	return;
}

sub mkdir {
	my ( $self, $context, $path, $modes ) = @_;

	$self->fsv->mkdir( $path, $modes, $self->_cb( 'mkdir' ) );
	return;
}

sub unlink {
	my ( $self, $context, $path ) = @_;

	$self->fsv->unlink( $path, $self->_cb( 'unlink' ) );
	return;
}

sub rmdir {
	my ( $self, $context, $path ) = @_;

	$self->fsv->rmdir( $path, $self->_cb( 'rmdir' ) );
	return;
}

sub symlink {
	my ( $self, $context, $path, $symlink ) = @_;

	$self->fsv->symlink( $path, $symlink, $self->_cb( 'symlink' ) );
	return;
}

sub rename {
	my ( $self, $context, $path, $newpath ) = @_;

	$self->fsv->rename( $path, $newpath, $self->_cb( 'rename' ) );
	return;
}

sub link {
	my ( $self, $context, $path, $hardlink ) = @_;

	$self->fsv->link( $path, $hardlink, $self->_cb( 'link' ) );
	return;
}

sub chmod {
	my ( $self, $context, $path, $modes ) = @_;

	$self->fsv->chmod( $path, $modes, $self->_cb( 'chmod' ) );
	return;
}

sub chown {
	my ( $self, $context, $path, $uid, $gid ) = @_;

	$self->fsv->chown( $path, $uid, $gid, $self->_cb( 'chown' ) );
	return;
}

sub utime {
	my ( $self, $context, $path, $atime, $mtime ) = @_;

	$self->fsv->utime( $path, $atime, $mtime, $self->_cb( 'utime' ) );
	return;
}

sub fsync {
	my ( $self, $context, $path, $fsync_mode ) = @_;

	# get the fh
	my $fh = undef;
	if ( exists $self->{'fhmap'}->{ $context->{'fh'} } ) {
		$fh = $self->{'fhmap'}->{ $context->{'fh'} };
	}

	if ( ! defined $fh ) {
		$poe_kernel->yield( 'reply', [ 'fsync' ], [ -EINVAL() ] );
	} else {
		# interesting, ::Async don't care about $fsync_mode...
		$self->fsv->fsync( $fh, $self->_cb( 'fsync' ) );
	}

	return;
}

sub statfs {
	my( $self, $context ) = @_;

	# FIXME fake the data...
	# $namelen, $files, $files_free, $blocks, $blocks_avail, $blocksize
	$poe_kernel->yield( 'reply', [ 'statfs' ], [ 255, 1, 1, 1, 1, 2 ] );
	return;
}

1;
__END__

=head1 NAME

POE::Component::Fuse::AsyncFsV - Wrapper for Filesys::Virtual::Async

=head1 SYNOPSIS

  Please do not use this module directly.

=head1 ABSTRACT

Please do not use this module directly.

=head1 DESCRIPTION

This module is responsible for "wrapping" L<Filesys::Virtual::Async> objects and making them communicate properly
with the FUSE API that L<POE::Component::Fuse> exposes. Please do not use this module directly.

=head1 EXPORT

None.

=head1 SEE ALSO

L<POE::Component::Fuse>

L<Filesys::Virtual::Async>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to xantus who wrote the L<Filesys::Virtual::Async> module!

Inspiration was taken from the L<Fuse::Filesys::Virtual> module too.

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
