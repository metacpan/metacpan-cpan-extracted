package TUI::StdDlg::FileInputLine;
# ABSTRACT: Input line view for file dialog focus handling

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TFileInputLine
  new_TFileInputLine
);

use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  :types
);

use TUI::Dialogs::InputLine;
use TUI::Drivers::Const qw( evBroadcast );
use TUI::StdDlg::Const qw(
  cmFileFocused
  FA_DIREC
);
use TUI::StdDlg::Util qw( fexpand );
use TUI::Views::Const qw( sfSelected );

sub TFileInputLine() { __PACKAGE__ }
sub name() { 'TFileInputLine' };
sub new_TFileInputLine { __PACKAGE__->from(@_) }

extends TInputLine;

sub BUILDARGS {    # \%args (|%args)
  state $sig = signature(
    method => 1,
    named => [
      bounds    => Object,
      maxLen    => Int, { alias => 'aMaxLen' },
    ],
    caller_level => +1,
  );
  my ( $class, $args ) = $sig->( @_ );
  return { %$args };
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );
  $self->{eventMask} = evBroadcast;
  return;
}

sub from {    # $obj ($aLimit, $aDelta)
  state $sig = signature(
    method => 1,
    pos    => [Object, Int],
  );
  my ( $class, @args ) = $sig->( @_ );
  return $class->new( bounds => $args[0], maxLen => $args[1] );
}

sub handleEvent {    # void ($event)
  state $sig = signature(
    method => Object,
    pos    => [Object],
  );
  my ( $self, $event ) = $sig->( @_ );
  $self->SUPER::handleEvent( $event );

  if ( $event->{what} == evBroadcast
    && $event->{message}{command} == cmFileFocused
    && !( $self->{state} & sfSelected )
  ) {
    # Prevents incorrect display in the input line if wildCard has
    # already been expanded.
    assert ( is_Object $event->{message}{infoPtr} );
    assert ( defined $event->{message}{infoPtr}->name );
    if ( $event->{message}{infoPtr}->attr & FA_DIREC ) {
      $self->{data} = $self->{owner}->wildCard;
      if ( $self->{data} !~ /[:\\]/ ) {
        $self->{data} = $event->{message}{infoPtr}->name
                      . "\\" 
                      . $self->{owner}->wildCard;
      }
      else {
        # Insert "<name>\\" between last name/wildcard and last '\'
        fexpand( $self->{data} );    # Insure complete expansion to begin with
        my $pos = rindex( $self->{data}, '\\' );
        my $nm  = $event->{message}{infoPtr}->name;
        if ( $pos >= 0 ) {
          my $offset = $pos + 1;       # position after last '\'
          substr( $self->{data}, $offset, 0 ) = $nm . '\\';
        }
        else {
          # No backslash found: prepend "<name>\"
          $self->{data} = $nm . '\\' . $self->{data};
        }
        fexpand( $self->{data} );    # Expand again incase it was '..'.
      }
    }
    else {
      $self->{data} = $event->{message}{infoPtr}->name;
      $self->drawView();
    }
  }
  return;
} #/ sub handleEvent

1

__END__

=pod

=head1 NAME

TUI::StdDlg::FileInputLine - input line view for file dialog interaction

=head1 HIERARCHY

  TObject
    TView
      TInputLine
        TFileInputLine

=head1 SYNOPSIS

  use TUI::StdDlg;

  my $input = new_TFileInputLine(
    $bounds,
    $maxLen
  );

=head1 DESCRIPTION

C<TFileInputLine> implements a specialized input line used by standard Turbo
Vision file dialogs for entering file and directory names.

The control extends C<TInputLine> with file-dialog-specific behavior, such as
custom keyboard handling and interaction with other dialog components. It is
typically embedded in a C<TFileDialog> and participates in focus navigation
and command processing within the dialog.

=head1 CONSTRUCTOR

=head2 new

  my $input = TFileInputLine->new(
    bounds => $bounds,
    maxLen => $maxLen
  );

Creates a new file input line.

=over

=item bounds

Bounding rectangle defining the position and size of the input line (I<TRect>).

=item maxLen

Maximum length of the input text (I<Int>).

=back

=head2 new_TFileInputLine

  my $input = new_TFileInputLine($bounds, $maxLen);

Factory-style constructor using positional arguments.

=head1 METHODS

=head2 handleEvent

  $input->handleEvent($event);

Processes keyboard and command events specific to file dialog interaction.

This method extends the default input line behavior to integrate with file
selection and dialog-level commands.

=head1 SEE ALSO

L<TUI::StdDlg::FileDialog>,
L<TUI::Dialogs::InputLine>,
L<TUI::Views::View>

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
