# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Tree - Operatonen auf Baumstrukturen

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::Tree;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.223';

use Scalar::Util ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Methoden

=head3 leafPaths() - Liste der Pfade

=head4 Synopsis

  @paths|$pathA = $class->leafPaths($ref);

=head4 Arguments

=over 4

=item $ref

Referenz auf hierarchische Datenstruktur

=back

=head4 Description

Liefere die Liste der Pfade zu den Blattknoten der Datenstruktur $ref.
Diese Liste kann nützlich sein, um die Zugriffspfade zu den Blättern
einer hierarchischen Datenstruktur zu ermitteln.

=cut

# -----------------------------------------------------------------------------

sub leafPaths {
    my ($class,$ref,$path) = @_;

    $path //= '';
    my @paths;

    my $type = Scalar::Util::reftype($ref);
    if (!defined $type) {
        return $path;
    }
    elsif ($type eq 'HASH') {
        for my $key (keys %$ref) {
            push @paths,$class->leafPaths($ref->{$key},$path? "$path.$key": $key);
        }
    }
    elsif ($type eq 'ARRAY') {
        my $i = 0;
        for my $e (@$ref) {
            push @paths,$class->leafPaths($ref->[$i],"$path.[$i]");
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

Ein Blattknoten ist leer, wenn wenn sein Wert C<undef> ist.

Ein Hashknoten ist leer, wenn der Hash kein Element enthält.

Ein Arrayknoten ist leer, wenn er kein Element enthält.

=cut

# -----------------------------------------------------------------------------

sub removeEmptyNodes {
    my $class = shift;
    my $ref = $_[0];

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
                $n += $class->removeEmptyNodes($ref->{$key});
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
                $n += $class->removeEmptyNodes($ref->[$i]);
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
"einfachen" skalaren Wert besitzt, also auf keine Substruktur verweist
(Hash- oder Array-Referenz).

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

=head3 substitutePlaceholders() - Ersetze Platzhalter

=head4 Synopsis

  $class->substitutePlaceholders($ref,@keyVal);

=head4 Arguments

=over 4

=item $ref

Referenz auf hierarchische Datenstruktur

=item @kayVal

Liste der Platzhalter und ihrer Werte

=back

=head4 Description

Durchlaufe die Datenstruktur $ref rekursiv und ersetze auf den Blattknoten
die Platzhalter durch ihre Werte.

=cut

# -----------------------------------------------------------------------------

sub substitutePlaceholders {
    my $class = shift;
    my $ref = shift;
    # @_: @keyVal

    my %map = @_;
    $class->setLeafValue($ref,sub {
        my $val = shift;
        return defined $val? $map{$val} // $val: undef;
    });

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.223

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2024 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
