package TUI::Dialogs::HistoryViewer::HistList;
# ABSTARCT: Implements the behavior of the HistRec list

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT_OK = qw(
  historyCount
  historyAdd
  historyStr
  clearHistory
  initHistory
  doneHistory
);

use TUI::toolkit qw( :utils );
use TUI::toolkit::Types qw(
  Maybe
  :Int
  :Str
);

# declare global variables
our $historyBlock = undef;   # array reference, not a packed string
our $historySize  = 1024;    # initial size of history block
our $historyUsed  = 0;       # taken from the Turbo Pascal implementation

# predeclare private subs
my (
  $advanceStringPointer,
  $deleteString,
  $insertString,
  $startId,
);

# declare local variables
my $curId;
my $curRec;

# Advance curRec to next string with an id of $curId
$advanceStringPointer = sub {    # void ()
  assert ( @_ == 0 );
  $curRec++;
  while ( $curRec < $historyUsed && $historyBlock->[$curRec]->{id} != $curId ) {
    $curRec++;
  }
  $curRec = -1 if $curRec >= $historyUsed;
  return;
};

# Deletes the current string from the table
$deleteString = sub {    # void ()
  assert ( @_ == 0 );
  splice( @$historyBlock, $curRec, 1 ) 
    if $curRec < @$historyBlock;
  $historyUsed = @$historyBlock;
  return;
};

# Insert a string into the table
$insertString = sub {    # void ($id, $str)
  my ( $id, $str ) = @_;
  assert ( @_ == 2 );
  assert ( is_Int $id );
  assert ( is_Str $str );
  my $len = length $str;
  my $n = @$historyBlock;
  my $size = 0;
  for ( reverse @$historyBlock ) {
    last if $len > $historySize - $size;
    $size += length $_->{str};
    $n--;
  }
  splice( @$historyBlock, 0, $n ) if $n > 0;
  push @$historyBlock => { id => $id, str => $str };
  $historyUsed = @$historyBlock;
  return;
};

$startId = sub {    # void ($id)
  assert ( @_ == 1 );
  assert ( is_Int $_[0] );
  $curId = shift;
  $curRec = -1;
  return;
};

sub historyAdd {    # void ($id, $str|undef)
  state $sig = signature(
    pos => [Int, Maybe[Str]]
  );
  my ( $id, $str ) = $sig->( @_ );

  return unless defined $str;
  &$startId( $id );

  # Delete duplicates
  &$advanceStringPointer();
  while ( $curRec >= 0 ) {
    &$deleteString()
      if $str eq $historyBlock->[$curRec]->{str};
    &$advanceStringPointer();
  }

  &$insertString( $id, $str );
  return;
}

sub historyCount {    # $count ($id)
  state $sig = signature(
    pos => [Int]
  );
  my ( $id ) = $sig->( @_ );

  &$startId( $id );
  my $count = 0;
  &$advanceStringPointer();
  while ( $curRec >= 0 ) {
    $count++;
    &$advanceStringPointer();
  }
  return $count;
} #/ sub historyCount

sub historyStr {    # $str ($id, $index)
  state $sig = signature(
    pos => [Int, Int]
  );
  my ( $id, $index ) = $sig->( @_ );

  &$startId( $id );
  &$advanceStringPointer() for ( 0..$index );
  return $curRec >= 0
    ? $historyBlock->[$curRec]->{str}
    : '';
}

sub clearHistory {    # void ()
  state $sig = signature(
    pos => []
  );
  $sig->( @_ );
  $historyBlock = [];
  $historyUsed = @$historyBlock;
  return
}

sub initHistory {   # void ()
  state $sig = signature(
    pos => []
  );
  $sig->( @_ );
  clearHistory();
  return
}

sub doneHistory {   # void ()
  state $sig = signature(
    pos => []
  );
  $sig->( @_ );
  $historyBlock = undef;
  $historyUsed = 0;
  return
}

1

__END__

=pod

=head1 NAME

TUI::Dialogs::HistoryViewer::HistList - TVision style input history functions

=head1 SYNOPSIS

  use TUI::Dialogs::HistoryViewer::HistList qw(
    historyAdd
    historyStr
    historyCount
    clearHistory
  );

  historyAdd(1, "hello");
  historyAdd(1, "world");

  my $count = historyCount(1);
  my $first = historyStr(1, 0);

=head1 DESCRIPTION

C<TUI::Dialogs::HistoryViewer::HistList> provides a set of functions 
implementing a Turbo Vision compatible input history mechanism. It is used by 
dialog controls such as input lines to store and retrieve previously entered 
values.

History entries are grouped by numeric identifiers. Each group maintains an
ordered list of strings. The implementation mirrors the behavior of the
original Turbo Vision history list routines, while adapting the interface to
idiomatic Perl usage.

This module is purely functional. It does not define any classes or objects.

=head1 VARIABLES

The following global variables manage the internal history storage used
by C<HistList>.

=head2 $historyBlock

Reference to the history storage block.
This is an array reference, not a packed string.

=head2 $historySize

Initial size of the history storage block.

=head2 $historyUsed

Number of entries currently used in the history block.
This behavior follows the original Turbo Pascal implementation.

=head1 INTERNAL STRUCTURE

Internally, history entries are stored in a single list of records:

  [
    { id => Int, str => Str },
    { id => Int, str => Str },
    ...
  ]

Each entry associates a history group identifier with a string value.

=head1 FUNCTIONS

=head2 historyAdd

  historyAdd($id, $string);

Adds a string to the history group identified by C<$id>.

If the string already exists in the same history group, it may be moved or
reordered according to Turbo Vision history semantics.

=head2 historyCount

  my $count = historyCount($id);

Returns the number of entries stored in the history group identified by C<$id>.

=head2 historyStr

  my $string = historyStr($id, $index);

Returns the string at position C<$index> in the history group identified by
C<$id>.

If the index is out of range, an empty string is returned.

=head2 clearHistory

  clearHistory();

Removes all history entries from all history groups.

=head2 initHistory

  initHistory();

Initializes the history list management system.

This function clears all existing history data and prepares the internal
storage structures. It is typically called automatically during application
startup.

=head2 doneHistory

  doneHistory();

Destroys all history data and resets the internal module state.

This function is typically called during application shutdown.

=head1 COMPATIBILITY NOTES

This module follows the Turbo Vision C++ history model and preserves its
behavior and semantics.

Internally, the original implementation relied on global state and shared
history storage managed by the application lifecycle. In this Perl port, the
same logical behavior is retained while using Perl-native data structures and
memory management.

The public interface has been adapted to idiomatic Perl usage. In particular:

=over

=item *

State is managed internally by the module and does not require explicit memory
allocation by the caller.

=item *

Strings are passed and returned directly, rather than being modified via
call-by-reference parameters.

=item *

Initialization and shutdown are handled by the surrounding application
framework.

=back

These differences do not change the observable behavior of history handling,
but make the interface safer and more natural to use in Perl.

=head1 IMPORTANT

The history functions are intended for use within TUI::Vision applications
only. They depend on application-level initialization performed during program
startup.

=head1 SEE ALSO

L<TUI::Dialogs::InputLine>,
L<TUI::Dialogs::HistoryViewer>,
L<TUI::App::Application>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2025-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
