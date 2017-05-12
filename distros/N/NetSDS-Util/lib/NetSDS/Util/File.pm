#===============================================================================
#
#         FILE:  File.pm
#
#  DESCRIPTION:  NetSDS utilities for file operations
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.044
#      CREATED:  16.07.2008 18:25:48 EEST
#===============================================================================

=head1 NAME

NetSDS::Util::File - file related utilities

=head1 SYNOPSIS

	use NetSDS::Util::File qw(file_read);

	my $passwd = file_read('/etc/passwd');

	file_move('/etc/passwd', '/tmp/find_this');

=head1 DESCRIPTION

C<NetSDS::Util::File> module contains some routines for files
and directories processing tasks like creating, reading, writing,
copying and moving files and catalogs.

This module of cource uses such well known things like L<File::Spec>,
L<File::Path>, L<File::Copy> and others.

=cut

package NetSDS::Util::File;

use 5.8.0;
use strict;
use warnings;

use POSIX;
use File::Spec;
use File::Copy;
use File::Path;
use File::Temp ();

use base 'Exporter';

use version; our $VERSION = "1.044";
our @EXPORT = qw(
  is_handle
  reset_handle
  file_open
  file_read
  file_write
  file_copy
  file_move
  file_temp
  dir_create
  dir_delete
  dir_read
  dir_read_recursive
  exec_external
);

#***********************************************************************

=head1 EXPORTED FUNCTIONS

=over

=item B<is_handle($var)> - check if argument is a file handle

Paramters: some variable

Returns: 1 if it's file handle or undef otherwise

	if (is_handle($var)) {

		reset_handle($fh);

	}

=cut 

#-----------------------------------------------------------------------

sub is_handle {
	my ( $fh, @list ) = @_;

	push( @list, qw(IO::Scalar IO::Handle GLOB) );
	foreach my $class (@list) {
		if ( UNIVERSAL::isa( $fh, $class ) ) {
			return 1;
		}
	}

	return 0;
}

#***********************************************************************

=item B<reset_handle($fh)> - reset file handle

Paramters: file handle

Returns: nothing

This function tries to set filehandle to begin of file and set binmode on it.

	my $fh = file_open('/etc/passwd');
	...
	do something with file
	...
	reset_handle($fh); # We can read it from the beginning

=cut 

#-----------------------------------------------------------------------

sub reset_handle {
	my ($fh) = @_;

	if ( $fh->can('binmode') ) {
		$fh->binmode;
	} else {
		binmode($fh);
	}

	if ( $fh->can('seek') ) {
		$fh->seek( 0, 0 );
	}
}

#***********************************************************************

=item B<file_open($file)> - open file

Paramters: file name or file handle

Returns: file handle

This function provides unified API for opening files.

	my $f = file_open('/etc/passwd');

=cut 

#-----------------------------------------------------------------------

sub file_open {
	my $fil = shift;

	my $fh;
	my $st = 1;
	if ( ref($fil) ) {
		if ( is_handle($fil) ) {
			$fh = $fil;
		} else {
			require IO::File;
			$fh = IO::File->new;
			$st = $fh->fdopen( $fil, @_ );
		}
	} else {
		require IO::File;
		$fh = IO::File->new;
		$st = $fh->open( $fil, @_ );
	}

	if ($st) {
		reset_handle($fh);
	} else {
		return undef;
	}

	return $fh;
} ## end sub file_open

#***********************************************************************

=item B<file_read($file)> - read file to scalar

Paramters: file name or file handle

Returns: scalar content of file

This function provides ability to read file content to scalar variable.

	my $data = file_read('/etc/passwd');

	print "Passwords file: $data\n";

=cut 

#-----------------------------------------------------------------------

sub file_read {
	my $fil = shift;

	my $bin = undef;

	my $fh = file_open( $fil, ( scalar(@_) > 0 ) ? @_ : 'r' );

	if ( defined($fh) ) {
		local $/ = undef;
		$bin = <$fh>;
		$fh->close;
		$/ = "\n";
	}

	return $bin;
}

#***********************************************************************

=item B<file_write($file, $data)> - write scalar data to file

Paramters: file name or open file handle

Returns: length of written data or undef in case of error

	my $data = 'This should be file';

	file_write('/tmp/file.dat', $data);

=cut 

#-----------------------------------------------------------------------

sub file_write {
	my $fil = shift;
	my $bin = shift;

	my $fh = file_open( $fil, ( scalar(@_) > 0 ) ? @_ : 'w+' );

	if ( defined($fh) ) {
		$fh->print($bin);
		$fh->close;
		return bytes::length($bin);
	} else {
		return undef;
	}
}

#***********************************************************************

=item B<file_copy($in_file, $out_file)> - copy file

Paramters: input file name, output file name

Returns: 

This function copy file to new location.

=cut 

#-----------------------------------------------------------------------

sub file_copy {
	my ( $ifl, $ofl ) = @_;

	if ( is_handle($ifl) ) {
		reset_handle($ifl);
	}

	if ( copy( $ifl, $ofl ) ) {
		return 1;
	} else {
		return undef;
	}
}

#***********************************************************************

=item B<file_move($in_file, $out_file)> - move file

Paramters: input file name, output file name

Returns: 1 or undef

This function moves old file to new location.

=cut 

#-----------------------------------------------------------------------

sub file_move {
	my ( $ifl, $ofl ) = @_;

	if ( is_handle($ifl) ) {
		reset_handle($ifl);
	}

	if ( move( $ifl, $ofl ) ) {
		return 1;
	} else {
		return undef;
	}
}

#***********************************************************************

=item B<file_temp($dir)> - create temporary file

Creates new temp file and return its handle

=cut 

#-----------------------------------------------------------------------

sub file_temp {

	my ($dir) = @_;

	my %params = ();
	if ($dir) { $params{DIR} = $dir; }

	my $fh = File::Temp->new(%params);

	return $fh;

}

#***********************************************************************

=item B<dir_create($dir)> - create directory with parents

Paramters: directory name

Returns: directory name or undef

	# Will create all parent catalogs if necessary

	dir_create('/var/log/NetSDS/xxx');

=cut 

#-----------------------------------------------------------------------

sub dir_create {
	my ( $dir, $mode ) = @_;
	$mode ||= 0777 & ~umask();

	my $ret = '';
	eval { $ret = mkpath( $dir, 0, $mode ); };
	if ($@) {
		return undef;
	}

	return $dir;
}

#***********************************************************************

=item B<dir_delete($dir)> - remove directory recursive

Paramters: directory name

Returns: dir name or undef if error

	print "We need no libs!";

	dir_delete('/usr/lib');

=cut 

#-----------------------------------------------------------------------

sub dir_delete {
	my ($dir) = @_;

	my $ret = '';
	eval { $ret = rmtree( $dir, 0, 1 ); };
	if ($@) {
		return undef;
	}

	return $dir;
}

#***********************************************************************

=item B<dir_read($dir, $ext)> - read files list from catalog

Paramters: directory name, extension of files to read

Returns: list of files in catalog

	my @logs = @{ dir_read('/var/log/httpd', 'log') };

	print "Logs are: " . join (', ', @logs);

=cut 

#-----------------------------------------------------------------------

sub dir_read {
	my ( $dir, $end ) = @_;

	if ( opendir( DIR, $dir ) ) {
		my @con =
		  ( defined($end) )
		  ? sort grep { $_ !~ m/^[.]{1,2}$/ and $_ =~ m/^.+\.$end$/i } readdir(DIR)
		  : sort grep { $_ !~ m/^[.]{1,2}$/ } readdir(DIR);

		closedir(DIR);

		return \@con;
	} else {
		return undef;
	}
}

#***********************************************************************

=item B<dir_read_recursive($dir, $ext, [$res])> - read all files list recursive

Paramters: $start catalog, $extension

Returns: list of files with extension from parameters

	my $tpls = dir_read_recursive('/etc/NetSDS', 'tmpl');

	foreach my $tpl (@$tpls) {

		pritn "Template: $tpl\n";

	}

=cut 

#-----------------------------------------------------------------------

sub dir_read_recursive {
	my ( $dir, $ext, $res ) = @_;
	$res ||= [];

	my $con = dir_read($dir);
	if ( defined($con) ) {
		foreach my $nam ( @{$con} ) {
			my $fil = "$dir/$nam";
			if ( -d $fil ) {
				dir_read_recursive( $fil, $ext, $res );
			} elsif ( $nam =~ m/^.+\.$ext$/i ) {
				push( @{$res}, $fil );
			}
		}

		return $res;
	} else {
		return undef;
	}
} ## end sub dir_read_recursive

#***********************************************************************

=item B<exec_external($prog, [$param1, ... $paramN])> - execute external program

Paramters: pragram name, arguments list (see perldoc -f system)

Returns: 1 if ok, undef otherwise

This function calls system() with given parameters and returns 1 if everything
happened correctly (program executed and returned correct result).

	if (exec_external('/bin/rm', '-rf', '/')) {

		print "Hey! We removed the world!";

	}

=cut 

#-----------------------------------------------------------------------

sub exec_external {

	my $rc = system(@_);

	if ( $rc == -1 ) {
		return undef;
	} elsif ( $rc & 127 ) {
		return undef;
	} else {
		my $cd = $rc >> 8;
		if ( $cd == 0 ) {
			return 1;
		} else {
			return undef;
		}
	}
}
#-----------------------------------------------------------------------

1;

__END__

=back

=head1 EXAMPLES

None yet

=head1 BUGS

Unknown yet

=head1 SEE ALSO

L<IO::Handle>, L<IO::Scalar>, L<IO::File>, L<File::Spec>, L<File::Copy>, L<File::Path>, L<system()>

=head1 TODO

1. Implement more detailed error handling

=head1 AUTHOR

Valentyn Solomko <pere@pere.org.ua>

Michael Bochkaryov <misha@rattler.kiev.ua>

=cut


