package TUI::StdDlg::Util;
# ABSTRACT: defines utility functions used for Standard Dialogs

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT_OK = qw(
  fexpand
  driveValid
  isDir
  pathValid
  validFileName
  getCurDir
  getHomeDir
  isWild
);

our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
);

use Scalar::Util qw( readonly );
use TUI::toolkit qw(
  :boolean
  :utils
);
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::StdDlg::Const qw(
  DIRECTORY
  FA_DIREC
  :MAX
);
use TUI::StdDlg::Dos;    #  ffblk
use TUI::StdDlg::Dir qw(
  getcurdir
  getdisk
  findfirst
  fnmerge
  fnsplit
);

my (
  $skip,
  $squeeze,
  $isSep,
  $isHomeExpand,
  $isAbsolute,
  $addFinalSep,
  $getPathDrive,
);

$skip = sub {    # void ($src, $k)
  my ( $src, $k ) = @_;
  assert ( @_ == 2 );
  assert ( is_Str $src );
  assert ( is_Str $k );
  while ( length( $src ) && substr( $src, 0, 1 ) eq $k ) {
    substr( $src, 0, 1, '' );
  }
  $_[0] = $src;
  return;
};

$squeeze = sub {   # void ($path)
  my ( $path ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $path );
  assert ( not readonly $_[0] );

  my $dest = '';
  my $src  = $path;
  my $last = '';

  while ( length $src ) {
    if ( $last eq '\\' ) {
      &$skip( $src, '\\' );    # skip repeated '\'
    }
    if ( ( !$last || $last eq '\\' ) && substr( $src, 0, 1 ) eq '.' ) {
      substr( $src, 0, 1, '' );

      # have a '.' or '.\'
      if ( !length( $src ) || substr( $src, 0, 1 ) eq '\\' ) {
        &$skip( $src, '\\' );
      }

      # have a '..' or '..\'
      elsif ( substr( $src, 0, 1 ) eq '.'
        && ( length( $src ) == 1 || substr( $src, 1, 1 ) eq '\\' ) )
      {

        # skip the following '.'
        substr( $src, 0, 1, '' );
        &$skip( $src, '\\' );

        # back up to previous '\'
        substr( $dest, -1, 1, '' ) if length( $dest );

        # back up to previous '\'
        while ( length( $dest ) && substr( $dest, -1, 1 ) ne '\\' ) {
          substr( $dest, -1, 1, '' );
        }

        # move to the next position
        $last = length( $dest ) ? substr( $dest, -1, 1 ) : '';
      } #/ elsif ( substr( $src, 0, ...))
      else {
        # copy the '.' we just skipped
        $dest .= $last = '.';
      }
    } #/ if ( ( $last eq "\0" ||...))
    else {
      # copy first char from src to dest
      my $c = substr( $src, 0, 1, '' );
      $dest .= $c;
      $last = $c;
    }
  } #/ while ( length( $src ) )

  # Perl string needs no zero terminator
  $_[0] = $dest;
  return;
}; #/ sub squeeze_inplace

$isSep = sub {    # $bool ($c)  
  my ( $c ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $c );
  return ( $c eq '\\' || $c eq '/' );
};

$isHomeExpand = sub {   # $bool ($path)
  my ( $path ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $path );
  my @path = ( split( //, $path ), ('') x 2 )[ 0 .. 1 ];
  return $path[0] eq '~' && &$isSep( $path[1] );
};

$isAbsolute = sub {   # $bool ($path)
  my ( $path ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $path );
  my @path = ( split( //, $path ), ('') x 3 )[ 0 .. 2 ];
  return &$isSep( $path[0] ) 
      || ( $path[0] && $path[1] eq ':' && &$isSep( $path[2] ) );
};

$addFinalSep = sub {    # void ($path, $size)
  my ( $path, $size ) = @_;
  assert ( @_ == 2 );
  assert ( is_Str $path );
  assert ( is_Int $size );
  assert ( not readonly $_[0] );
  if ( $size < 1 && length( $path ) < $size ) {
    $path .= '\\';
    $_[0] = $path;
  }
  return;
};

$getPathDrive = sub {    # $int ($path)
  my ( $path ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $path );
  my @path = ( split( //, $path ), ('') x 2 )[ 0 .. 1 ];
  if ( $path[0] && $path[1] eq ':' ) {
    my $drive = ord( uc $path[0] ) - ord( 'A' );
    if ( 0 <= $drive && $drive <= ord( 'Z' ) - ord( 'A' ) ) {
      return $drive;
    }
  }
  return -1;
};

sub driveValid {    # $bool ($drive)
  state $sig = signature(
    pos => [Str],
  );
  my ( $drive ) = $sig->( @_ );
  $drive = uc( $drive );
  assert ( $drive =~ /^[A-Z]$/ );
  my $mask = 1 << ( ord( $drive ) - ord( 'A' ) );
  if ( $^O eq 'MSWin32' && eval { require Win32API::File; !$@ } ) {
    return ( Win32API::File::GetLogicalDrives() & $mask ) != 0;
  }
  my $path = "$drive:/";
  return -d $path;
}

sub isDir {    # $bool ($str)
  state $sig = signature(
    pos => [Str],
  );
  my ( $str ) = $sig->( @_ );
  my $ff = ffblk->new();
  return findfirst( $str, $ff, FA_DIREC ) == 0
      && ( $ff->ff_attrib() & FA_DIREC ) != 0;
}

sub pathValid {    # $bool ($path)
  state $sig = signature(
    pos => [Str],
  );
  my ( $path ) = $sig->( @_ );
  my $expPath = $path;
  fexpand( $expPath ); 
  my $len = length( $expPath );
  if ( $len <= 3 ) {
    return driveValid( substr( $expPath, 0, 1 ) );
  }

  $expPath =~ s/\\$//;
  
  return isDir( $expPath );
}

sub validFileName {    # $bool ($fileName)
  state $sig = signature(
    pos => [Str],
  );
  my ( $fileName ) = $sig->( @_ );

  state $illegalChars = qr/[;,=+<>|"\[\] \\]/;

  my $path = '';
  my $dir = '';
  my $name = '';
  my $ext = '';

  fnsplit( $fileName, $path, $dir, $name, $ext );
  $path .= $dir;
  return false 
    if $dir ne ''
    && !pathValid( $path );

  my $ext1 = $ext ne '' ? substr( $ext, 1 ) : '';
  return false
    if $name =~ $illegalChars
    || $ext1 =~ $illegalChars
    || index( $ext1, '.' ) != -1;

  return true;
}

sub getHomeDir {    # $bool ($drive, $dir)
  state $sig = signature(
    pos => [ Maybe[Str], Maybe[Str] ],
  );
  my ( $drive, $dir ) = $sig->( @_ );
  assert ( !defined or !readonly $_[0] );
  assert ( !defined or !readonly $_[1] );
  if ( $^O eq 'MSWin32' ) {
    my $homedrive = $ENV{"HOMEDRIVE"};
    my $homepath  = $ENV{"HOMEPATH"};
    if ( $homedrive && $homepath ) {
      if ( defined $drive ) {
        $_[0] = $drive = substr( $homedrive, 0, MAXDRIVE );
      }
      if ( defined $dir ) {
        $_[1] = $dir = substr( $homepath, 0, MAXDIR );
      }
      return true;
    }
  } 
  else {
    my $home = $ENV{"HOME"};
    if ( $home ) {
      if ( defined $drive ) {
        $_[0] = $drive = '';
      }
      if ( defined $dir ) {
        $_[1] = $dir = substr( $home, 0, MAXPATH );
      }
      return true;
    }
  }
  return false;
}

sub getCurDir {    # void ($dir, $drive)
  state $sig = signature(
    pos => [
      Str, 
      Int, { default => -1 },
    ],
  );
  my ( $dir, $drive ) = $sig->( @_ );
  assert ( not readonly $_[0] );
  $drive = getdisk() unless 0 <= $drive && $drive <= ord( 'Z' ) - ord( 'A' );
  $dir = chr( $drive + ord( 'A' ) ) . ':\\';
  getcurdir( $drive + 1, my $tmp );
  substr( $dir, 3 ) = $tmp;
  $dir .= '\\' if length $tmp;
  substr( $dir, MAXPATH ) = '' if length $dir > MAXPATH;
  $_[0] = $dir;
  return;
}

sub isWild {
  state $sig = signature(
    pos => [Str],
  );
  my ( $f ) = $sig->( @_ );
  return $f =~ /[?*]/;
}

sub fexpand {    # void ($rpath, |$relativeTo)
  state $sig = signature( 
    pos => [
      Str, 
      Str, { optional => 1 },
    ],
  );
  my ( $rpath, $relativeTo ) = $sig->( @_ );
  assert ( not readonly $_[0] );
  unless ( defined $relativeTo ) {
    $relativeTo = '';
    getCurDir( $relativeTo, &$getPathDrive($rpath) );
  }
  my $fn = {
    drive => '',
    dir   => '',
    file  => '',
    ext   => '',
  };
  my $path = '';

  my $drv;
  # Prioritize drive letter in 'rpath'.
  if ( ( $drv = &$getPathDrive( $rpath ) ) == -1 
    && ( $drv = &$getPathDrive( $relativeTo ) ) == -1 
  ) {
    $drv = getdisk();
  }
  $fn->{drive} = chr( ord('A') + $drv );
  $fn->{drive} .= ':';

  my $flags = fnsplit( $rpath, undef, $fn->{dir}, $fn->{file}, $fn->{ext} );
  if ( ( $flags & DIRECTORY ) == 0 || !&$isSep( substr $fn->{dir}, 0, 1 ) ) {
    my $rbase = '';
    if ( &$isHomeExpand( $fn->{dir} ) && getHomeDir( $fn->{drive}, $rbase ) ) {
      # Home expansion. Overwrite drive if necessary.
      # 'dir' begins with "~/" or "~\", so we can reuse the separator.
      $rbase .= substr( $fn->{dir}, 1 );
      $rbase = substr( $rbase, 0, MAXDIR ) if length $rbase > MAXDIR;
    }
    else {
      # If 'rpath' is relative but contains a drive letter, just swap drives.
      if ( &$getPathDrive( $rpath ) != -1 ) {
        if ( getcurdir( $drv + 1, $rbase ) != 0 ) {
          $rbase = '';
        }
      }
      else {
        # Expand 'relativeTo'.
        $rbase = substr( $relativeTo, 0, MAXPATH );
        if ( !&$isAbsolute( $rbase ) ) {
          my $curpath = '';
          getCurDir( $curpath, $drv );
          fexpand( $rbase, $curpath );
        }

        # Skip drive letter in 'rbase' (remove "C:")
        if ( &$getPathDrive( $rbase ) != -1 ) {
          substr( $rbase, 0, 2, '' );
        }
      }

      # Ensure 'rbase' ends with a separator.
      &$addFinalSep( $rbase, MAXPATH );
      $rbase .= $fn->{dir};
      $rbase = substr( $rbase, 0, MAXDIR ) if length $rbase > MAXDIR;
    } #/ else [ if ( &$isHomeExpand( $fn->{dir}...))]

    if ( !&$isSep( substr( $rbase, 0, 1 ) ) ) {
      $fn->{dir} = substr( '\\' . $rbase, 0, MAXDIR );
    }
    else {
      $fn->{dir} = substr( $rbase, 0, MAXDIR );
    }
  } #/ if ( ( ( $flags & $DIRECTORY...)))

  $fn->{dir} =~ tr{\/}{\\};
  &$squeeze( $fn->{dir} );
  fnmerge( $path, $fn->{drive}, $fn->{dir}, $fn->{file}, $fn->{ext} );
  # $path = uc $path;
  $_[0] = $rpath = substr( $path, 0, MAXPATH );
  return;
}

1

__END__

=pod

=head1 NAME

TUI::StdDlg::Util - utility functions for standard dialogs

=head1 SYNOPSIS

  use TUI::StdDlg::Util qw(
    driveValid
    fexpand
    getCurDir
    getHomeDir
    isDir
    isWild
    pathValid
    validFileName
  );

  my $ok = pathValid('/usr/local');
  my $abs = fexpand('docs', '/home/user');

=head1 DESCRIPTION

C<TUI::StdDlg::Util> provides a collection of helper functions used by Turbo
Vision standard dialogs to validate paths, filenames, and directories.

The functions in this module operate on strings and filesystem-related data and
do not maintain any internal state. They are intended to support file and
directory selection dialogs.

=head1 FUNCTIONS

=head2 driveValid

  my $bool = driveValid($drive);

Returns true if the specified drive identifier is valid.

=head2 fexpand

  my $path = fexpand($relativePath, $basePath | undef);

Expands a relative path into an absolute path.

If C<$basePath> is provided, the expansion is performed relative to that path.
Otherwise, the current directory is used as the base.

=head2 getCurDir

  getCurDir($dir, $drive);

Retrieves the current directory for the specified drive and stores it in
C<$dir>.

=head2 getHomeDir

  my $bool = getHomeDir($drive, $dir);

Retrieves the home directory associated with the specified drive and stores it
in C<$dir>.

Returns true if a home directory could be determined.

=head2 isDir

  my $bool = isDir($path);

Returns true if the specified path refers to an existing directory.

=head2 isWild

  my $bool = isWild($string);

Returns true if the specified string contains wildcard characters.

=head2 pathValid

  my $bool = pathValid($path);

Returns true if the specified path is syntactically valid.

=head2 validFileName

  my $bool = validFileName($fileName);

Returns true if the specified file name is valid.

=head1 SEE ALSO

L<TUI::StdDlg::FileDialog>,
L<TUI::StdDlg::DirListBox>,
L<TUI::StdDlg::ChDirDialog>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
