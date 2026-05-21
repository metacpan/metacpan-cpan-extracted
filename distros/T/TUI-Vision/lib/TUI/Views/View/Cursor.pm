package TUI::Views::View::Cursor;
# ABSTRACT: TView resetCursor member functions.

use 5.010;
use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use TUI::toolkit qw(
  :boolean
  :utils
);
use TUI::toolkit::Types qw( :Object );

use TUI::Drivers::HardwareInfo;
use TUI::Drivers::Screen;
use TUI::Views::Const qw( :sfXXXX );

my $self = undef;
my $x = 0;
my $y = 0;

use subs qw(
  resetCursor
);

# import global variables
use vars qw(
  $cursorLines
);
{
  no strict 'refs';
  *cursorLines = \${ TScreen . '::cursorLines' };
}

my (
  $computeCaretSize,
  $caretCovered,
  $decideCaretSize,
);

sub resetCursor {    # void ($p)
  state $sig = signature(
    method => Object,
    pos    => [],
  );
  my ( $p ) = $sig->( @_ );
  $self = $p;
  $x    = $self->{cursor}{x};
  $y    = $self->{cursor}{y};
  my $caretSize = &$computeCaretSize();
  if ( $caretSize ) {
    THardwareInfo->setCaretPosition( $x, $y );
  }
  THardwareInfo->setCaretSize( $caretSize );
  return;
} #/ sub resetCursor

$computeCaretSize = sub {    # $int ()
  assert ( @_ == 0 );
  if ( !( ~$self->{state} & ( sfVisible | sfCursorVis | sfFocused ) ) ) {
    my $v = $self;
    while ( $y >= 0 && $y < $v->{size}{y} 
         && $x >= 0 && $x < $v->{size}{x} 
    ) {
      $y += $v->{origin}{y};
      $x += $v->{origin}{x};
      if ( $v->owner() ) {
        if ( $v->owner()->{state} & sfVisible ) {
          if ( &$caretCovered( $v ) ) {
            last;
          }
          $v = $v->owner();
        }
        else {
          last;
        }
      } #/ if ( $v->owner() )
      else {
        return &$decideCaretSize();
      }
    } #/ while ( $y >= 0 && $y < $v...)
  } #/ if ( !( ~$self->{state...}))
  return 0;
}; #/ sub $computeCaretSize

$caretCovered = sub {    # $bool ($v)
  my ( $v ) = @_;
  assert ( @_ == 1 );
  assert ( is_Object $v );
  my $u = $v->owner()->last()->next();
  for ( ; $u != $v ; $u = $u->next() ) {
    if ( ( $u->{state} & sfVisible )
      && ( $u->{origin}{y} <= $y && $y < $u->{origin}{y} + $u->{size}{y} )
      && ( $u->{origin}{x} <= $x && $x < $u->{origin}{x} + $u->{size}{x} ) 
    ) {
      return true;
    }
  }
  return false;
}; #/ sub $caretCovered

$decideCaretSize = sub {    # $int ()
  assert ( @_ == 0 );
  if ( $self->{state} & sfCursorIns ) {
    return 100;
  }
  return $cursorLines & 0x0f;
};

1

__END__

=pod

=head1 NAME

TUI::Views::View::Cursor - TView resetCursor member functions.

=head1 DESCRIPTION

TView resetCursor member functions.

The content was taken from the framework
"A modern port of Turbo Vision 2.0", which is licensed under MIT license.

=head1 METHODS

=head2 resetCursor

  $self->resetCursor();

=head1 SEE ALSO

I<tvcursor.asm>, I<tvcursor.cpp>

=head1 AUTHORS

=over

=item * Borland International (original Turbo Vision design)

=item * J. Schneider <brickpool@cpan.org> (Perl implementation and maintenance)

=back

=head1 CONTRIBUTORS

=over

=item * magiblot <magiblot@hotmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1990-1994, 1997 by Borland International

Copyright (c) 2019-2026 the L</AUTHORS> and L</CONTRIBUTORS> as listed above.

This software is licensed under the MIT license (see the LICENSE file, which is 
part of the distribution).

=cut
