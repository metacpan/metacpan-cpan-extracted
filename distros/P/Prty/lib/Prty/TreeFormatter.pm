package Prty::TreeFormatter;
use base qw/Prty::Hash/;

use strict;
use warnings;

our $VERSION = 1.122;

use Prty::Option;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::TreeFormatter - Erzeugung von Baumdarstellungen

=head1 BASE CLASS

L<Prty::Hash>

=head1 SYNOPSIS

Der Code

    use Prty::TreeFormatter;
    
    my $t = Prty::TreeFormatter->new([
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

    +--A
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
Baumstruktur wird als eine Liste von Paaren an den Konstruktor
übergeben. Ein Paar besteht aus der Angabe des Knotens und seiner
Ebene [$level, $node]. Der Knoten $node kann ein Objekt oder ein
Text sein. Die Ebene $level ist eine natürliche Zahl im
Wertebereich von 0 (Wurzelknoten) bis n. Die Paar-Liste kann aus
irgendeiner Baumstruktur mit einer rekursiven Funktion erzeugt werden
(siehe Abschnitt L</EXAMPLE>).

=head1 EXAMPLE

=head2 Baumknoten als Texte

Siehe L</SYNOPSIS>.

=head2 Baumknoten als Objekte

Hier ein Beispiel für eine rekursive Methode einer Anwendung, die
eine Klassenhierarchie für eine bestimmte Klasse ($self)
ermittelt. Die Methode liefert die Klassenhierarchie als
Paar-Liste für Prty::TreeFormatter:

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

    my $cls = $cop->findEntity('Prty/ContentProcessor/Type');
    my $arrA = $cls->classHierarchy;
    print Prty::TreeFormatter->new($arrA)->asText(
        -getText => sub {
            my $cls = shift;
    
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

    +--Prty/ContentProcessor/Type
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
       +--Yeah/Type
          |
          +--Yeah/Type/Export
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
          +--Yeah/Type/Language
          |
          +--Yeah/Type/Library
          |
          +--Yeah/Type/Package
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

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Baum-Objekt

=head4 Synopsis

    $t = $class->new(\@pairs);

=head4 Arguments

=over 4

=item @pairs

Liste von Paaren [$level, $node].

=back

=head4 Returns

Referenz auf Baum-Objekt.

=head4 Description

Instantiiere ein Baum-Objekt und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$pairA) = @_;

    # Paare in interne Liste umkopieren. Die interne Liste besitzt
    # ein weiteres Feld mit einem "Verbindungskennzeichen". Die
    # Felder: Level, Verbindungskennzeichen, Knoten (Objekt oder Text).
    # Das Verbindungskennzeichen gibt an, ob ein Folgeknoten auf
    # gleicher Ebene vorhanden ist. Wir initialisieren dessen Wert
    # hier auf 0.

    my @arr;
    for my $p (@$pairA) {
        # [$level,$follow,$node]
        push @arr,[$p->[0],0,$p->[1]];
    }

    # Setze die Kolumne mit Verbindungs-Kennzeichen auf 1, wenn
    # ein Folgeknoten gleicher Ebene existiert, ohne dass ein
    # Knoten einer niedrigeren Ebene dazwischen liegt.

    for (my $i = 0; $i < @arr-1; $i++) {
        my $iLevel = $arr[$i][0];
        for (my $j = $i+1; $j < @arr; $j++) {
            my $jLevel = $arr[$j][0];
            if ($jLevel == $iLevel) {
               $arr[$i][1] = 1;
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

    $str = $class->asText(@opt);

=head4 Options

=over 4

=item -format => 'debug'|'compact'|'tree' (Default: 'tree')

Format der Ausgabe (s.u.)

=item -getText => sub { my $node = shift; ... return $text }

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
    2 1     C
    3 0       D
    2 1     E
    2 0     F
    3 0       G
    4 0         H
    1 1   I
    1 1   J
    2 1     K
    2 0     L
    1 0   M
    2 0     N

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

    +--A
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

    my $format = 'tree';
    my $getText = sub {return shift};

    Prty::Option->extract(\@_,
        -format => \$format,
        -getText => \$getText,
    );

    my $str = '';
    my $lineA = $self->get('lineA');

    if ($format eq 'tree') {
        # Array, das für jede Einrückungsspalte angibt, ob dort eine
        # Verbindungslinie geführt wird.
        my @follow;

        for (my $i = 0; $i < @$lineA; $i++) {
            my ($level,$follow,$node) = @{$lineA->[$i]};
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
            # existiert. Y ist dann ein |, wenn das Verbindugskennzeichen
            # für Ebene $level gesetzt ist, sonst ein Leerzeichen.
            # X existiert nicht beim ersten Knoten, sonst ist X
            # konstant ein |.

            my ($line1,$rest) = split /\n/,$getText->($node),2;
            my $block = sprintf "%s+--%s\n",$i? "|\n": '',$line1;

            if ($rest) {
                if ($follow[$level]) {
                    $rest =~ s/^/|  /mg;
                }
                else {
                    $rest =~ s/^/   /mg;
                }
                $block .= $rest;
            }

            # Einrückungs-Block und Knoten-Block zusammenfügen

            $block =~ s/^/$indent/mg;
            $str .= $block;
        }
    }
    elsif ($format eq 'debug') {
        for (@$lineA) {
            my ($level,$follow,$node) = @$_;
            $str .= sprintf "%d %d %s%s\n",
                $level,
                $follow,
                '  ' x $level,
                $node;
        }
    }
    elsif ($format eq 'compact') {
        for (@$lineA) {
            my ($level,$follow,$node) = @$_;
            my ($line1,$rest) = split /\n/,$getText->($node),2;
            $str .= sprintf "%s%s\n",'  ' x $level,$line1;
        }
    }
    else {
        $self->throw(
            q~TREE-FORMATTER-00001: Unknown format~,
            Format => $format,
        );
    }
    
    return $str;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.122

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2018 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
