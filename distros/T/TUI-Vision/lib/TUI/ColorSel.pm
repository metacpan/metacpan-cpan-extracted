package TUI::ColorSel;
# ABSTRACT: Aggregated color selection components for TUI::Vision

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Import::Into;

use TUI::ColorSel::Const;
use TUI::ColorSel::ColorDialog;
use TUI::ColorSel::ColorDisplay;
use TUI::ColorSel::ColorGroup;
use TUI::ColorSel::ColorGroupList;
use TUI::ColorSel::ColorItem;
use TUI::ColorSel::ColorItemList;
use TUI::ColorSel::ColorSelector;
use TUI::ColorSel::MonoSelector;

sub import {
  my $target = caller;
  TUI::ColorSel::Const->import::into( $target, qw( :all ) );
  TUI::ColorSel::ColorDialog->import::into( $target );
  TUI::ColorSel::ColorDisplay->import::into( $target );
  TUI::ColorSel::ColorGroup->import::into( $target );
  TUI::ColorSel::ColorGroupList->import::into( $target );
  TUI::ColorSel::ColorItem->import::into( $target );
  TUI::ColorSel::ColorItemList->import::into( $target );
  TUI::ColorSel::ColorSelector->import::into( $target );
  TUI::ColorSel::MonoSelector->import::into( $target );
}

sub unimport {
  my $caller = caller;
  TUI::ColorSel::Const->unimport::out_of( $caller );
  TUI::ColorSel::ColorDialog->unimport::out_of( $caller );
  TUI::ColorSel::ColorDisplay->unimport::out_of( $caller );
  TUI::ColorSel::ColorGroup->unimport::out_of( $caller );
  TUI::ColorSel::ColorGroupList->unimport::out_of( $caller );
  TUI::ColorSel::ColorItem->unimport::out_of( $caller );
  TUI::ColorSel::ColorItemList->unimport::out_of( $caller );
  TUI::ColorSel::ColorSelector->unimport::out_of( $caller );
  TUI::ColorSel::MonoSelector->unimport::out_of( $caller );
}

1

__END__

=head1 NAME

TUI::ColorSel - Aggregated color selection components for TUI::Vision

=head1 SYNOPSIS

=head1 SYNOPSIS

  use TUI::ColorSel;

  my $calendar =
      TColorGroup->new('Calendar')
      + TColorItem->new('Frame passive',    16)
      + TColorItem->new('Frame active',     17)
      + TColorItem->new('Frame icons',      18)
      + TColorItem->new('Scroll bar page',  19)
      + TColorItem->new('Scroll bar icons', 20)
      + TColorItem->new('Normal text',      21)
      + TColorItem->new('Current day',      22);

  my $ascii =
      TColorGroup->new('ASCII table')
      + TColorItem->new('Frame passive',    24)
      + TColorItem->new('Frame active',     25)
      + TColorItem->new('Frame icons',      26)
      + TColorItem->new('Scroll bar page',  27)
      + TColorItem->new('Scroll bar icons', 28)
      + TColorItem->new('Text',             29);

  my $groups = $calendar + $ascii;

  my $dialog = TColorDialog->new(
    pal    => undef,
    groups => $groups,
  );

=head1 DESCRIPTION

C<TUI::ColorSel> is a convenience module that loads and re-exports the
color selection components of the L<TUI::Vision> framework.

Instead of importing each component separately, applications can simply
load this module to gain access to all color selection related classes
and constants.

The module exports the symbols as well as the classes listed below.

=over 4

=item * L<Const|TUI::ColorSel::Const>
Color selection constants and symbolic values.

=item * L<TColorDialog|TUI::ColorSel::ColorDialog>
Color selection dialog.

=item * L<TColorDisplay|TUI::ColorSel::ColorDisplay>
Displays the currently selected color/entry.

=item * L<TColorGroup|TUI::ColorSel::ColorGroup>
Represents a logical group of related color items.

=item * L<TColorGroupList|TUI::ColorSel::ColorGroupList>
Collection of color groups.

=item * L<TColorItem|TUI::ColorSel::ColorItem>
Represents a single colorable element.

=item * L<TColorItemList|TUI::ColorSel::ColorItemList>
Collection of color items.

=item * L<TColorSelector|TUI::ColorSel::ColorSelector>
Interactive color selector widget.

=item * L<TMonoSelector|TUI::ColorSel::MonoSelector>
Monochrome attribute selector widget.

=back

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

Contributors are documented in the POD of the respective framework modules.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2026 the L</AUTHORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is
part of the distribution).

=cut
