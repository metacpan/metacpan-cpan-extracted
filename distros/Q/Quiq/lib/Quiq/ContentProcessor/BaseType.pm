# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ContentProcessor::BaseType - Gemeinsame Funktionalität aller Entitäten (abstrakte Basisklasse)

=head1 BASE CLASSES

=over 2

=item *

L<Quiq::Section::Object>

=item *

L<Quiq::ClassConfig>

=back

=head1 DESCRIPTION

Diese abstrakte Basisklasse enthält die gemeinsame Funktionalität
ihrer Subklassen.

=cut

# -----------------------------------------------------------------------------

package Quiq::ContentProcessor::BaseType;
use base qw/Quiq::Section::Object Quiq::ClassConfig/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Eigenschaften

=head3 attributes() - Liste der zulässigen Abschnitts-Attribute

=head4 Synopsis

  @attributes | $attributeA = $class->attributes;

=head4 Returns

Liste der Namen der Abschnitts-Attribute. Im Skalar-Kontext wird
eine Referenz auf die Liste geliefert.

=head4 Description

Ermittele die Liste der Namen der zulässigen Abschnitts-Attribute
entlang der Klassenhierarchie und liefere diese zurück. Die
Liste ist alphabetisch sortiert.

=cut

# -----------------------------------------------------------------------------

sub attributes {
    my $class = shift;

    my $a = $class->defMemoize('attributes',sub {
        my ($class,$key) = @_;

        my $a = $class->defCumulate('Attributes');
        @$a = sort @$a;
        return $a;
    });

    return wantarray? @$a: $a;
}

# -----------------------------------------------------------------------------

=head3 contentAllowed() - Inhalt im Abschnitt erlaubt?

=head4 Synopsis

  $bool = $class->contentAllowed;

=head4 Returns

Boolscher Wert

=head4 Description

Ermittele, ob Abschnitte des Entitätstyps einen Inhalt haben dürfen.
Wenn ja, liefert die Methode 1, andernfalls 0.

=cut

# -----------------------------------------------------------------------------

sub contentAllowed {
    my $class = shift;

    return $class->defMemoize('contentAllowed',sub {
        my ($class,$key) = @_;
        return $class->defSearch('ContentAllowed');
    });
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
