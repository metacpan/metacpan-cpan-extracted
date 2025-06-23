# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sql::Composer - Klasse zum Erzeugen von SQL-Code

=head1 BASE CLASS

L<Quiq::Dbms>

=head1 SYNOPSIS

Instantiierung:

  $s = Quiq::Sql::Composer->new($dbms); # Name eines DBMS (siehe Basisklasse)
  $s = Quiq::Sql::Composer->new($db);   # Instanz einer Datenbankverbindung

Alias:

  $sql = $s->alias($expr,$alias);

CASE:

  $sql = $s->case($expr,@pairs,@opt);
  $sql = $s->case($expr,@pairs,$else,@opt);

=cut

# -----------------------------------------------------------------------------

package Quiq::Sql::Composer;
use base qw/Quiq::Dbms/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Reference;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Ausdrücke

=head3 alias() - Ergänze Ausdruck um Alias

=head4 Synopsis

  $sql = $s->alias($expr,$alias);

=head4 Arguments

=over 4

=item $expr

Ausdruck, wie er in einer Select-Liste auftreten kann (expr).

=item $alias

Alias für den Ausdruck.

=back

=head4 Returns

Ausdruck mit Alias (String)

=head4 Description

Ergänze den Ausdruck $expr um den Alias $alias und liefere das
Resultat zurück.

=head4 Example

  $sql = $s->alias('LOWER(name)','name');
  ==>
  "LOWER(name) AS name"

=cut

# -----------------------------------------------------------------------------

sub alias {
    my ($self,$expr,$alias) = @_;

    my $sql = $self->expr($expr);
    $sql .= " AS $alias";

    return $sql;
}

# -----------------------------------------------------------------------------

=head3 case() - Erzeuge CASE-Ausdruck

=head4 Synopsis

  $sql = $s->case($expr,@pairs,@opt);
  $sql = $s->case($expr,@pairs,$else,@opt);

=head4 Arguments

=over 4

=item $expr

CASE-Ausdruck (expr)

=item @pairs

Liste von WHEN/THEN-Paaren (valExpr)

=item $else

ELSE-Wert (valExpr)

=back

=head4 Options

=over 4

=item -fmt => 'm'|'i' (Default: 'm')

Erzeuge einen mehrzeiligen (m=multiline) oder einen
einzeiligen (i=inline) Ausdruck.

=back

=head4 Returns

CASE-Ausdruck (String)

=head4 Description

Erzeuge einen CASE-Ausdruck und liefere diesen zurück.

=head4 Examples

=over 2

=item *

Übersetze Wochentagsnummer in Wochentagskürzel (SQLite)

  $sql = $s->case("strftime('%w', datum)",0=>'So',1=>'Mo',2=>'Di',
      3=>'Mi',4=>'Do',5=>'Fr',6=>'Sa');
  ==>
  "CASE strftime('%w', datum)
      WHEN '0' THEN 'So'
      WHEN '1' THEN 'Mo'
      WHEN '2' THEN 'Di'
      WHEN '3' THEN 'Mi'
      WHEN '4' THEN 'Do'
      WHEN '5' THEN 'Fr'
      WHEN '6' THEN 'Sa'
  END"

=item *

Übersetze 1, 0 in 'Ja', 'Nein', einzeiliger Ausdruck

  $sql = $s->case('bearbeitet',1=>'Ja','Nein',-fmt=>'i');
  ==>
  "CASE bearbeitet WHEN '1' THEN 'Ja' ELSE 'Nein' END"

=item *

Ausdruck statt Sting-Literal (NULL)

  $sql = $s->case('bearbeitet',1=>'Ja',0=>'Nein',\'NULL',-fmt=>'i');
  ==>
  "CASE bearbeitet WHEN '1' THEN 'Ja' WHEN '0' THEN 'Nein' ELSE NULL END"

=back

=cut

# -----------------------------------------------------------------------------

sub case {
    my $self = shift;
    # @_: @keyVal,@opt -or- @keyVal,$else,@opt

    my $fmt = 'm';

    my $argA = $self->parameters(2,undef,\@_,
        -fmt => \$fmt,
    );

    my $expr = $self->expr(shift @$argA);

    my @else;
    if (@$argA % 2) {
        @else = ($self->valExpr(pop @$argA));
    }

    my $sql = "CASE $expr";
    while (@$argA) {
        my $when = $self->valExpr(shift @$argA);
        my $then = $self->valExpr(shift @$argA);
        
        $sql .= $fmt eq 'm'? "\n    ": ' ';
        $sql .= "WHEN $when THEN $then";
    }
    if (@else) {
        $sql .= $fmt eq 'm'? "\n    ": ' ';
        $sql .= "ELSE $else[0]";
    }
    $sql .= $fmt eq 'm'? "\n": ' ';
    $sql .= 'END';

    return $sql;
}

# -----------------------------------------------------------------------------

=head2 Elementare Ausdrücke

=head3 expr() - Erzeuge Ausdruck

=head4 Synopsis

  $sql = $s->expr($expr);
  $sql = $s->expr(\$val);

=head4 Arguments

=over 4

=item $expr

Ausdruck, der unverändert geliefert wird.

=item $val

Wert, der in ein SQL String-Literals gewandelt wird (siehe Methode
$s->L<stringLiteral|"stringLiteral() - Erzeuge String-Literal">()).

=back

=head4 Returns

Ausdruck oder String-Literal (String)

=head4 Description

Liefere den Ausdruck $expr oder den in den in ein Stringliteral
gewandelten Wert $val zurück.

=cut

# -----------------------------------------------------------------------------

sub expr {
    my ($self,$expr) = @_;

    my $refType = Quiq::Reference->refType($expr);
    if ($refType eq 'SCALAR') {
        return $self->stringLiteral($$expr);
    }

    return $expr;
}

# -----------------------------------------------------------------------------

=head3 valExpr() - Erzeuge Wert-Ausdruck

=head4 Synopsis

  $sql = $s->valExpr($val);
  $sql = $s->valExpr(\$expr);

=head4 Arguments

=over 4

=item $val

Wert, der in ein SQL String-Literals gewandelt wird (siehe Methode
$s->L<stringLiteral|"stringLiteral() - Erzeuge String-Literal">()).

=item $expr

Ausdruck, der unverändert geliefert wird.

=back

=head4 Returns

Stringliteral oder Ausdruck (String)

=head4 Description

Liefere den in den in ein Stringliteral gewandelten Wert $val
oder den Ausdruck $expr zurück.

=cut

# -----------------------------------------------------------------------------

sub valExpr {
    my ($self,$expr) = @_;

    my $refType = Quiq::Reference->refType($expr);
    if ($refType eq 'SCALAR') {
        return $$expr;
    }

    return $self->stringLiteral($expr);
}

# -----------------------------------------------------------------------------

=head3 stringLiteral() - Erzeuge String-Literal

=head4 Synopsis

  $sql = $s->stringLiteral($val);
  $sql = $s->stringLiteral($val,$default);

=head4 Arguments

=over 4

=item $val

Wert, der in ein SQL String-Literals gewandelt wird.

=item $default

Defaultwert, der in ein SQL String-Literals gewandelt wird.
Als Defaultwert kann auch ein Ausdruck angegeben werden,
der I<nicht> in ein Stringliteral gewandelt wird, wenn diesem
ein Backslash (\) vorangestellt wird.

=back

=head4 Returns

Stringliteral oder Ausdruck (String)

=head4 Description

Wandele den Wert $val in ein SQL-Stringliteral und liefere dieses
zurück. Hierbei werden alle in $str enthaltenen einfachen
Anführungsstriche verdoppelt und der gesamte String in einfache
Anführungsstriche eingefasst. Ist der String leer ('' oder undef)
liefere einen Leerstring (kein leeres String-Literal!). Ist
$default angegeben, liefere diesen Wert als Stringliteral.

B<Anmerkung>: PostgreSQL erlaubt aktuell Escape-Sequenzen in
String-Literalen. Wir behandeln diese nicht. Escape-Sequenzen sollten
in postgresql.conf abgeschaltet werden mit der Setzung:

  standard_conforming_strings = on

=head4 Examples

=over 2

=item *

Eingebettete Anführungsstriche

  $s->stringLiteral("Sie hat's");
  ==>
  "'Sie hat''s'"

=item *

Leerstring, wenn kein Wert

  $s->stringLiteral('');
  ==>
  ""

=item *

Defaultwert, wenn kein Wert

  $s->stringLiteral('','schwarz');
  ==>
  "'schwarz'"

=item *

Ausdruck als Defaultwert, wenn kein Wert

  $s->stringLiteral('',\'NULL');
  ==>
  "NULL"

=back

=cut

# -----------------------------------------------------------------------------

sub stringLiteral {
    my $self = shift;
    my $str = shift;
    # @_: $default

    if (!defined $str || $str eq '') {
        return @_? $self->valExpr(shift): '';
    }
    if ($self->isMySQL) {
        $str =~ s|\\|\\\\|g;
    }
    $str =~ s/'/''/g;

    return "'$str'";
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
