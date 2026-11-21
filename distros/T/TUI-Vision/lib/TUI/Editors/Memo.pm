package TUI::Editors::Memo;
# ABSTRACT: multi-line text editor view for dialog data

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TMemo
  new_TMemo
);

use Class::Struct;
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Drivers::Const qw(
  :evXXXX
  :kbXXXX
);
use TUI::Editors::Const qw( cpMemo );
use TUI::Editors::Editor;
use TUI::Views::Palette;

struct TMemoData => [
  length => '$',
  buffer => '$',
];

sub TMemo() { __PACKAGE__ }
sub name() { 'TMemo' }
sub new_TMemo { __PACKAGE__->from(@_) }

extends TEditor;

sub getData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  $rec->[0] = $self->bufLen();
  $rec->[1] = $self->{buffer};
  return;
}

sub setData {    # void (\@rec)
  state $sig = signature(
    method => Object,
    pos    => [ArrayLike],
  );
  my ( $self, $rec ) = $sig->( @_ );
  $self->{buffer} = substr( $rec->[1], 0, $rec->[0] );
  $self->setBufLen( length $self->{buffer} );
  return;
}

sub getPalette {    # $palette ()
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $self ) = $sig->( @_ );
  state $palette = TPalette->new(
    data => cpMemo,
    size => length( cpMemo ),
  );
  return $palette->clone();
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  return if $event->{what} == evKeyDown
         && $event->{keyDown}{keyCode} == kbTab;
  $self->SUPER::handleEvent( $event );
  return;
}

sub write :method {    # void ($os)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $os ) = $sig->( @_ );
  $self->SUPER::write( $os );
  $os->put( $self->bufLen(), $self->{buffer} );
  return;
}

sub read :method {    # $self ($is)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $is ) = $sig->( @_ );
  $self->SUPER::read( $is );
  my $length = $is->get();
  my $text   = $is->get();
  if ( $self->{isValid} ) {
    $self->{buffer} = substr( $text, 0, $length );
    $self->setBufLen( length $self->{buffer} );
  }
  return $self;
}

1

__END__

=pod

=head1 NAME

TUI::Editors::Memo - multi-line text editor view for dialog data

=head1 HIERARCHY

  TObject
    TView
      TEditor
        TMemo

=head1 SYNOPSIS

  use TUI::Objects;
  use TUI::Editors;
  use TUI::Dialogs;

  my $memo = TMemo->new(
    bounds     => TRect->new( ax => 0, ay => 0, bx => 40, by => 8 ),
    hScrollBar => undef,
    vScrollBar => $vScrollBar,
    indicator  => undef,
    bufSize    => 0,
  );
  $dialog->insert( $memo );

  my @rec = ();
  $memo->getData( \@rec );
  my $text = $rec[1];

=head1 DESCRIPTION

C<TMemo> is a L<TEditor|TUI::Editors::Editor> that takes part in the data
transfer of a dialog. Its data record is an array-like value whose first
element is the length and whose second element is the text of the buffer.
A L</TMemoData> object can be used as this record.

C<getData> stores the current text in the record, and C<setData> replaces the
text with the text of the record. A Tab key press is not handled by the memo,
so the Tab key moves the focus to the next view of the dialog.

The text buffer of L<TEditor|TUI::Editors::Editor> is a plain Perl string, so
the Turbo Vision buffer size of C<TMemoData> is not needed. The data record
therefore has two entries: the length and the text.

=head1 ATTRIBUTES

C<TMemo> has no attributes of its own. The attributes are inherited from
L<TEditor|TUI::Editors::Editor>.

=head1 CONSTRUCTOR

=head2 new

  my $memo = TMemo->new(
    bounds     => $bounds,
    hScrollBar => $hScrollBar | undef,
    vScrollBar => $vScrollBar | undef,
    indicator  => $indicator  | undef,
    bufSize    => $bufSize,
  );

Creates a new memo view. The constructor is the same as the constructor of
L<TEditor|TUI::Editors::Editor>, so C<bufSize> is required.

=head2 new_TMemo

  my $memo = new_TMemo(
    $bounds,
    $hScrollBar | undef,
    $vScrollBar | undef,
    $indicator  | undef,
    $bufSize,
  );

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 getData

  $memo->getData( \@rec );
  $memo->getData( TMemoData->new() );

Stores the buffer length in C<< $rec->[0] >> and the text in
C<< $rec->[1] >>. C<$rec> must be an array-like value (C<ArrayLike>): a
plain array reference or an object based on an array, such as a
L</TMemoData> object.

=head2 setData

  $memo->setData( \@rec );
  $memo->setData( TMemoData->new( length => 5, buffer => 'hello' ) );

Replaces the text with C<< $rec->[1] >>, truncated to C<< $rec->[0] >>
characters, and sets the buffer length to the length of the new text.
C<$rec> must be an array-like value (C<ArrayLike>), as for L</getData>.

=head2 getPalette

  my $palette = $memo->getPalette();

Returns the palette C<cpMemo>, which differs from the palette of
L<TEditor|TUI::Editors::Editor>.

=head2 handleEvent

  $memo->handleEvent( $event );

Ignores a C<kbTab> key down event. All other events are passed to
L<TEditor|TUI::Editors::Editor>.

=head1 STRUCTURES

=head2 TMemoData

  my $data = TMemoData->new( length => 5, buffer => 'hello' );

An optional data record of the memo, built with L<Class::Struct> as an array
reference. It has the attributes C<length> and C<buffer>, which are the
elements C<< [0] >> and C<< [1] >> of the record. It is a convenience only;
any array-like value can be used with L</getData> and L</setData>.

=head1 SEE ALSO

L<TEditor|TUI::Editors::Editor>,
L<TInputLine|TUI::Dialogs::InputLine>

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
