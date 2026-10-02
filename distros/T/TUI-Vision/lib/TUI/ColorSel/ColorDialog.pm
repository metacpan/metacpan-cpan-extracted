package TUI::ColorSel::ColorDialog;
# ABSTRACT: Common dialog box for selecting a color

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000002';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TColorDialog
  new_TColorDialog
);

use Carp ();
use TUI::toolkit;
use TUI::toolkit::Types qw(
  Maybe
  :is
  :types
);

use TUI::Drivers::Const qw( evBroadcast );
use TUI::Drivers::ColorAttr;
use TUI::Dialogs::Const qw(
  bfDefault
  bfNormal
);
use TUI::Dialogs::Button;
use TUI::Dialogs::Dialog;
use TUI::Dialogs::Label;
use TUI::ColorSel::Const qw(
  cmNewColorItem
  cmNewColorIndex
  :csXXXX
);
use TUI::ColorSel::ColorDisplay;
use TUI::ColorSel::ColorGroupList;
use TUI::ColorSel::ColorItemList;
use TUI::ColorSel::ColorSelector;
use TUI::ColorSel::MonoSelector;
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  cmOK
  cmCancel
  ofCentered
);
use TUI::Views::ScrollBar;
use TUI::Views::View;

sub TColorDialog() { __PACKAGE__ }
sub name() { 'TColorDialog' }
sub new_TColorDialog { __PACKAGE__->from(@_) }

extends TDialog;

# declare global variables
our $colors     = "Colors";
our $groupText  = "~G~roup";
our $itemText   = "~I~tem";
our $forText    = "~F~oreground";
our $bakText    = "~B~ackground";
our $textText   = "Text ";
our $colorText  = "Color";
our $okText     = "O~K~";
our $cancelText = "Cancel";

# import global variables
use vars qw(
  $showMarkers
);
{
  no strict 'refs';
  *showMarkers = \${ TView . '::showMarkers' };
}

# public attributes
has pal => ( is => 'rw', default => sub { die 'required' } );

# protected attributes
has display    => ( is => 'ro' );
has groups     => ( is => 'ro', default => sub { die 'required' } );
has forLabel   => ( is => 'ro' );
has forSel     => ( is => 'ro' );
has bakLabel   => ( is => 'ro' );
has bakSel     => ( is => 'ro' );
has monoLabel  => ( is => 'ro' );
has monoSel    => ( is => 'ro' );
has groupIndex => ( is => 'ro', default => 0 );

# local color indexes for the get/setIndexes methods
my $colorIndexes = TColorIndex->new();

use constant {
  groupIndex => 0,
  colorSize  => 1,
  colorIndex => 2,
};

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method => 1,
    named => [
      pal    => Maybe[Object], { alias => 'aPalette' },
      groups => Maybe[Object], { alias => 'aGroups' },
    ],
    caller_level => +1,
  );
  my ( $class, $args1 ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  my $args2 = $class->SUPER::BUILDARGS(
    bounds => TRect->new( ax => 0, ay => 0, bx => 79, by => 18 ), 
    title  => $colors, 
  );
  return { %$args1, %$args2 };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  assert ( is_HashRef $args );
  $self->{options} |= ofCentered;
  my $aPalette = $args->{pal};
  $self->{pal} = $aPalette->clone()
    if $aPalette;

  my $sb = TScrollBar->new(
    bounds => TRect->new( ax => 27, ay => 3, bx => 28, by => 14 ), 
  );
  $self->insert( $sb );

  my $aGroups = $args->{groups};
  $self->{groups} = TColorGroupList->new(
    bounds    => TRect->new( ax => 3, ay => 3, bx => 27, by => 14 ), 
    scrollBar => $sb, 
    groups    => $aGroups,
  );
  $self->insert( $self->{groups} );
  $self->insert( 
    TLabel->new(
      bounds => TRect->new( ax => 3, ay => 2, bx => 10, by => 3 ),
      text   => $groupText,
      link   => $self->{groups},
    )
  );

  $sb = TScrollBar->new(
    bounds => TRect->new( ax => 59, ay => 3, bx => 60, by => 14 ),
  );
  $self->insert( $sb );

  my $p = TColorItemList->new( 
    bounds    => TRect->new( ax => 30, ay => 3, bx => 59, by => 14 ), 
    scrollBar => $sb, 
    items     => $aGroups->{items}
  );
  $self->insert( $p );
  $self->insert( 
    TLabel->new(
      bounds => TRect->new( ax => 30, ay => 2, bx => 36, by => 3 ),
      text   => $itemText,
      link   => $p,
    )
  );

  $self->{forSel} = TColorSelector->new( 
    bounds  => TRect->new( ax => 63, ay => 3, bx => 75, by => 7 ),
    selType => csForeground,
  );
  $self->insert( $self->{forSel} );
  $self->{forLabel} = TLabel->new(
    bounds => TRect->new( ax => 63, ay => 2, bx => 75, by => 3 ), 
    text   => $forText, 
    link   => $self->{forSel},
  );
  $self->insert( $self->{forLabel} );

  $self->{bakSel} = TColorSelector->new(
    bounds  => TRect->new( ax => 63, ay => 9, bx => 75, by => 11 ),
    selType => csBackground,
  );
  $self->insert( $self->{bakSel} );
  $self->{bakLabel} = TLabel->new(
    bounds => TRect->new( ax => 63, ay => 8, bx => 75, by => 9 ), 
    text   => $bakText, 
    link   => $self->{bakSel},
  );
  $self->insert( $self->{bakLabel} );

  $self->{display} = TColorDisplay->new(
    bounds => TRect->new( ax => 62, ay => 12, bx => 76, by => 14 ), 
    text   => $textText,
  );
  $self->insert( $self->{display} );

  $self->{monoSel} = TMonoSelector->new(
    bounds => TRect->new( ax => 62, ay => 3, bx => 77, by => 7 ),
  );
  $self->{monoSel}->hide();
  $self->insert( $self->{monoSel} );
  $self->{monoLabel} = TLabel->new(
    bounds => TRect->new( ax => 62, ay => 2, bx => 77, by => 3 ), 
    text   => $colorText, 
    link   => $self->{monoSel},
  );
  $self->{monoLabel}->hide();
  $self->insert( $self->{monoLabel} );

  $self->insert( TButton->new( 
    bounds  => TRect->new( ax => 51, ay => 15, bx => 61, by => 17 ),
    title   => $okText, 
    command => cmOK, 
    flags   => bfDefault,
  ));
  $self->insert( TButton->new(
    bounds  => TRect->new( ax => 35, ay => 15, bx => 45, by => 17 ),
    title   => $cancelText,
    command => cmCancel,
    flags   => bfNormal,
  ));
  $self->selectNext( false );

  $self->setData( $self->{pal} )
    if $self->{pal};
  return;
}

sub from {    # $obj ($aPalette|undef, $aGroups|undef)
  state $sig = signature(
    method => 1,
    pos    => [Maybe[Object], Maybe[Object]],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( pal => $args[0], groups => $args[1] );
}

sub dataSize {    # $dSize ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  $sig->( @_ );
  return 1;
}

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  $self->getIndexes( $colorIndexes );
  $rec->[0] = $self->{pal}->clone();
  return;
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->{groupIndex} = $self->{groups}->focused()
    if $event->{what} == evBroadcast 
    && $event->{message}{command} == cmNewColorItem;
  $self->SUPER::handleEvent( $event );
  $self->{display}->setColor( 
    \( $self->{pal}->[ $event->{message}{infoByte} ] )
  ) if $event->{what} == evBroadcast
    && $event->{message}{command} == cmNewColorIndex;
  return;
}

sub setData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  $self->{pal} = $rec->[0]->clone();

  $self->setIndexes( $colorIndexes );
  $self->{display}->setColor(
    \( $self->{pal}->[
      $self->{groups}->getGroupIndex( $self->{groupIndex} ) 
    ] )
  );
  $self->{groups}->focusItem( $self->{groupIndex} );
  if ( $showMarkers ) {
    $self->{forLabel}->hide();
    $self->{forSel}->hide();
    $self->{bakLabel}->hide();
    $self->{bakSel}->hide();
    $self->{monoLabel}->show();
    $self->{monoSel}->show();
  }
  $self->{groups}->select();
  return;
}

sub setIndexes {    # void (\@colIdx)
  no warnings 'uninitialized';
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $colIdx ) = $sig->( @_ );
  my ( $numGroups, $index );

  $numGroups = $self->{groups}->getNumGroups();
  if ( $colIdx && ( $colIdx->[colorSize] != $numGroups ) ) {
    @$colIdx = ()
  }
  if ( !@$colIdx ) {
    $colIdx->[groupIndex] = 0;
    $colIdx->[colorIndex] = [ 0 .. $numGroups - 1 ],
    $colIdx->[colorSize]  = $numGroups,
  }
  for ( $index = 0 ; $index < $numGroups ; $index++ ) {
    $self->{groups}->setGroupIndex( $index, $colIdx->[colorIndex][$index] );
  }

  $self->{groupIndex} = $colIdx->[groupIndex];
  return;
}

sub getIndexes {    # void (\@colIdx)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $colIdx ) = $sig->( @_ );
  my $n = $self->{groups}->getNumGroups();
  if ( !@$colIdx ) {
    $colIdx->[groupIndex] = 0;
    $colIdx->[colorIndex] = [ 0 .. $n - 1 ],
    $colIdx->[colorSize]  = $n,
  }
  $colIdx->[groupIndex] = $self->{groupIndex};
  for ( my $index = 0 ; $index < $n ; $index++ ) {
    $colIdx->[colorIndex][$index] = $self->{groups}->getGroupIndex( $index );
  }
  return;
}

1

__END__

=pod

=head1 NAME

TUI::ColorSel::ColorDialog - Common dialog box for selecting colors

=head1 HIERARCHY

  TObject
    TView
      TDialog
        TColorDialog

=head1 SYNOPSIS

  use TUI::ColorSel::ColorGroup;

  my $groups =
    TColorGroup->new('Calendar')
      + TColorItem->new('Frame passive',    16)
      + TColorItem->new('Frame active',     17)
      + TColorItem->new('Normal text',      21)
      + TColorItem->new('Current day',      22);

  my $dialog = TColorDialog->new(
    pal    => $palette,
    groups => $groups,
  );

  if ( $deskTop->execView($dialog) == cmOK ) {
    my @data;
    $dialog->getData(\@data);

    my $newPalette = $data[0];
    ...
  }

=head1 DESCRIPTION

C<TColorDialog> implements the standard L<TUI::Vision> color selection dialog.

The dialog presents a list of color groups and their associated color items. 
The selected item can be modified using foreground and background color 
selectors or, when running in monochrome mode, through a monochrome attribute 
selector.

The dialog operates on a copy of the supplied palette. The modified palette can 
be retrieved through the standard Perl data transfer mechanism.

The dialog contains the following visual components:

=over 4

=item * Color group list

Displays the available color groups.

=item * Color item list

Displays the items belonging to the selected group.

=item * Foreground selector

Selects the foreground color attribute.

=item * Background selector

Selects the background color attribute.

=item * Monochrome selector

Used when monochrome attributes are edited.

=item * Color display

Preview area showing the currently selected color.

=back

=head1 CONSTRUCTOR

=head2 new

  my $dlg = TColorDialog->new(
    pal    => $palette | undef,
    groups => $groups  | undef,
  );

Constructs a color selection dialog.

Parameters:

=over 4

=item * C<pal>

Optional palette object (L<TPalette|TUI::Views::Palette>). When supplied, the 
palette is cloned and edited locally within the dialog.

=item * C<groups>

A L<TColorGroup|TUI::ColorSel::ColorGroup> hierarchy describing the available 
color groups and items that may be edited.

=back

=head2 new_TColorDialog

  my $dlg = new_TColorDialog( $palette | undef, $groups | undef);

Compatibility constructor corresponding to the original Borland Turbo Vision
interface.

=head1 ATTRIBUTES

=head2 pal

The palette currently being edited (L<TPalette|TUI::Views::Palette> or
C<undef>).

A clone of the palette provided to the constructor is maintained by the
dialog.

=head2 groups

The color group hierarchy displayed by the dialog
(L<TColorGroupList|TUI::ColorSel::ColorGroupList>).

=head1 METHODS

=head2 dataSize

  my $size = $dlg->dataSize();

Returns the size of the data record used by the dialog.

=head2 getData

  $dlg->getData(\@record);

Copies the current palette into the supplied record.

=head2 setData

  $dlg->setData(\@record);

Initializes the dialog from the supplied record.

=head2 handleEvent

  $dlg->handleEvent($event);

Handles L<TUI::Vision> events and updates the preview display when the
currently selected color item changes.

=head1 SEE ALSO

L<TColorGroup|TUI::ColorSel::ColorGroup>,
L<TColorItem|TUI::ColorSel::ColorItem>,
L<TColorSelector|TUI::ColorSel::ColorSelector>,
L<TMonoSelector|TUI::ColorSel::MonoSelector>,
L<TDialog|TUI::Dialogs::Dialog>

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
