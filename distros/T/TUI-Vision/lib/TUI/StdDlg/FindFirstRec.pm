package TUI::StdDlg::FindFirstRec;
# ABSTRACT: A class implementing the behaviour of findfirst and findnext

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw( FindFirstRec );

# Code snippet taken from File::Spec
my %module = (
  MSWin32 => 'Win32',
);

my $module = $module{$^O} || 'Unix';

sub FindFirstRec() { "TUI::StdDlg::FindFirstRec::$module" }

require "TUI/StdDlg/FindFirstRec/$module.pm";
our @ISA = ( FindFirstRec );

1

__END__

=pod

=head1 NAME

TUI::StdDlg::FindFirstRec - platform-independent directory search interface

=head1 SYNOPSIS

  use TUI::StdDlg::FindFirstRec;

  my $rec = FindFirstRec->allocate(
    $find_t,
    $attrib,
    $pattern
  );

  while ( $rec->next ) {
    print $find_t->name, "\n";
  }

=head1 DESCRIPTION

C<FindFirstRec> defines the platform-independent interface used by the standard
dialog subsystem to perform directory searches.

The interface models an active directory search as a search context object.
Each search context is associated with a record structure (C<find_t>) that is
updated to reflect the current matching filesystem entry.

The module provides a uniform abstraction for iterating over filesystem entries
that match a given pattern. Platform-specific details are hidden behind a common
interface and resolved transparently at runtime.

Search contexts are typically created and consumed by higher-level components
such as directory collections and list boxes.

=head1 METHODS

=head2 allocate

  my $rec = FindFirstRec->allocate($record, $attrib, $pattern);

Creates and initializes a directory search context.

The provided C<find_t> record is associated with the newly created search
context and will be updated on each successful search step.

The search parameters remain bound to the context for its entire lifetime.

=head2 get

  my $rec = FindFirstRec->get($record);

Returns the search context currently associated with the given record.

This method allows higher-level code to retrieve the active search object when
only the record structure is available.

=head2 next

  my $bool = $rec->next();

Advances the directory search to the next matching entry.

On success, the associated record is updated to describe the newly found
filesystem entry and the method returns true. If no further matches are
available, the method returns false.

=head1 SEE ALSO

L<TUI::StdDlg::FindFirstRec::Win32>,
L<TUI::StdDlg::Dos>,
L<TUI::StdDlg::DirCollection>

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
