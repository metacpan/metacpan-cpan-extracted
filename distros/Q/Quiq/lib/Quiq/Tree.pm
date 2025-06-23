# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Tree - Operatonen auf Perl-Baumstrukturen

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Diese Klasse stellt Methoden zur Verfügung, um auf beliebigen
baumartigen Perl-Datenstrukturen operieren zu können. D.h. der
Baum wird als Datenstruktur aus Hashes und Arrays angesehen - ohne dass
die Knoten einer bestimmten Klasse angehören müssen. Die Klasse
besitzt daher ausschließlich Klassenmethoden. Der erste Parameter jeder
Klassenmethode ist eine Referenz auf den Wurzelknoten des Baums.

=cut

# -----------------------------------------------------------------------------

package Quiq::Tree;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Scalar::Util ();
use Quiq::AnsiColor;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 blessNodes() - Blesse Knotentypen auf bestimmte Klassen

=head4 Synopsis

  $class->blessNodes($ref,{$type=>$class,...});

=head4 Arguments

=over 4

=item $ref

Referenz auf hierarchische Datenstruktur

=item {$type=>$class,...}

Abbildung von Typ $type auf Klasse $class

=back

=head4 Description

Durchlaufe die Datenstruktur $ref rekursiv und blesse Knoten
vom Typ $type auf Klasse $class.

=head4 Example

  $class->blessNodes($ref,{
      HASH => 'Quiq::Hash',
      ARRAY => 'Quiq::Array',
  });

=cut

# -----------------------------------------------------------------------------

sub blessNodes {
    my ($class,$ref,$typeH) = @_;

    my $type = Scalar::Util::reftype($ref);
    if (!defined $type) { # Terminaler Knoten
        # nichts tun
        return;
    }
    if (my $nodeClass = $typeH->{$type}) {
        $ref = bless $ref,$nodeClass;
    }
    if ($type eq 'HASH') {
        for my $key (keys %$ref) {
            $class->blessNodes($ref->{$key},$typeH);
        }
    }
    elsif ($type eq 'ARRAY') {
        for my $e (@$ref) {
            $class->blessNodes($e,$typeH);
        }
    }
    else {
        $class->throw(
            'TREE-00099: Unknown reference type',
            Reference => "$ref",
            Type => $type,
        );
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 leafPaths() - Liste der Pfade

=head4 Synopsis

  @paths|$pathA = $class->leafPaths($ref);

=head4 Arguments

=over 4

=item $ref

Referenz auf den Baum

=back

=head4 Returns

(Array of Pairs) Liste der Pfade. Im Skalarkontext wird eine Referenz auf die
Liste geliefert.

=head4 Description

Liefere die Liste der Pfade [$path,$value] zu den Blattknoten des Baums $ref.
Diese Liste ist nützlich, um die Zugriffspfade zu den Blattknoten
zu ermitteln.

=cut

# -----------------------------------------------------------------------------

my $a = Quiq::AnsiColor->new(1);

sub leafPaths {
    my ($class,$ref,$path) = @_;

    $path //= '';
    my @paths;

    my $type = Scalar::Util::reftype($ref);
    if (!defined $type) {
        $ref //= '';
        $ref =~ s/\n/\\n/g;
        # return "$path ".$a->str('cyan',$ref); # Pfad und terminaler skalarer Wert
        return [$path,$ref]; # ".$a->str('cyan',$ref); # Pfad und terminaler skalarer Wert
    }
    elsif ($type eq 'HASH') {
        for my $key (keys %$ref) {
            push @paths,$class->leafPaths($ref->{$key},$path? "$path.$key": $key);
        }
    }
    elsif ($type eq 'ARRAY') {
        my $i = 0;
        for my $e (@$ref) {
            push @paths,$class->leafPaths($ref->[$i],$path? "$path.[$i]": "[$i]");
            $i++;
        }
    }
    else {
        $class->throw(
            'TREE-00099: Unknown reference type',
            Reference => "$ref",
            Type => $type,
        );
    }

    return wantarray? @paths: \@paths;
}

# -----------------------------------------------------------------------------

=head3 removeEmptyNodes() - Entferne alle leeren Knoten

=head4 Synopsis

  $class->removeEmptyNodes($ref);

=head4 Arguments

=over 4

=item $ref

Referenz auf hierarchische Datenstruktur

=back

=head4 Description

Durchlaufe die Datenstruktur $ref rekursiv und entferne alle leeren
Knoten.

=over 2

=item *

Ein Blattknoten ist leer, wenn wenn sein Wert C<undef> ist.

=item *

Ein Hashknoten ist leer, wenn er kein Element enthält.

=item *

Ein Arrayknoten ist leer, wenn er kein Element enthält.

=back

=cut

# -----------------------------------------------------------------------------

sub removeEmptyNodes {
    my ($class,$ref) = @_;

    # Durchlaufe den Baum so lange immmer wieder rekursiv,
    # bis keine Knoten mehr entfernt werden

    my $n = 0;
    do {
        $n = $class->removeEmptyNodesRecursive($ref);
    } while $n;

    return;
}

# -----------------------------------------------------------------------------

=head3 removeEmptyNodesRecursive() - Entferne leere Knoten

=head4 Synopsis

  $class->removeEmptyNodesRecursive($ref);

=head4 Arguments

=over 4

=item $ref

Referenz auf Baum

=back

=head4 Description

Interne Methode, die den Baum rekursiv durchläuft und die leeren Knoten
entfernt. Es sind i.d.R. mehrere Durchläufe nötig, um I<alle> leeren
Knoten zu entfernen, siehe $class->removeEmptyNodes().

=cut

# -----------------------------------------------------------------------------

sub removeEmptyNodesRecursive {
    my $class = shift;
    my $ref = $_[0];

    if (!defined $ref) {
        # Kein Baum (mehr)
        return 0;
    }

    my $n = 0;

    my $type = Scalar::Util::reftype($ref);
    if ($type eq 'HASH') {
        my @keys = keys %$ref;
        for my $key (@keys) {
            if (!defined Scalar::Util::reftype($ref->{$key})) {
                if (!defined $ref->{$key}) {
                    delete $ref->{$key};
                    $n++;
                }
            }
            else {
                $n += $class->removeEmptyNodesRecursive($ref->{$key});
            }
        }
        if (!keys %$ref) {
            $_[0] = undef;
            $n++;
        }
    }
    elsif ($type eq 'ARRAY') {
        for (my $i = 0; $i < @$ref; $i++) {
            if (!defined Scalar::Util::reftype($ref->[$i])) {
                if (!defined $ref->[$i]) {
                    splice @$ref,$i--,1;
                    $n++;
                }
            }
            else {
                $n += $class->removeEmptyNodesRecursive($ref->[$i]);
            }
        }
        if (!@$ref) {
            $_[0] = undef;
            $n++;
        }
    }
    else {
        $class->throw(
            'TREE-00099: Unknown reference type',
            Reference => "$ref",
            Type => $type,
        );
    }

    return $n;
}

# -----------------------------------------------------------------------------

=head3 setLeafValue() - Setze den Wert von Blattknoten

=head4 Synopsis

  $class->setLeafValue($ref,$sub);

=head4 Arguments

=over 4

=item $ref

Referenz auf hierarchische Datenstruktur

=item $sub

Referenz auf Subroutine, die für jeden Blattknoten gerufen wird.

=back

=head4 Description

Durchlaufe die Datenstruktur $ref rekursiv, rufe auf allen Blattknoten
die Subroutine $sub mit dem aktuellen Wert des Knotens auf und setze
auf dem Knoten den gelieferten Wert.

Ein Blattknoten des Baums ist dadurch gekennzeichner, dass er einen
"einfachen" skalaren Wert besitzt, also auf keine Substruktur
(Hash- oder Array-Referenz) verweist.

=cut

# -----------------------------------------------------------------------------

sub setLeafValue {
    my ($class,$ref,$sub) = @_;

    my $type = Scalar::Util::reftype($ref);
    if ($type eq 'HASH') {
        for my $key (keys %$ref) {
            if (!defined Scalar::Util::reftype($ref->{$key})) {
                $ref->{$key} = $sub->($ref->{$key});
            }
            else {
                $class->setLeafValue($ref->{$key},$sub);
            }
        }
    }
    elsif ($type eq 'ARRAY') {
        for my $e (@$ref) {
            if (!defined Scalar::Util::reftype($e)) {
                $e = $sub->($e);
            }
            else {
                $class->setLeafValue($e,$sub);
            }
        }
    }
    else {
        $class->throw(
            'TREE-00099: Unknown reference type',
            Reference => "$ref",
            Type => $type,
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
