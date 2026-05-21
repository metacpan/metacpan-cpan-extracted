package TUI::StdDlg::Dir;
# ABSTRACT: Replacements for functions in Borland's C/C++ Run Time Library

use 5.010;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
  findfirst
  findnext
  fexpand
  fnsplit
  fnmerge
  getdisk
  setdisk
  getcurdir
);

our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
);

use Cwd qw(
  getcwd
  getdcwd
);
use List::Util qw( min );
use Scalar::Util qw(
  blessed
  readonly
);
use TUI::toolkit qw( :utils );
use TUI::toolkit::Types qw(
  Maybe
  is_PositiveOrZeroInt
  :types
);

use TUI::StdDlg::Const qw(
  :DIR
  :MAX
);
use TUI::StdDlg::Dos qw(
  _dos_findfirst
  _dos_findnext
);

sub findfirst {    # $int ($pathname, $ffblk, $attrib)
  state $sig = signature(
    pos => [Str, ArrayLike, PositiveOrZeroInt],
  );
  my ( $pathname, $ffblk, $attrib ) = $sig->( @_ );
  return _dos_findfirst( $pathname, $attrib, $ffblk );
}

sub findnext {    # $int ($ffblk)
  state $sig = signature(
    pos => [ArrayLike],
  );
  my ( $ffblk ) = $sig->( @_ );
  return _dos_findnext( $ffblk );
}

# Builds a path from component parts.
sub fnmerge {    # void ($pathP|undef, $driveP|undef, $dirP|undef, $nameP|undef, $extP|undef)
  state $sig = signature(
    pos => [ Maybe[Str], Maybe[Str], Maybe[Str], Maybe[Str], Maybe[Str] ],
  );
  my ( $pathP, $driveP, $dirP, $nameP, $extP ) = $sig->( @_ );
  assert ( not readonly $_[0] );
  $pathP = '';

  if ( $^O eq 'MSWin32' && length $driveP ) {
    $pathP .= $driveP;
    $pathP .= ':' if substr( $pathP, -1, 1 ) ne ':';
  }

  if ( length $dirP ) {
    $pathP .= $dirP;
    my $last = substr( $pathP, -1, 1 );
    if ( $last ne '\\' && $last ne '/' ) {
      $pathP .= '\\';
    }
  }
  if ( length $nameP ) {
    $pathP .= $nameP 
  }
  if ( length $extP ) {
    $pathP .= '.' if substr( $extP, 0, 1 ) ne '.';
    $pathP .= $extP;
  }

  # fnmerge is often used before accessing files, so producing a
  # UNIX-formatted pathP fixes most cases of filesystem access.
  if ( $^O ne 'MSWin32' ) {
    $pathP =~ tr{\\}{/};
    $pathP =~ s{/+}{/}g;
  }

  $_[0] = $pathP;
  return;
}

# Split a Full Path Name into Its Components
sub fnsplit {    # void ($pathP|undef, $driveP|undef, $dirP|undef, $nameP|undef, $extP|undef)
  state $sig = signature(
    pos => [ Maybe[Str], Maybe[Str], Maybe[Str], Maybe[Str], Maybe[Str] ],
  );
  my ( $pathP, $driveP, $dirP, $nameP, $extP ) = $sig->( @_ );
  alias: for $driveP ( $_[1] ) { 
  alias: for $dirP   ( $_[2] ) { 
  alias: for $nameP  ( $_[3] ) {
  alias: for $extP   ( $_[4] ) {

  my $flags = 0;

  $driveP = '' unless readonly $driveP;
  $dirP   = '' unless readonly $dirP;
  $nameP  = '' unless readonly $nameP;
  $extP   = '' unless readonly $extP;

  if ( my $len = length $pathP ) {
    my $caretP;
    my $slashP;       # Rightmost slash
    my $lastDotP;     # Last dot in filename
    my $firstDotP;    # First dot in filename
    for ( my $i = $len - 1; $i >= 0; --$i ) {
      SWITCH: for ( substr( $pathP, $i, 1 ) ) {
        $_ eq '?' || 
        $_ eq '*' and do {
          # Wildcards are only detected in filename or extension.
          $flags |= WILDCARDS if !defined $slashP;
          last;
        };

        $_ eq '.' and do {
          if ( !defined $slashP ) {
            $lastDotP  = $i if !defined $lastDotP;
            $firstDotP = $i;
          }
          last;
        };

        $_ eq '\\' || 
        $_ eq '/' and do {
          $slashP = $i if !defined $slashP;
          last;
        };

        $_ eq ':' and do {
          if ( $i == 1 ) {
            $caretP = $i;
            $i = 0;    # Exit loop, we don't check the drive letter.
          }
        };

        DEFAULT:
      }
    }

    # These variables point after the last character of each component.
    my $driveEnd = defined $caretP   ? $caretP + 1 : 0;
    my $dirEnd   = defined $slashP   ? $slashP + 1 : $driveEnd;
    my $nameEnd  = defined $lastDotP ? $lastDotP : $len;

    # Special case: pathP ends with '.' or '..', thus there's no filename.
    if ( defined $lastDotP && $lastDotP == $len - 1
      && ( $lastDotP - $firstDotP ) < 2
      && defined $firstDotP && $firstDotP == $dirEnd
    ) {
      $dirEnd = $nameEnd = $len;
    }

    # Copy components and set flags.
    if ( $driveEnd != 0 ) {
      $driveP = substr( $pathP, 0, min( $driveEnd, MAXDRIVE ) ) 
        if !readonly $driveP;
      $flags |= DRIVE;
    }
    if ( $dirEnd != $driveEnd ) {
      $dirP = substr( $pathP, $driveEnd, min( $dirEnd - $driveEnd, MAXDIR ) )
        if !readonly $dirP;
      $flags |= DIRECTORY;
    }
    if ( $nameEnd != $dirEnd ) {
      $nameP = substr( $pathP, $dirEnd, min( $nameEnd - $dirEnd, MAXFILE ) )
        if !readonly $nameP;
      $flags |= FILENAME;
    }
    if ( $len != $nameEnd ) {
      $extP = substr( $pathP, $nameEnd, min( $len - $nameEnd, MAXEXT ) )
        if !readonly $extP;
      $flags |= EXTENSION;
    }
  }

  return $flags;
  }}}} #/ alias:
}

# $direc is an Str where the directory name will be placed, without drive 
# specification nor leading backslash.
# B<Note>: that drive 0 is the I<default> drive, C<1> is drive C<A>, etc.
sub getcurdir {   # $int ($drive, $direc|undef)
  state $sig = signature(
    pos => [ Int, Maybe[Str] ],
  );
  my ( $drive, $direc ) = $sig->( @_ );
  assert ( not readonly $_[1] );
  $direc = '';

  if ( $^O eq 'MSWin32' ) {
    my $idx = $drive ? $drive - 1 : getdisk();    # 0-based A=0
    return -1 if $idx < 0 || $idx > 25;

    my $letter = chr( ord( 'A' ) + $idx );
    my $full   = getdcwd( $letter . ':' );
    return -1 if !defined( $full ) || $full eq '';

    $full =~ tr{\/}{\\};
    $full =~ s/\A[A-Za-z]:\\//;

    # Ensure no leading backslash (should already be none after stripping)
    $full =~ s/\A\\+//;

    $_[1] = $direc = $full;
    return 0;
  }

  return -1 unless $drive == 0 || ( $drive - 1 ) == getdisk();

  my $cwd = getcwd();
  return -1 unless length $cwd;

  $cwd =~ tr{/}{\\};
  $cwd =~ s{\\+}{\\}g;
  $cwd =~ s/\A\\//;

  $_[1] = $direc = $cwd;
  return 0;
}

# Return current drive index (A=0, B=1, C=2, ...)
sub getdisk {    # $int ()
  state $sig = signature(
    pos => [],
  );
  $sig->( @_ );
  if ( $^O eq 'MSWin32' ) {
    require Win32;
    if ( my $cwd = Win32::GetCwd() ) {
      my $letter = substr( $cwd, 0, 1 );
      return ord( $letter ) - ord( 'A' );
    }
  }
  # Emulate drive C.
  return ord( 'C' ) - ord( 'A' );
}

sub setdisk {    # $int ($drive)
  state $sig = signature(
    pos => [Int],
  );
  my ( $drive ) = $sig->( @_ );

  if ( $^O eq 'MSWin32' ) {
    require Win32;
    require Win32API::File;
    return -1 unless $drive >= 1 && $drive <= 26;
    my $letter = chr( ord( 'A' ) + $drive - 1 );
	  Win32::SetCwd( "${letter}:\\" ) or return -1;
    my $mask = Win32API::File::GetLogicalDrives();
    my $count = 0;
    $count++ while $mask &= $mask - 1;
    return $count;
  }

  return $drive == getdisk() ? 0 : -1;
}

1

__END__

=pod

=head1 NAME

TUI::StdDlg::Dir - directory and path utility functions

=head1 SYNOPSIS

  use TUI::StdDlg;

  my $rc = findfirst('*.*', $ffblk, 0);
  while ( $rc == 0 ) {
    print $ffblk->ff_name, "\n";
    $rc = findnext($ffblk);
  }

  my ($drive, $dir, $name, $ext);
  fnsplit('/usr/local/bin/perl', $drive, $dir, $name, $ext);

=head1 DESCRIPTION

C<TUI::StdDlg::Dir> provides a set of directory- and path-related utility
functions compatible with the traditional Borland C/C++ runtime library.

The functions in this module are used by the standard dialog subsystem to
perform directory traversal, path manipulation, and drive handling. Although
inspired by the original Borland RTL, the implementation is adapted to modern
platforms and Perl conventions.

This module is purely functional and does not define any objects.

=head1 FUNCTIONS

=head2 findfirst

  my $rc = findfirst($pathname, $ffblk, $attrib);

Initializes a directory search using the specified pathname and attribute
mask.

On success, the directory entry record C<$ffblk> is populated with information
about the first matching entry and the function returns zero.

=head2 findnext

  my $rc = findnext($ffblk);

Advances the directory search to the next matching entry.

The directory entry record is updated to describe the new match. The function
returns zero on success and a non-zero value if no further entries are
available.

=head2 fnmerge

  fnmerge($pathP, $drive | undef, $dir | undef, $name | undef, $ext | undef);

Builds a path from its component parts.

Output components are written directly to the provided arguments. Undefined 
components are ignored.

=head2 fnsplit

  fnsplit($path, $driveP | undef, $dirP | undef, $nameP | undef, $extP | undef);

Splits a full path name into its individual components.

The component parameters are modified directly by the function and do not need
to be passed as references.

=head2 getcurdir

  my $rc = getcurdir($drive, $dir | undef);

Retrieves the current directory for the specified drive.

The directory name is stored without drive specification or leading path
separator.

=head2 getdisk

  my $drive = getdisk();

Returns the index of the current drive (A=0, B=1, C=2, ...).

=head2 setdisk

  my $rc = setdisk($drive);

Sets the current drive.

=head1 IMPLEMENTATION NOTES

Parameters with a trailing C<P> suffix are modified directly by the function.

In this Perl implementation, these parameters are passed as ordinary arguments
and updated in place via C<@_>. No explicit references are required and the
parameters are not treated as read-only.

=head1 SEE ALSO

L<TUI::StdDlg::Dos>,
L<TUI::StdDlg::FindFirstRec>,
L<TUI::StdDlg::Util>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

=over

=item * magiblot <magiblot@hotmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1987, 1993 by Borland International

Copyright (c) 2019-2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
