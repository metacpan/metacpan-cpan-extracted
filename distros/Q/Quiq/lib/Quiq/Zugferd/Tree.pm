# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Zugferd::Tree - Operatonen auf ZUGFeRD-Baum

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein ZUGFeRD-Baum ist die Repräsentation von ZUGFeRD-XML in Form einer
Perl-Datenstruktur. Diese Repräsentation wird genutzt, um die XML-Struktur
geeignet bearbeiten zu können.

=cut

# -----------------------------------------------------------------------------

package Quiq::Zugferd::Tree;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Tree;
use Quiq::AnsiColor;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $ztr = $class->new($ref);

=head4 Description

Instantiiere einen ZUGFeRD-Baum und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$ref) = @_;
    return bless $ref,$class;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 getSubTree() - Liefere Mehrfach-Element

=head4 Synopsis

  $ztr = $ztr->getSubTree($keyPath,$placeholder)

=head4 Arguments

=over 4

=item $keyPath

Pfad zu Array

=item $placeholder

Name des Platzhalters

=back

=head4 Description

Liefere die Struktur, die das erste Element des Arrays iat, das
$keyPath referenziert, und ersetze die Referenz durch den Platzhalter
$placeholder.

=cut

# -----------------------------------------------------------------------------

sub getSubTree {
    my ($self,$keyPath,$placeholder) = @_;

    my $tree = $self->getDeep($keyPath)->[0];
    $self->setDeep($keyPath,$placeholder);

    return bless $tree,'Quiq::Zugferd::Tree';
}

# -----------------------------------------------------------------------------

=head3 reduceTree() - Reduziere den Baum

=head4 Synopsis

  $ztr->reduceTree;
  $ztr->reduceTree($sub);

=head4 Arguments

=over 4

=item $sub

Referenz auf Subroutine, die unaufgelöste Werte entfernt. Default:

  sub {
      my $val = shift;
      if (defined $val && $val =~ /^__\w+__$/) {
          $val = undef;
      }
      return $val;
  }

=back

=head4 Description

Reduziere den ZUGFeRD-Baum auf ein Minumum, d.h.

=over 2

=item *

Entferne alle Knoten mit unaufgelösten Werten

=item *

Entferne alle leeren Knoten

=back

=cut

# -----------------------------------------------------------------------------

sub reduceTree {
    my ($self,$sub) = @_;

    # Entferne Knoten mit unaufgelösten Werten (Default: ___XXX__ Platzhalter)

    $sub //= Quiq::Tree->setLeafValue($self,sub {
        my $val = shift;
        if (defined $val && $val =~ /^__\w+__$/) {
            $val = undef;
        }
        return $val;
    });

    # Entferne alle leeren Knoten
    Quiq::Tree->removeEmptyNodes($self);

    return;
}

# -----------------------------------------------------------------------------

=head3 resolvePlaceholders() - Ersetze Platzhalter

=head4 Synopsis

  $ztr->resolvePlaceholders(@keyVal,%options);

=head4 Arguments

=over 4

=item @keyVal

Liste der Platzhalter und ihrer Werte

=back

=head4 Options

=over 4

=item -label => $text (Default: '')

Versieh den Abschnitt der Platzhalter (bei -showPlaceHolders=>1) mit
der Beschriftung $label.

=item -showPlaceholders => $bool (Default: 0)

Gibt die Liste der Platzhalter auf STDOUT aus

=back

=head4 Description

Durchlaufe den ZUGFeRD-Baum rekursiv und ersetze auf den Blattknoten
die Keys durch ihre Werte. Blattknoten-Werte, die unter den Keys
nicht vorkommen, werden auf C<undef> gesetzt (und ggf. später durch
reduceTree() entfernt).

Fehlt einer der Platzhalter (key) im Baum oder kommen Platzhalter
mehrfach vor, wird eine Exception geworfen.

=cut

# -----------------------------------------------------------------------------

my $a = Quiq::AnsiColor->new(1);

sub resolvePlaceholders {
    my $self = shift;
    # @_: $zug,@keyVal,%options

    # Optionen und Argumente
    
    my $label = '';
    my $showPlaceholders = 0;
    
    my $argA = $self->parameters(0,undef,\@_,
       -label => \$label,
       -showPlaceholders => \$showPlaceholders,
    );
    # @$argA;
    
    if ($showPlaceholders) {
        say "--$label--";
        for (my $i = 0; $i < @$argA; $i += 2) {
            my $key = $argA->[$i];
            my $val = $argA->[$i+1];
            printf "%s = %s %s\n",$key,defined($val)? "'$val'": 'undef',
                $a->str('dark green','?'); # $zug->bt($key)->text);
        }
        print "\n";
    }

    # my %map = @_;
    my %map = @$argA;

    # Operation ausführen

    if (0) { # Debug
        my @keys = map {$_->[0]}
            sort {$a->[1] <=> $b->[1] or $a->[0] cmp $b->[0]}
            map {[$_,/-(\d+)/]}
            keys %map;
        for my $key (@keys) {
            say "$key => $map{$key}";
        }
    }

    # * Prüfe, dass kein Schlüssel doppelt vorkommen

    my %seen; # gesehene Platzhalter
    my @arr; # doppelte Platzhalter
    for (my $i = 0; $i < @_; $i += 2) {
        my $key = $_[$i];
        if (exists $seen{$key}) {
            push @arr,$key;
        }
        $seen{$key} = 0;
    }

    if (@arr) {
        $self->throw(
            'TREE-00099: Duplicate placeholders',
            Placeholders => join(', ',@arr),
        );
    }

    # Ersetze Platzhalter

    Quiq::Tree->setLeafValue($self,sub {
        my $val = shift; # akt. Knotenwert
        if (defined $val) { # Wir ersetzen nur definierte Werte
            if (exists $map{$val}) { # wir haben einen Platzhalter-Knoten
                $seen{$val} = 1;
                my $newVal = $map{$val}; # neuer Wert
                # Wir setzen den neuen Wert nur, wenn er nicht leer ist
                if (defined($newVal) && $newVal ne '') {
                    return $newVal;
                }
            }
        }
        return undef;
    });

    # Prüfe, dass wir alle Platzhalter ersetzt haben

    @arr = (); # nicht gefundene Platzhalter
    for my $key (keys %map) {
        if (!$seen{$key}) {
            push @arr,$key;
        }
    }
    if (@arr) {
        $self->throw(
            'TREE-00099: Non-existent Placeholders',
            Placeholders => join('. ',@arr),
        );
    }

    return;
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
