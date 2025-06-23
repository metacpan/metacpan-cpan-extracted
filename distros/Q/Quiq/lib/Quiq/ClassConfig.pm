# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ClassConfig - Verwalte Information auf Klassenebene

=head1 SYNOPSIS

Klasse einbinden:

  use base qw/... Quiq::ClassConfig/;

Information definieren (Anwendungsbeispiel):

  package Model::Object;
  
  __PACKAGE__->def(
      table => 'Object',
      prefix => 'Obj',
      columns => [
          id => {
              domain => 'Integer',
              primaryKey => 1,
              notNull => 1,
              description => 'Primärschlüssel',
          },
          ...
      ],
      ...
  );

Information abfragen:

  my $table = Model::Object->defGet('table');
  =>
  Object

Information suchen:

  my $table = Model::Object->defSearch('table');
  =>
  Object

=head1 DESCRIPTION

Die Klasse ermöglicht, Information in Klassen zu hinterlegen und
abzufragen. Anstatt hierfür Klassenvariablen mit C<our> zu
definieren, verwaltet die Klasse sämliche Information in einem
einzigen Hash (je Klasse natürlich) mit dem Namen
C<%ClassConfig>. Die Methoden der Klasse verwalten (erzeugen,
setzen, lesen) diesen Hash.

=cut

# -----------------------------------------------------------------------------

package Quiq::ClassConfig;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Perl;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Information definieren

=head3 def() - Definiere/Setze Klassen-Information

=head4 Synopsis

  $h = $class->def(@keyVal);

=head4 Arguments

=over 4

=item @keyVal

Liste der Schlüssel/Wert-Paare

=back

=head4 Returns

Referenz auf den Hash

=head4 Description

Erzeuge einen globalen Hash in Klasse $class und weise diesem die
Schlüssel/Wert-Paare @keyVal zu. Existiert der Hash bereits,
wird er nicht neu erzeugt.

=cut

# -----------------------------------------------------------------------------

sub def {
    my $class = shift;
    # @_: @keyVal

    no strict 'refs';
    my $h = *{$class.'::ClassConfig'}{HASH};
    if (!$h) {
        *{$class.'::ClassConfig'} = $h = {};
    }

    while (@_) {
        my $key = shift;
        $h->{$key} = shift;
    }

    return $h;
}

# -----------------------------------------------------------------------------

=head2 Information abfragen

=head3 defGet() - Liefere Klassen-Information

=head4 Synopsis

  $val = $class->defGet($key);
  @vals = $class->defGet(@keys);

=head4 Arguments

=over 4

=item $key bzw. @keys

Schlüssel bzw. Liste von Schlüsseln.

=back

=head4 Returns

=over 4

=item $val bzw. @vals

Wert bzw. Liste von Werten.

=back

=head4 Description

Liefere die Werte zu den Schlüsseln @keys. Im Skalarkontext
liefere den Wert des ersten Schlüssels.

=cut

# -----------------------------------------------------------------------------

sub defGet {
    my $class = shift;
    # @_: @keys

    no strict 'refs';
    my $ref = *{$class.'::ClassConfig'}{HASH};

    my @arr;
    while (@_) {
        my $key = shift;
        CORE::push @arr,$ref? $ref->{$key}: undef;
    }

    return wantarray? @arr: $arr[0];
}

# -----------------------------------------------------------------------------

=head3 defMemoize() - Berechne und chache Klassen-Information

=head4 Synopsis

  $val = $class->defMemoize($key,$sub);

=head4 Arguments

=over 4

=item $key

Schlüssel

=item $sub

Subroutine, die den Wert berechnet. Diese hat den Aufbau

  sub {
      my ($class,$key) = @_;
      ...
      return $val;
  }

=back

=head4 Returns

=over 4

=item $val

Berechneter bzw. gecachter Wert

=back

=head4 Description

Berechne den Wert per Subroutine $sub, speichere ihn unter dem
Schlüssel $key und liefere ihn schließlich zurück. Der Wert wird
nur beim ersten Aufruf berechnet, danach wird der gespeicherte
Wert unmittelbar geliefert.

=cut

# -----------------------------------------------------------------------------

sub defMemoize {
    my ($class,$key,$sub) = @_;

    my $h = $class->def; # Hash wird erzeugt, wenn er nicht existiert
    return $h->{$key} //= $class->$sub($key);
}

# -----------------------------------------------------------------------------

=head2 Information suchen

=head3 defSearch() - Suche Klassen-Information in Vererbungshierarchie

=head4 Synopsis

  $val = $class->defSearch($key);

=head4 Arguments

=over 4

=item $key

Schlüssel der Information.

=back

=head4 Returns

Die gesuchte Information oder C<undef>.

=head4 Description

Suche "von unten nach oben" in der Vererbungshierarchie, beginnend
mit Klasse $class, die Information $key. Die erste Klasse, die die
Information besitzt, liefert den Wert. Existiert die Information
nicht, wird C<undef> geliefert.

=cut

# -----------------------------------------------------------------------------

sub defSearch {
    my ($class,$key) = @_;

    no strict 'refs';
    for my $class ($class,Quiq::Perl->baseClassesISA($class)) {
        my $ref = *{$class.'::ClassConfig'}{HASH};
        if ($ref && exists $ref->{$key}) {
            return $ref->{$key};
        }
    }

    return undef;
}

# -----------------------------------------------------------------------------

=head3 defCumulate() - Sammele Klassen-Information entlang Vererbungshierarchie

=head4 Synopsis

  @arr | $arr = $class->defCumulate($key);

=head4 Arguments

=over 4

=item $key

Schlüssel der Information.

=back

=head4 Returns

Liste der Werte. Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Durchlaufe die Klassenhierarchie I<von oben nach unten> und sammele
alle Werte des Attributs $key ein und liefere die Liste der
Werte zurück.

Diese Methode ist nützlich, wenn z.B. Attributnamen entlang
einer Vererbungshierarchie definiert werden (je höher die Klasse
desto allgemeiner das Attribut) und für eine gegebene Klasse
die Liste der Attributnamen bestimmt werden soll.

=head4 Example

Klassenhierarchie:

  package Object;
  use base/Quiq::ClassConfig/;
  
  __PACKAGE__->def(
      Attributes => [qw/
          Id
      /],
  );
  
  package Person;
  use base qw/Object/;
  
  __PACKAGE__->def(
      Attributes => [qw/
          Vorname
          Nachname
      /],
  );

Attributes der Klasse Person:

  @attributes = Person->defCumulate('Attributes');
  =>
  ('Id', 'Vorname', 'Nachname')

=cut

# -----------------------------------------------------------------------------

sub defCumulate {
    my ($class,$key) = @_;

    no strict 'refs';

    my @arr;
    for my $class (reverse(Quiq::Perl->baseClassesISA($class)),$class) {
        my $ref = *{$class.'::ClassConfig'}{HASH};
        if ($ref && exists $ref->{$key}) {
            my $val = $ref->{$key};
            push @arr,ref $val? @$val: $val;
        }
    }

    return wantarray? @arr: \@arr;
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
