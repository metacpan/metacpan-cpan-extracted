package TUI::Gadgets::HeapView::Unix;
# ABSTRACT: Determine memory usage based on the 'ps' command

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use TUI::toolkit qw( :utils );
use TUI::toolkit::Types qw( Object );

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

  my $kb = qx(ps -o rss= -p $$ 2>/dev/null);
  $kb =~ s/\D//g;
  return -1 unless $kb;

  $bytes = $kb * 1024;
  $totalStr = sprintf( "%12d", $bytes );

  return $bytes;
  }    #/ alias:
}

1;

=pod

=head1 NAME

TUI::Gadgets::HeapView::Unix - Unix heap usage backend for HeapView

=head1 SYNOPSIS

  use TUI::Gadgets::HeapView::Unix;

  my $total = TUI::Gadgets::HeapView::Unix->heapSize();

=head1 DESCRIPTION

This module provides the Unix-specific implementation used by 
L<THeapView|TUI::Gadgets::HeapView> to retrieve memory usage information.

On Unix systems, memory usage is obtained from the operating system by
querying the resident set size (RSS) of the current process using the
C<ps> command.

The module is not intended to be used directly by application code.

=head1 METHODS

=head2 heapSize

  my $total = TUI::Gadgets::HeapView::Unix->heapSize();

Returns the amount of resident memory currently used by the process.

The value is derived from the RSS (resident set size) reported by the
operating system and is returned in bytes.

To reduce system overhead, the value is cached for up to one second
before being refreshed.

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
