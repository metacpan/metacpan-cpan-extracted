# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::If - Liefere Werte unter einer Bedingung

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::If;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 catIf() - Konkateniere Strings bei erfüllter Bedingung

=head4 Synopsis

  $str = $class->catIf($bool,sub {$expr,...});

=head4 Arguments

=over 4

=item $bool

Bedingung

=item sub {$expr,...}

Ausdrücke, deren Resultat konkateniert wird.

=back

=head4 Returns

String

=head4 Description

Ist Bedingung C<$bool> falsch, liefere einen Leerstring. Andernfalls
konkateniere die Werte der Ausdrücke C<$expr, ...> und liefere das
Resultat zurück. Evaluiert ein Ausdruck C<$expr> zu C<undef>, wird
der Wert durch einen Leerstring ersetzt.

Die Methode ist logisch äquivalent zu

  $str = !$bool? '': join '',$expr // '', ...;

Sie vermeidet jedoch, dass C<$expr // '', ...> berechnet werden muss,
wenn C<$bool> falsch ist.

=head4 Example

B<Konkatenation bei zutreffender Bedingung>

  Quiq::If->catIf(1,sub {
      'Dies',
      'ist',
      'ein',
      undef,
      'Test',
  });
  ==>
  'DiesisteinTest'

=cut

# -----------------------------------------------------------------------------

sub catIf {
    my ($class,$bool,$sub) = @_;
    return !$bool? '': join '',map {$_ // ''} $sub->();
}
    

# -----------------------------------------------------------------------------

=head3 listIf() - Liefere Liste bei erfüllter Bedingung

=head4 Synopsis

  @ret = $class->listIf($bool,@list);
  @ret = $class->listIf($bool,$sub);

=head4 Arguments

=over 4

=item $bool

Bedingung

=item @list

Liste, die bei erfüllter Bedingung geliefert wird.

=back

=head4 Returns

String

=head4 Description

Ist Bedingung C<$bool> wahr, liefere @list bzw. den Rückgabewert
von $sub->(), andernfalls eine leere Liste.

Die Methode ist logisch äquivalent zu

  !$bool? (): @list

bzw.

  !$bool? (): $sub->()

B<Anmerkung>: Die erste Variante hat den Nachteil, dass @list auch
dann ausgewertet wird, wenn $bool falsch ist. In dem Fall ist
die äquivalente Formulierung normalerweise vorzuziehen.

=head4 Example

Setze Attribut C<ready> des Quiq::Html::Page-Objekts
nur dann, wenn $refresh erfüllt ist:

  my $html = Quiq::Html::Page->html($h,
      ...
      Quiq::If->listIf($refresh,
          ready => qq~
              var refresh = $refresh;
              var interval = setInterval(function() {
                  refresh--;
                  \$('#timer').text(refresh);
                  if (refresh == 0) {
                      clearInterval(interval);
                      \$('#timer').text('Lade Seite...');
                      location.reload();
                  }
              },1000);
          ~
      ),
  );

=cut

# -----------------------------------------------------------------------------

sub listIf {
    my ($class,$bool) = splice @_,0,2;

    if (!$bool) {
        return ();
    }
    elsif (ref($_[0]) eq 'CODE') {
        return $_[0]->();
    }

    return @_;
}
    

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
