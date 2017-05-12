# Declare our package
package POE::Devel::ProcAlike::ModuleInfo;
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

#/modules
#	# place for modules to dump their info ( those who are aware of poe-devel-procalike )
#
#	/poe-component-server-simplehttp
#		# module name will be converted to above format
#		# allowed only one object per module, they can stuff any data they want in their area
my %fs = (
	# start with no modules loaded
);

# helper sub to munge package names
sub _mungepkg {
	my( $self, $pkg ) = @_;

	# change :: to -
	$pkg =~ s|::|-|g;

	# lowercase everything
	$pkg = lc( $pkg );

	# all done!
	return $pkg;
}

# adds a package
sub register {
	my( $self, $pkg ) = @_;

	# munge the package name to our "standard" format
	$pkg = $self->_mungepkg( $pkg );

	# sanity check
	if ( exists $fs{ $pkg } ) {
		return;
	}

	# yay, we can add the package!
	$fs{ $pkg } = 1;
	return 1;
}

# removes a package
sub unregister {
	my( $self, $pkg ) = @_;

	# munge the package name to our "standard" format
	$pkg = $self->_mungepkg( $pkg );

	# sanity check
	if ( ! exists $fs{ $pkg } ) {
		return;
	}

	# yay, we can remove the package!
	delete $fs{ $pkg };
	return 1;
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

	# return our modules
	return [ keys %fs ];
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

	# return generic info
	my ($atime, $ctime, $mtime, $size, $modes);
	$atime = $ctime = $mtime = time();
	my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = ( 0, 0, 0, 1, (split( /\s+/, $) ))[0], $>, 1, 1024 );
	$size = 0;
	$modes = oct( '040755' );

	# count subdirs
	$nlink = 2 + scalar keys %fs;

	return( [ $dev, $ino, $modes, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks ] );
}

# _write

sub _open {
	my( $self, $path ) = @_;

	# we don't have anything to open!
	return;
}

1;
__END__

=head1 NAME

POE::Devel::ProcAlike::ModuleInfo - Manages the PoCo module data in ProcAlike

=head1 SYNOPSIS

  Please do not use this module directly.

=head1 ABSTRACT

Please do not use this module directly.

=head1 DESCRIPTION

This module is responsible for managing the PoCo module data in ProcAlike.

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