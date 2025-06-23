# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::TreeFormatter - Erzeugung von Baumdarstellungen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

Der Code

  use Quiq::TreeFormatter;
  
  my $t = Quiq::TreeFormatter->new([
      [0,'A'],
      [1,'B'],
      [2,'C'],
      [3,'D'],
      [2,'E'],
      [2,'F'],
      [3,'G'],
      [4,'H'],
      [1,'I'],
      [1,'J'],
      [2,'K'],
      [2,'L'],
      [1,'M'],
      [2,'N'],
  ]);
  
  print $t->asText;

produziert

  A
  |
  +--B
  |  |
  |  +--C
  |  |  |
  |  |  +--D
  |  |
  |  +--E
  |  |
  |  +--F
  |     |
  |     +--G
  |        |
  |        +--H
  |
  +--I
  |
  +--J
  |  |
  |  +--K
  |  |
  |  +--L
  |
  +--M
     |
     +--N

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Baum, der mit
Methoden der Klasse dargestellt (visualisiert) werden kann. Die
Baumstruktur wird als eine Liste von (minestens zweielementigen) Tupeln
[$level,$node,...] an den Konstruktor übergeben. Ein Tupel besteht aus der
Angabe der Ebene des Knotens, des Knotens selbst und optional weiteren
- frei definierbaren - Informationen, z.B. ob der Subbaum des Knotens
ausgeblendet wurde. Die zusätzliche Information kann in der
getText-Callback-Methode genutzt werden, um den betreffenden Knoten
besonders darzustellen. Der Knoten $node kann ein Objekt oder ein Text
sein. Die Ebene $level ist eine natürliche Zahl im Wertebereich von
0 (Wurzelknoten) bis n. Die Paar-Liste kann aus irgendeiner Baumstruktur
mit einer rekursiven Funktion erzeugt werden (siehe Abschnitt L<EXAMPLE|"EXAMPLE">).

=head1 EXAMPLE

=head2 Baumknoten als Texte

Siehe SYNOPSIS.

=head2 Rekursive Methode mit Stop-Kennzeichen

Die folgende Methode erkennt, wenn ein Knoten wiederholt auftritt,
kennzeichnet diesen mit einem Stop-Kennzeichen und steigt dann
nicht in den Subbaum ab. Dies verhindert redundante Baumteile
und u.U. eine Endlos-Rekursion (wenn die Wiederholung auf einem
Pfad vorkommt).

  sub hierarchy {
      my $self = shift;
      my $stopH = shift || {};
  
      my $stop = $stopH->{$self}++;
      if (!$stop) {
          my @arr;
          for my $node ($self->subNodes) {
              push @arr,map {$_->[0]++; $_} $node->hierarchy($stopH);
          }
      }
      unshift @arr,[0,$self,$stop];
  
      return wantarray? @arr: \@arr;
  }

=head2 Baumknoten als Objekte

Hier ein Beispiel für eine rekursive Methode einer Anwendung, die
eine Klassenhierarchie für eine bestimmte Klasse ($self)
ermittelt. Die Methode liefert die Klassenhierarchie als
Paar-Liste für Quiq::TreeFormatter:

  sub classHierarchy {
      my $self = shift;
  
      my @arr;
      for my $cls ($self->subClasses) {
          push @arr,map {$_->[0]++; $_} $cls->classHierarchy;
      }
      unshift @arr,[0,$self];
  
      return wantarray? @arr: \@arr;
  }

Hier sind die Knoten $node Objekte, deren Text für die Darstellung
im Baum durch eine anonyme Subroutine produziert wird.
Die Subroutine wird mittels der Option C<-getText> an $t->asText()
übergeben:

  my $cls = $cop->findEntity('Quiq/ContentProcessor/Type');
  my $arrA = $cls->classHierarchy;
  print Quiq::TreeFormatter->new($arrA)->asText(
      -getText => sub {
          my ($cls,$level,$stop) = @_;
  
          my $str = $cls->name."\n";
          for my $grp ($cls->groups) {
              $str .= sprintf ": %s\n",$grp->title;
              for my $mth ($grp->methods) {
                  $str .= sprintf ":   %s()\n",$mth->name;
              }
          }
  
          return $str;
      },
  );

Ein Ausschnitt aus der produzierten Ausgabe:

  +--Quiq/ContentProcessor/Type
     : Erzeugung
     :   create()
     : Objektmethoden
     :   entityFile()
     :   entityId()
     :   entityType()
     :   files()
     :   fileSource()
     :   fileSourceRef()
     :   appendFileSource()
     :   name()
     :   pureCode()
     : Intern
     :   needsTest()
     :   needsUpdate()
     |
     +--Jaz/Type
        |
        +--Jaz/Type/Export
        |  : Erzeugung
        |  :   create()
        |  : Entitäten
        |  :   entities()
        |  : Reguläre Ausdrücke
        |  :   excludeRegex()
        |  :   selectRegexes()
        |  : Verzeichnisse
        |  :   adminDirectories()
        |  :   rootDirectory()
        |  : Verzeichnisse
        |  :   subDirectories()
        |  : Export
        |  :   rewriteRules()
        |  :   export()
        |
        +--Jaz/Type/Language
        |
        +--Jaz/Type/Library
        |
        +--Jaz/Type/Package
        |  : Erzeugung
        |  :   create()
        |  : Eigenschaften
        |  :   level()
        |  :   levelName()
        |  : Entitäten
        |  :   entities()
        |  :   hierarchy()
        |  :   package()
        |  :   subPackages()
        |  : Reguläre Ausdrücke
        |  :   regexes()
        |
        ...

=cut

# -----------------------------------------------------------------------------

package Quiq::TreeFormatter;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Option;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Baum-Objekt

=head4 Synopsis

  $t = $class->new(\@tuples);

=head4 Arguments

=over 4

=item @tuples

Liste von Tupeln [$level, $node, ...]. Die Komponenten ... werden
transparent weitergereicht.

=back

=head4 Returns

Referenz auf Baum-Objekt.

=head4 Description

Instantiiere ein Baum-Objekt und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$tupleA) = @_;

    # Tupel in interne Liste umkopieren. Die interne Liste besitzt
    # am Anfang ein weiteres Feld mit einem "Verbindungskennzeichen". Die
    # Felder Verbindungskennzeichen, Level, Knoten (Objekt oder Text),
    # und sonstige Infomation. Das Verbindungskennzeichen gibt an, ob ein
    # Folgeknoten auf gleicher Ebene vorhanden ist. Wir initialisieren
    # dessen Wert hier auf 0.

    my @arr;
    for (@$tupleA) {
        # [$follow,$level,$node,...]
        push @arr,[0,@$_];
    }

    # Setze die Kolumne mit Verbindungs-Kennzeichen auf 1, wenn
    # ein Folgeknoten gleicher Ebene existiert, ohne dass ein
    # Knoten einer niedrigeren Ebene dazwischen liegt.

    for (my $i = 0; $i < @arr-1; $i++) {
        my $iLevel = $arr[$i][1];
        for (my $j = $i+1; $j < @arr; $j++) {
            my $jLevel = $arr[$j][1];
            if ($jLevel == $iLevel) {
               $arr[$i][0] = 1;
               last;
            }
            elsif ($jLevel < $iLevel) {
               last;
            }
        }
    }

    return $class->SUPER::new(
        lineA => \@arr,
    );
}

# -----------------------------------------------------------------------------

=head2 Darstellung

=head3 asText() - Erzeuge Text-Repräsentation des Baums

=head4 Synopsis

  $str = $t->asText(@opt);

=head4 Options

=over 4

=item -format => 'debug'|'compact'|'tree' (Default: 'tree')

Format der Ausgabe (s.u.)

=item -getText => sub { my ($node,@args) = @_; ... return $text }

Callback-Funktion zum Ermitteln des Textes des Knotens. Der Text
kann mehrzeilig sein.

=back

=head4 Returns

Baumdarstellung (String)

=head4 Description

Erzeuge eine Text-Repräsentation des Baums und liefere diese zurück.

B<debug>

  0 0 A
  1 1   B
  1 2     C
  0 3       D
  1 2     E
  0 2     F
  0 3       G
  0 4         H
  1 1   I
  1 1   J
  1 2     K
  0 2     L
  0 1   M
  0 2     N

B<compact>

  A
    B
      C
        D
      E
      F
        G
          H
    I
    J
      K
      L
    M
      N

B<tree>

  A
  |
  +--B
  |  |
  |  +--C
  |  |  |
  |  |  +--D
  |  |
  |  +--E
  |  |
  |  +--F
  |     |
  |     +--G
  |        |
  |        +--H
  |
  +--I
  |
  +--J
  |  |
  |  +--K
  |  |
  |  +--L
  |
  +--M
     |
     +--N

=cut

# -----------------------------------------------------------------------------

sub asText {
    my $self = shift;
    # @_: @opt

    my $direction = 'down';
    my $format = 'tree';
    my $getText = sub {return shift};

    Quiq::Option->extract(\@_,
        -direction => \$direction,
        -format => \$format,
        -getText => \$getText,
    );

    my $lineA = $self->get('lineA');

    my $str = '';

    if ($format eq 'tree') {
        # Array, das für jede Einrückungsspalte angibt, ob dort eine
        # Verbindungslinie geführt wird.
        my @follow;

        for (my $i = 0; $i < @$lineA; $i++) {
            my ($follow,$level,$node,@args) = @{$lineA->[$i]};
            $follow[$level] = $follow; # Verbindungskennzeichen für $level

            # Einrückungs-Block erzeugen. Der Einrückungs-Block
            # enthält für jede Ebene 0 bis $level-1 Leerraum oder
            # eine Verbindungslinie gemäß dem Verbindungskennzeichen
            # $follow der betreffenden Ebene. Die Einrückung je
            # Ebene beträgt 3 Zeichen.

            my $indent = '';
            for (my $j = 0; $j < $level; $j++) {
                $indent .= $follow[$j]? '|  ': '   ';
            }

            # Knoten-Block erzeugen. Der Knoten-Block hat den Aufbau
            #
            #     X
            #     +--$line1
            #     Y  $rest
            #
            # wobei "Y  $rest" nur bei einem mehrzeiligen Knoten-Text
            # existiert. Y ist dann ein |, wenn das Verbindungskennzeichen
            # für Ebene $level gesetzt ist, sonst ein Leerzeichen.
            # X existiert nicht beim ersten Knoten, sonst ist X
            # konstant ein |. Bei Direction 'down' wird X oberhalb,
            # bei 'up' unterhalb des Blocks hinzugefügt.

            my ($line1,$rest) = split /\n/,$getText->($node,$level,@args),2;

            my $block = sprintf "+--%s\n",$line1;

            if ($rest) {
                if ($follow[$level]) {
                    $rest =~ s/^/|  /mg;
                }
                else {
                    $rest =~ s/^/   /mg;
                }
                $block .= $rest;
            }

            # Wenn 'down' setzen wir | auf die Zeile davor,
            # bei 'up' setzen wir | auf die Zeile danach.

            if ($i) {
                $block = $direction eq 'down'? "|\n$block": "$block|\n";
            }

            # Einrückungs-Block und Knoten-Block zusammenfügen

            $block =~ s/^/$indent/mg;

            if ($direction eq 'down') {
                $str .= $block;
            }
            else { # up
                $str = $block.$str;
            }
        }

        $str =~ s/^(\+--|   )//mg;
    }
    elsif ($format eq 'debug') {
        for (@$lineA) {
            my ($follow,$level,$node,@args) = @$_;
            $str .= sprintf "%d %d %s%s%s\n",
                $follow,
                $level,
                '  ' x $level,
                $getText->($node,$level,@args), # $node,
                @args? ' '.join('|',map {$_ // 'undef'} @args): '';
        }
    }
    elsif ($format eq 'compact') {
        for (@$lineA) {
            my ($follow,$level,$node,@args) = @$_;
            my ($line1,$rest) = split /\n/,$getText->($node,$level,@args),2;
            my $block = sprintf "%s%s\n",'  ' x $level,$line1;
            if ($direction eq 'down') {
                $str .= $block;
            }
            else { # up
                $str = $block.$str;
            }
        }
    }
    else {
        $self->throw(
            'TREE-FORMATTER-00001: Unknown format',
            Format => $format,
        );
    }

    return $str;
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
