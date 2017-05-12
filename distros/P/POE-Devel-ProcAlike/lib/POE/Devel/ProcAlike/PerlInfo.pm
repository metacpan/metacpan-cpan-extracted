# Declare our package
package POE::Devel::ProcAlike::PerlInfo;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.02';

# Set our superclass
use base 'Filesys::Virtual::Async::inMemory';

# portable tools
use File::Spec;

sub new {
	# make sure we set a readonly filesystem!
	return __PACKAGE__->SUPER::new(
		'readonly'	=> 1,
	);
}

#/perl
#	# place for generic perl data
#
#	binary		# $^X
#	version		# $^V
#	pid		# $$
#	script		# $0
#	osname		# $^O
#	starttime	# $^T
#
#	inc		# dumps the @inc array
#
#	/env
#		# dumps the %ENV hash
#
#		PWD	# data is $ENV{PWD}
#		...
#
#	/modules
#		# lists all loaded modules
#
#		/Foo-Bar
#			# module name will be converted to above format
#
#			version		# $module->VERSION ||= 'UNDEF'
#			path		# module's path in %INC
my %fs = (
	'binary'	=> $^X . "\n",
	'version'	=> "$^V\n",
	'pid'		=> $$ . "\n",
	'script'	=> $0 . "\n",
	'osname'	=> $^O . "\n",
	'starttime'	=> $^T . "\n",
	'inc'		=> join( "\n", @INC ) . "\n",

	'env'		=> \&manage_env,

	'modules'	=> \&manage_modules,
);

# helper to get loaded modules
sub _get_loadedmodules {
	my @list = grep { $_ !~ /(?:al|ix)$/ } keys %INC;	# remove those annoying non-module files
	for ( @list ) {
		s/\.pm$//;					# remove trailing .pm
		$_ = join( '-', File::Spec->splitdir( $_ ) );	# convert "/" into "-" ( portably )
	}

	return \@list;
}

sub _get_module_metrics {
	return [ qw( version path ) ];
}

sub _get_module_metric {
	my $incpath = shift;
	my $module = shift;
	my $metric = shift;

	# what metric?
	if ( $metric eq 'version' ) {
		my $size = join( '::', split( '-', $module ) );

		## no critic
		$size = eval "$size->VERSION";
		## use critic

		if ( defined $size ) {
			return $size . "\n";
		} else {
			return 'UNDEF' . "\n";
		}
	} elsif ( $metric eq 'path' ) {
		return $INC{ $incpath } . "\n";
	} else {
		die "unknown module metric: $metric\n";
	}
}

sub manage_modules {
	my( $type, @path ) = @_;

	# what's the operation?
	if ( $type eq 'readdir' ) {
		# trying to read the root or the module itself?
		if ( defined $path[0] ) {
			# shortcut, because we always know what's in the module dir
			return _get_module_metrics();
		} else {
			# list all loaded modules
			return _get_loadedmodules();
		}
	} elsif ( $type eq 'stat' ) {
		# set some default data
		my ($atime, $ctime, $mtime, $size, $modes);
		$atime = $ctime = $mtime = time();
		my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = ( 0, 0, 0, 1, (split( /\s+/, $) ))[0], $>, 1, 1024 );

		# trying to stat the dir or stuff inside it?
		if ( defined $path[0] ) {
			# convert it back to %INC type
			my $incpath = join( '/', split( '-', $path[0] ) ) . '.pm';

			# does it exist?
			if ( ! exists $INC{ $incpath } ) {
				return;
			}

			# trying to stat the module or data inside it?
			if ( defined $path[1] ) {
				# valid filename?
				if ( ! grep { $_ eq $path[1] } @{ _get_module_metrics() } or defined $path[2] ) {
					return;
				}

				$modes = oct( '100644' );

				# get the data
				$size = length( _get_module_metric( $incpath, $path[0], $path[1] ) );
			} else {
				# a directory, munge the data
				$size = 0;
				$modes = oct( '040755' );
				$nlink = 2;
			}
		} else {
			# a directory, munge the data
			$size = 0;
			$modes = oct( '040755' );
			$nlink = 2 + scalar @{ _get_loadedmodules() };
		}

		# finally, return the darn data!
		return( [ $dev, $ino, $modes, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks ] );
	} elsif ( $type eq 'open' ) {
		# convert it back to %INC type
		my $incpath = join( '/', split( '-', $path[0] ) ) . '.pm';

		# does it exist?
		if ( ! exists $INC{ $incpath } or ! defined $path[1] ) {
			return;
		}

		# valid filename?
		if ( ! grep { $_ eq $path[1] } @{ _get_module_metrics() } or defined $path[2] ) {
			return;
		}

		# get the metric!
		my $data = _get_module_metric( $incpath, $path[0], $path[1] );
		return \$data;
	}
}

sub manage_env {
	my( $type, @path ) = @_;

	# what's the operation?
	if ( $type eq 'readdir' ) {
		# we don't have any subdirs so simply return the entire hash!
		return [ keys %ENV ];
	} elsif ( $type eq 'stat' ) {
		# set some default data
		my ($atime, $ctime, $mtime, $size, $modes);
		$atime = $ctime = $mtime = time();
		my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = ( 0, 0, 0, 1, (split( /\s+/, $) ))[0], $>, 1, 1024 );

		# trying to stat the dir or stuff inside it?
		if ( defined $path[0] ) {
			# does it exist?
			if ( ! exists $ENV{ $path[0] } or defined $path[1] ) {
				return;
			}

			# a file, munge the data
			$size = length( $ENV{ $path[0] } . "\n" );
			$modes = oct( '100644' );
		} else {
			# a directory, munge the data
			$size = 0;
			$modes = oct( '040755' );
			$nlink = 2;
		}

		# finally, return the darn data!
		return( [ $dev, $ino, $modes, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks ] );
	} elsif ( $type eq 'open' ) {
		# return a scalar ref
		if ( exists $ENV{ $path[0] } ) {
			my $data = $ENV{ $path[0] } . "\n";
			return \$data;
		} else {
			return;
		}
	}
}

# we cheat here and not implement a lot of stuff because we know the FUSE api never calls the "extra" APIs
# that ::Async provides. Furthermore, this is a read-only filesystem so we can skip even more APIs :)

# _rmtree

# _scandir

# _move

# _copy

# _load

sub _readdir {
	my( $self, $path ) = @_;

	if ( $path eq File::Spec->rootdir() ) {
		return [ keys %fs ];
	} else {
		# sanitize the path
		my @dirs = File::Spec->splitdir( $path );
		shift( @dirs ); # get rid of the root entry which is always '' for me
		return $fs{ $dirs[0] }->( 'readdir', @dirs[ 1 .. $#dirs ] );
	}
}

# _rmdir

# _mkdir

# _rename

# _mknod

# _unlink

# _chmod

# _truncate

# _chown

# _utime

sub _stat {
	my( $self, $path ) = @_;

	# stating the root?
	if ( $path eq File::Spec->rootdir() ) {
		my ($atime, $ctime, $mtime, $size, $modes);
		$atime = $ctime = $mtime = time();
		my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = ( 0, 0, 0, 1, (split( /\s+/, $) ))[0], $>, 1, 1024 );
		$size = 0;
		$modes = oct( '040755' );

		# count subdirs
		$nlink = 2 + grep { ref $fs{ $_ } } keys %fs;

		return( [ $dev, $ino, $modes, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks ] );
	}

	# sanitize the path
	my @dirs = File::Spec->splitdir( $path );
	shift( @dirs ); # get rid of the root entry which is always '' for me

	if ( exists $fs{ $dirs[0] } ) {
		# directory or file?
		if ( ref $fs{ $dirs[0] } ) {
			# trying to stat the dir or the subpath?
			return $fs{ $dirs[0] }->( 'stat', @dirs[ 1 .. $#dirs ] );
		} else {
			# arg, stat is a finicky beast!
			my $size = length( $fs{ $dirs[0] } );
			my $modes = oct( '100644' );

			my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = ( 0, 0, 0, 1, (split( /\s+/, $) ))[0], $>, 1, 1024 );
			my ($atime, $ctime, $mtime);
			$atime = $ctime = $mtime = time();

			return( [ $dev, $ino, $modes, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks ] );
		}
	} else {
		return;
	}
}

# _write

sub _open {
	my( $self, $path ) = @_;

	# sanitize the path
	my @dirs = File::Spec->splitdir( $path );
	shift( @dirs ); # get rid of the root entry which is always '' for me
	if ( defined $dirs[0] and exists $fs{ $dirs[0] } ) {
		# directory or file?
		if ( ref $fs{ $dirs[0] } ) {
			return $fs{ $dirs[0] }->( 'open', @dirs[ 1 .. $#dirs ] );
		} else {
			# return a scalar ref
			return \$fs{ $dirs[0] };
		}
	} else {
		return;
	}
}

1;
__END__

=head1 NAME

POE::Devel::ProcAlike::PerlInfo - Manages the perl data in ProcAlike

=head1 SYNOPSIS

  Please do not use this module directly.

=head1 ABSTRACT

Please do not use this module directly.

=head1 DESCRIPTION

This module is responsible for exporting the perl data in ProcAlike.

=head1 EXPORT

None.

=head1 SEE ALSO

L<POE::Devel::ProcAlike>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut