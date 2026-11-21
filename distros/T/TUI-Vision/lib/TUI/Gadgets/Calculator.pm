package TUI::Gadgets::Calculator;
# ABSTRACT: dialog window of the calculator gadget

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000003';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Exporter 'import';
our @EXPORT = qw(
  TCalculator
  new_TCalculator
);

use Carp ();
use Storable;
use TUI::toolkit;
use TUI::toolkit::Types qw(
  is_Object
  is_Str
  :types
);

use TUI::Dialogs::Button;
use TUI::Dialogs::Const qw(
  bfBroadcast
  bfNormal
);
use TUI::Dialogs::Dialog;
use TUI::Gadgets::CalcDisplay;
use TUI::Gadgets::Const qw( cmCalcButton );
use TUI::Objects::Rect;
use TUI::Views::Const qw(
  ofFirstClick
  ofSelectable
);

sub TCalculator() { __PACKAGE__ }
sub name() { 'TCalculator' }
sub new_TCalculator { __PACKAGE__->from(@_) }

extends TDialog;

# button captions, row by row
my @keyChar = (
  "C", "\x1B", "%", "\xF1",    # 0x1B is escape, 0xF1 is the +/- char
  "7", "8",    "9", "/",
  "4", "5",    "6", "*",
  "1", "2",    "3", "-",
  "0", ".",    "=", "+",
);

sub BUILDARGS {    # \%args (%args)
  state $sig = signature(
    method       => 1,
    named        => [],
    caller_level => +1,
  );
  my ( $class ) = $sig->( @_ );
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  return $class->SUPER::BUILDARGS(
    bounds => TRect->new( ax => 5, ay => 3, bx => 29, by => 18 ),
    title  => "Calculator",
  );
}

sub BUILD {    # void (\%args)
  my ( $self, $args ) = @_;
  assert ( @_ == 2 );
  assert ( is_Object $self );

  $self->{options} |= ofFirstClick;

  for my $i ( 0 .. $#keyChar ) {
    my $x = ( $i % 4 ) * 5 + 2;
    my $y = int( $i / 4 ) * 2 + 4;
    my $button = TButton->new(
      bounds  => TRect->new( ax => $x, ay => $y, bx => $x + 5, by => $y + 2 ),
      title   => $keyChar[$i],
      command => cmCalcButton,
      flags   => bfNormal | bfBroadcast,
    );
    $button->{options} &= ~ofSelectable;
    $self->insert( $button );
  }

  $self->insert( TCalcDisplay->new(
    bounds => TRect->new( ax => 3, ay => 2, bx => 21, by => 3 ),
  ));
}

sub from {    # $obj ()
  state $sig = signature(
    method => 1,
    pos    => [],
  );
  my ( $class ) = $sig->( @_ );
  return $class->new();
}

sub build {    # $obj ()
  my ( $class ) = @_;
  assert ( @_ == 1 );
  assert ( is_Str $class );
  assert ( Storable::is_retrieving );
  return $class->new();
}

1

__END__

=pod

=head1 NAME

TUI::Gadgets::Calculator - dialog window of the calculator gadget

=head1 HIERARCHY

  TObject
    TView
      TWindow
        TDialog
          TCalculator

=head1 SYNOPSIS

  use TUI::Gadgets;

  my $calc = new_TCalculator();
  $desktop->insert( $calc );

=head1 DESCRIPTION

C<TCalculator> is a dialog that hosts twenty buttons and a
L<TCalcDisplay|TUI::Gadgets::CalcDisplay>. Each button broadcasts
C<cmCalcButton> with its caption as the key, and the display evaluates
the key sequence.

=head1 CONSTRUCTOR

=head2 new

  my $calc = TCalculator->new();

Creates the calculator dialog at position (5,3) with a size of 24x15
and the title C<Calculator>. The constructor takes no arguments.

=head1 METHODS

=head2 build

  my $calc = TCalculator->build();

Creates a new calculator. Used when a stored object is restored.

=head1 SEE ALSO

L<TUI::Gadgets::CalcDisplay>, L<TUI::Dialogs::Dialog>,
L<TUI::Dialogs::Button>

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
