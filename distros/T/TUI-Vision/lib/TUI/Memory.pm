package TUI::Memory;
# ABSTRACT: defines various memory-related utility functions

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Hash::Util::FieldHash qw( fieldhash );
use PerlX::Assert::PP;
use Scalar::Util qw(
  looks_like_number
  readonly
  weaken
);
use TUI::toolkit::boolean;

use Exporter 'import';

our @EXPORT = qw(
  initMemory
  doneMemory
  lowMemory
  memAlloc
  newCache
  disposeCache
  getBufferSize
  setBufferSize
);

our @EXPORT_OK = qw(
  $maxHeapSize
);

our %EXPORT_TAGS = (
  all => [ @EXPORT, @EXPORT_OK ],
);

# global variables
our $maxHeapSize = 655360;    # 640K

# private attributes
fieldhash my %cacheList;
fieldhash my %bufferSize;

sub initMemory () {    # void ()
  assert ( @_ == 0 );
  goto &doneMemory;
  return;
}

sub doneMemory () {    # void ()
  assert ( @_ == 0 );
  %cacheList  = ();
  %bufferSize = ();
  return;
}

my $freeSafetyPool = sub () {    # bool ()
  assert ( @_ == 0 );
  my $trimmed = false;
  for my $p ( values %cacheList ) {
    my @keys = keys %$p;
    my $remove = @keys - $bufferSize{$p};
    if ( $remove > 0 ) {
      # Partial Fisher-Yates shuffle:
      # We shuffle only the first $remove positions. This yields a uniformly 
      # random selection of $remove unique keys without shuffling the entire 
      # array. The selected keys are then deleted.
      for my $i ( 0 .. $remove - 1 ) {
        my $j = $i + int rand( @keys - $i );
        @keys[ $i, $j ] = @keys[ $j, $i ];
      }
      delete @$p{ @keys[ 0 .. $remove - 1 ] };
      $trimmed = true;
    }
  }
  return $trimmed;
};

sub lowMemory () {    # $bool ()
  assert ( @_ == 0 );
  my $total = 0;
  $total += keys( %$_ ) for values %cacheList;
  if ( $total > $maxHeapSize ) {
    if ( $freeSafetyPool->() ) {
      $total = 0;
      $total += keys( %$_ ) for values %cacheList;
    }
  }
  return $total > $maxHeapSize;
}

sub memAlloc ($) {    # $p ($size)
  my ( $size ) = @_;
  assert ( @_ == 1 );
  assert ( looks_like_number $size and $size >= 0 );
  my $p = {};
  $cacheList{$p} = $p;
  weaken( $cacheList{$p} );
  $bufferSize{$p} = $size;
  return $p;
}

sub newCache ($$) {    # void ($p, $size)
  my ( undef, $size ) = @_;
  alias: for my $p ( $_[0] ) {
  assert ( @_ == 2 );
  assert ( !readonly $p );
  assert ( looks_like_number $size and $size >= 0 );
  $p = memAlloc( $size );
  return;
  } #/ alias:
}

sub disposeCache ($) {    # void ($p)
  alias: for my $p ( $_[0] ) {
  assert ( @_ == 1 );
  assert ( ref $p and !readonly $p );
  return
    unless $cacheList{$p};
  delete $cacheList{$p};
  delete $bufferSize{$p};
  $p = undef;
  return;
  } #/ alias:
}

sub getBufferSize ($) {    # $size|undef ($p)
  my ( $p ) = @_;
  assert ( @_ == 1 );
  assert ( ref $p );
  return $bufferSize{$p};
}

sub setBufferSize ($$) {    # $bool ($p, $size)
  my ( $p, $size ) = @_;
  assert ( @_ == 2 );
  assert ( ref $p );
  assert ( looks_like_number $size and $size >= 0 );
  return false
    unless $cacheList{$p};
  my $total = 0;
  $total += $bufferSize{$_} for values %cacheList;
  $total += $size - $bufferSize{$p};
  return false
    if $total > $maxHeapSize;
  $bufferSize{$p} = $size;
  return true;
}

1

__END__

=pod

=head1 NAME

TUI::Memory - memory-related utility functions

=head1 SYNOPSIS

  use TUI::Memory qw(
    lowMemory
    newCache
    disposeCache
  );

  my $cache;
  newCache( $cache, 20 );

  $cache->{$_} = $_
    for 1 .. 150;

  if ( lowMemory() ) {
    $cache = {};
  }

  disposeCache( $cache );

=head1 DESCRIPTION

C<TUI::Memory> provides the I<Turbo Vision> compatible memory and cache 
management API used by the Perl port.

Caches are represented by ordinary hash references. Each allocation defines a 
guaranteed minimum size. However, the cache may also use additional capacity.

When C<lowMemory> is called, the memory manager compares the combined number of 
cache entries with the configured heap limit. If the limit is exceeded, entries 
above each cache's guaranteed minimum size are discarded.

This module is purely functional and does not define any classes.

=head2 Commonly Used Features

Most applications interact with C<TUI::Memory> only through the cache
management API. Cache allocations are typically created with L</newCache>. A 
cache can be removed completely with L</disposeCache>.

The L</lowMemory> function is typically used by the framework before creating or
validating new views. If the combined guaranteed cache size still exceeds
L</$maxHeapSize> after reclaimable entries have been discarded, applications
may reject additional allocations and report a low-memory condition.

Typical examples include large transient caches such as attribute conversion 
tables, glyph caches or other lookup structures whose size may grow with the 
complexity of the user interface.

=head1 VARIABLES

=head2 $maxHeapSize

Maximum combined number of entries permitted across all registered caches
before the memory manager attempts to reclaim cache contents.

The name is retained from the original I<Turbo Vision> API. In the Perl port 
the value represents cache entries rather than bytes of heap memory.

=head1 FUNCTIONS

=head2 disposeCache

  disposeCache( $cache );

Calling C<disposeCache> explicitly deregisters the cache, releases its metadata
and sets the caller's cache variable to C<undef>. 

=head2 doneMemory

  doneMemory();

Shuts down the memory subsystem.

=head2 getBufferSize

  my $size = getBufferSize( $cache );

Returns the configured minimum size of a cache allocation.

Returns C<undef> if the allocation is not known to the memory manager.

=head2 initMemory

  initMemory();

Initializes the memory subsystem.

=head2 lowMemory

  my $bool = lowMemory();

Calls the memory manager and returns true if the total cache usage, even after 
being reduced to the guaranteed minimum, is greater than C<$maxHeapSize>.

Returns false if the total cache usage does not exceed C<$maxHeapSize>.

=head2 memAlloc

  my $cache = memAlloc( $size );

Creates a cache allocation with a guaranteed minimum size of C<$size>.

=head2 newCache

  newCache( $cache, $size );

Creates a cache allocation with a guaranteed minimum size of C<$size>.

When the combined number of entries in all registered caches exceeds
C<$maxHeapSize>, entries above the guaranteed minimum size may be discarded
automatically.

=head2 setBufferSize

  my $bool = setBufferSize( $cache, $size );

Changes the guaranteed minimum size of a cache allocation.

Returns true if the size was accepted.

Returns false if the allocation is unknown or if the requested size would
cause the combined guaranteed cache size to exceed C<$maxHeapSize>.

=head1 SEE ALSO

L<TProgram|TUI::App::Program>,
L<TFileViewer|TUI::Gadgets::FileViewer>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2021-2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
