package TUI::Gadgets::HeapView::Win32;
# ABSTRACT: on Windows, display the virtual memory used by the process

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';


use Config;
use TUI::toolkit qw( :utils );
use TUI::toolkit::Types qw( Object );
use Win32::API;

use constant PTR_SIZE => $Config{ptrsize};
use constant SIZE_T =>
    PTR_SIZE == 8 ? 'Q'
  : PTR_SIZE == 4 ? 'L'
  : die "Unrecognized ptrsize\n";

# Set the size large enough for Windows 32 and 64 bit versions
use constant PROCESS_MEMORY_COUNTERS_EX_SIZE => ( 2 * 4 + 9 * PTR_SIZE );

use constant {
  # cb                         =>  0,  # DWORD
  # PageFaultCount             =>  1,  # DWORD
  # PeakWorkingSetSize         =>  2,  # SIZE_T
  # WorkingSetSize             =>  3,  # SIZE_T
  # QuotaPeakPagedPoolUsage    =>  4,  # SIZE_T
  # QuotaPagedPoolUsage        =>  5,  # SIZE_T
  # QuotaPeakNonPagedPoolUsage =>  6,  # SIZE_T
  # QuotaNonPagedPoolUsage     =>  7,  # SIZE_T
  # PagefileUsage              =>  8,  # SIZE_T
  # PeakPagefileUsage          =>  9,  # SIZE_T
  PrivateUsage               => 10,  # SIZE_T
};

BEGIN {
  # Load required Windows API functions
  Win32::API::More->Import( 'kernel32', 
    'HANDLE GetCurrentProcess()'
  ) or die "Import GetCurrentProcess failed: $^E";

  Win32::API::More->Import( 'psapi', 
    'BOOL GetProcessMemoryInfo(
      HANDLE Process,
      LPVOID ppsmemCounters,
      DWORD  cb
    )'
  ) or die "Import GetProcessMemoryInfo failed: $^E";
}

sub heapSize {    # $total ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  alias: for my $totalStr ( $self->{heapStr} ) {
  $totalStr = "     No heap";

  # Get process handle
  my $hProcess = GetCurrentProcess();
  return -1 unless defined $hProcess && $hProcess != -1;

  # Create pmc buffer for PROCESS_MEMORY_COUNTERS_EX
  my $buf = "\0" x PROCESS_MEMORY_COUNTERS_EX_SIZE;

  # Call WinAPI to fill memory info
  my $r = GetProcessMemoryInfo( $hProcess, $buf, 
    PROCESS_MEMORY_COUNTERS_EX_SIZE );
  return -1 unless $r;

  # Unpack PROCESS_MEMORY_COUNTERS_EX
  my @pmc = unpack( 'LL' . SIZE_T . '*', $buf );

  # Prepare display string similar to setw(12)
  $totalStr = sprintf( "%12d", $pmc[PrivateUsage] );

  return $pmc[PrivateUsage];
  }
} #/ sub heapSize

1

__END__

=pod

=head1 NAME

TUI::Gadgets::HeapView::Win32 - Win32 heap usage backend for HeapView

=head1 SYNOPSIS

  use TUI::Gadgets::HeapView::Win32;

  my $total = TUI::Gadgets::HeapView::Win32->heapSize;

=head1 DESCRIPTION

C<TUI::Gadgets::HeapView::Win32> provides the Windows-specific implementation
used by C<THeapView> to retrieve memory usage information.

On Win32 systems, heap usage is derived from the process virtual memory
statistics provided by the operating system. This module encapsulates the
platform-specific logic required to obtain that information.

The module is not intended to be used directly by application code.

=head1 METHODS

=head2 heapSize

  my $total = TUI::Gadgets::HeapView::Win32->heapSize;

Returns the total amount of virtual memory currently used by the process.

=head1 SEE ALSO

L<TUI::Gadgets::HeapView>

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
