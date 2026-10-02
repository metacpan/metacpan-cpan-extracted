package TUI::Gadgets::HeapView::Linux;
# ABSTRACT: Use the data stored in /proc/self/statm to monitor memory usage

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use POSIX qw( sysconf _SC_PAGESIZE );

use TUI::toolkit qw( :utils );
use TUI::toolkit::Types qw( Object );

use constant PAGE_SIZE_KB => eval { sysconf( _SC_PAGESIZE ) / 1024 } || 4;

sub heapSize {
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  alias: for my $totalStr ( $self->{heapStr} ) {

  state $next_update = 0;
  state $bytes = -1;

  my $now = time;
  if ( $now < $next_update ) {
    $totalStr = sprintf( "%12d", $bytes )
      if $bytes >= 0;
    return $bytes;
  }
  $next_update = $now + 1;

  $totalStr = "     No heap";

  open my $fh, '<', '/proc/self/statm' or return -1;
  my ( undef, $resident ) = split ' ', <$fh>;
  close $fh;
  return -1 unless $resident;

  $bytes = $resident * PAGE_SIZE_KB * 1024;
  $totalStr = sprintf( "%12d", $bytes );

  return $bytes;
  } #/ alias:
}

1;

=pod

=head1 NAME

TUI::Gadgets::HeapView::Linux - Linux heap usage backend for HeapView

=head1 SYNOPSIS

  use TUI::Gadgets::HeapView::Linux;

  my $total = TUI::Gadgets::HeapView::Linux->heapSize();

=head1 DESCRIPTION

This module provides the Linux-specific implementation used by 
L<THeapView|TUI::Gadgets::HeapView> to retrieve memory usage information.

On Linux systems, heap usage is derived from the process virtual memory
statistics provided by the operating system. This module encapsulates the
platform-specific logic required to obtain that information.

The module is not intended to be used directly by application code.

=head1 METHODS

=head2 heapSize

  my $total = TUI::Gadgets::HeapView::Linux->heapSize();

Returns the amount of memory currently used by the process.

On Linux, the value is obtained from C</proc/self/statm>.

The returned value is expressed in bytes.

=head1 SEE ALSO

L<THeapView|TUI::Gadgets::HeapView>

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
