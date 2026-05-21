package TUI::StdDlg::Dos;
# ABSTRACT: Defines structures and functions for use similar to MS-DOS

use 5.010;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
  _dos_findfirst
  _dos_findnext
);

our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
);

use Class::Struct;
use TUI::toolkit qw( signature );
use TUI::toolkit::Types qw( :types );

use TUI::StdDlg::FindFirstRec;

struct ffblk => [
  ff_reserved => '$',
  ff_fsize    => '$',
  ff_attrib   => '$',
  ff_ftime    => '$',
  ff_fdate    => '$',
  ff_name     => '$',
];

# The MSC find_t structure corresponds exactly to the ffblk structure
struct find_t => [
  reserved => '$',
  size     => '$',    # size of file
  attrib   => '$',    # attribute byte for matched file
  wr_time  => '$',    # time of last write to file
  wr_date  => '$',    # date of last write to file
  name     => '$',    # string name of matched file
];

sub _dos_findfirst {    # $int ($pathname, $attrib, $finfo)
  state $sig = signature(
    pos => [Str, PositiveOrZeroInt, ArrayLike],
  );
  my ( $pathname, $attrib, $finfo ) = $sig->( @_ );
  # The original findfirst sets errno on failure. We don't do this for now.
  my $r;
  if ( $r = FindFirstRec->allocate( $finfo, $attrib, $pathname ) ) {
    return $r->next() ? 0 : -1;
  }
  return -1
}

sub _dos_findnext {    # $int ($finfo)
  state $sig = signature(
    pos => [ArrayLike],
  );
  my ( $finfo ) = $sig->( @_ );
  my $r = FindFirstRec->get( $finfo );
  return 0
    if $r && $r->next();
  return -1;
}

1

__END__

=pod

=head1 NAME

TUI::StdDlg::Dos - DOS-style directory search structures and functions

=head1 SYNOPSIS

  use TUI::StdDlg::Dos;

  my $blk = ffblk->new;

  if ( _dos_findfirst('*.*', 0, $blk) == 0 ) {
    do {
      print $blk->ff_name, "\n";
    } while ( _dos_findnext($blk) == 0 );
  }

=head1 DESCRIPTION

C<TUI::StdDlg::Dos> provides low-level data structures and helper functions used
by the standard dialog subsystem to perform directory searches in a
DOS-compatible manner.

The module defines record-style structures representing directory entries and
exposes search functions that iterate over matching filesystem objects. These
facilities are used internally by directory and file selection dialogs.

This module does not define any objects derived from C<TObject>.

=head1 STRUCTURES

=head2 ffblk

Represents a directory search record compatible with the traditional DOS
C<ffblk> structure.

The structure contains the following fields:

=over

=item ff_name

Name of the matched file or directory (I<Str>).

=item ff_fsize

Size of the file in bytes (I<Int>).

=item ff_attrib

Attribute flags of the matched entry (I<Int>).

=item ff_ftime

Time of last modification (I<Int>).

=item ff_fdate

Date of last modification (I<Int>).

=back

=head2 find_t

Represents a directory search record compatible with the Microsoft C runtime
C<find_t> structure.

The structure contains the following fields:

=over

=item name

Name of the matched file or directory (I<Str>).

=item size

Size of the file in bytes (I<Int>).

=item attrib

Attribute flags of the matched entry (I<Int>).

=item wr_time

Time of last modification (I<Int>).

=item wr_date

Date of last modification (I<Int>).

=back

=head1 FUNCTIONS

=head2 _dos_findfirst

  my $rc = _dos_findfirst($pattern, $attrib, $record);

Initializes a directory search.

=over

=item pattern

Search pattern, which may include wildcards (I<Str>).

=item attrib

Attribute mask used to filter matching entries (I<Int>).

=item record

A directory search record of type C<ffblk> or C<find_t> that will receive the
first matching entry.

=back

Returns zero on success. A non-zero value indicates that no matching entry was
found.

=head2 _dos_findnext

  my $rc = _dos_findnext($record);

Advances the directory search to the next matching entry.

=over

=item record

The directory search record previously initialized by C<_dos_findfirst>.

=back

Returns zero on success. A non-zero value indicates that no further matching
entries are available.

=head1 SEE ALSO

L<TUI::StdDlg::DirCollection>,
L<TUI::StdDlg::DirListBox>,
L<TUI::StdDlg::ChDirDialog>

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
