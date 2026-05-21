package TUI::Views::View::Exposed;
# ABSTRACT: TView exposed member functions.

use strict;
use warnings;

our $VERSION = '2.000001';
$VERSION =~ tr/_//d;
our $AUTHORITY = 'cpan:BRICKPOOL';

use Scalar::Util qw( weaken );
use TUI::toolkit::boolean;

use TUI::Views::Const qw(
  sfExposed
  sfVisible
);

my $eax = 0;
my $ebx = 0;
my $ecx = 0;
my $esi = 0;
my $target = undef;
        
use subs qw(
  L0
  L1
  L10
  L11
  L12
  L13
  L20
  L21
  L22
  L23
);

sub L0 {    # $bool ($dest)
  my ( $dest ) = @_;
  return false
    unless $dest->{state} & sfExposed;
  return false
    if 0 >= $dest->{size}{x} || 0 >= $dest->{size}{y};
  return L1( $dest );
}

sub L1 {    # $bool ($dest)
  my ( $dest ) = @_;
  my $i = 0;
  do {
    $eax = $i;
    $ebx = 0;
    $ecx = $dest->{size}{x};
    return true
      unless L11( $dest );
    $i++;
  } while ( $i < $dest->{size}{y} );
  return false;
} #/ sub L1

sub L10 {    # $bool ($dest)
  my ( $dest ) = @_;
  my $owner = $dest->owner();
  return false
    if $owner->{buffer}
    || $owner->{lockFlag};
  return L11( $owner );
}

sub L11 {    # $bool ($dest)
  my ( $dest ) = @_;
  weaken( $target = $dest );
  $eax += $dest->{origin}{y};
  $ebx += $dest->{origin}{x};
  $ecx += $dest->{origin}{x};
  my $owner = $dest->owner();
  return false
    unless $owner;
  return true
    if $eax < $owner->{clip}{a}{y};
  return true
    if $eax >= $owner->{clip}{b}{y};
  return L12( $owner )
    if $ebx >= $owner->{clip}{a}{x};
  $ebx = $owner->{clip}{a}{x};
  return L12( $owner );
} #/ sub L11

sub L12 {    # $bool ($owner)
  my ( $owner ) = @_;
  return L13( $owner )
    if $ecx <= $owner->{clip}{b}{x};
  $ecx = $owner->{clip}{b}{x};
  return L13( $owner );
}

sub L13 {    # $bool ($owner)
  my ( $owner ) = @_;
  return true
    if $ebx >= $ecx;
  return L20( $owner->last() );
}

sub L20 {    # $bool ($dest)
  my ( $dest ) = @_;
  my $next = $dest->next();
  return L10( $next )
    if $next == $target;
  return L21( $next );
}

sub L21 {    # $bool ($next)
  my ( $next ) = @_;
  return L20( $next )
    unless $next->{state} & sfVisible;
  $esi = $next->{origin}{y};
  return L20( $next )
    if $eax < $esi;
  $esi += $next->{size}{y};
  return L20( $next )
    if $eax >= $esi;
  $esi = $next->{origin}{x};
  return L22( $next )
    if $ebx < $esi;
  $esi += $next->{size}{x};
  return L20( $next )
    if $ebx >= $esi;
  $ebx = $esi;
  return L20( $next )
    if $ebx < $ecx;
  return true;
} #/ sub L21

sub L22 {    # $bool ($next)
  my ( $next ) = @_;
  return L20( $next )
    if $ecx <= $esi;
  $esi += $next->{size}{x};
  return L23( $next )
    if $ecx > $esi;
  $ecx = $next->{origin}{x};
  return L20( $next );
} #/ sub L22

sub L23 {    # $bool ($next)
  my ( $next ) = @_;
  my $_target   = $target;
  my $_esi      = $esi;
  my $_ecx      = $ecx;
  my $_eax      = $eax;
  $ecx = $next->{origin}{x};
  my $b = L20( $next );
  $eax    = $_eax;
  $ecx    = $_ecx;
  $ebx    = $_esi;
  weaken( $target = $_target );
  return L20( $next )
    if $b;
  return false;
} #/ sub L23

1

__END__

=pod

=NAME

TUI::Views::View::Exposed - TView exposed member functions.

=head1 DESCRIPTION

TView exposed member functions.

The content was taken from the framework
"A modern port of Turbo Vision 2.0", which is licensed under MIT license.

=head1 SEE ALSO

I<tvexposd.asm>, I<tvexposd.cpp>

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
