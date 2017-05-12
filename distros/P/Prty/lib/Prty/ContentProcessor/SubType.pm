package Prty::ContentProcessor::SubType;
use base qw/Prty::Section::Object Prty::ClassConfig/;

use strict;
use warnings;

our $VERSION = 1.106;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::ContentProcessor::SubType - Basisklasse für Sub-Typen

=head1 BASE CLASSES

=over 2

=item *

L<Prty::Section::Object>

=item *

L<Prty::ClassConfig>

=back

=head1 METHODS

=head2 Erzeugung

=head3 create() - Wandele Abschnitts-Objekt in Subtyp-Objekt

=head4 Synopsis

    $sty = $class->create($sec,$parent);

=head4 Description

Erweitere Abschnitts-Objekt $sec und blesse es zu einem Subtyp-Objekt.

=head4 Arguments

=over 4

=item $sec

Referenz auf Abschnitts-Objekt.

=item $parent

Referenz auf übergeordnetes (Sub)Typ-Objekt.

=back

=head4 Returns

Zum Subtyp geblesstes Abschnitts-Objekt.

=cut

# -----------------------------------------------------------------------------

sub create {
    my ($class,$sec,$parent) = splice @_,0,3;
    # @_: @keyVal

    # Inhalt und Abschnitts-Attribute prüfen
    $sec->validate($class->contentAllowed,scalar $class->attributes);
        
    $sec->set(
        parent=>$parent,
        # Subklassen-Attribute
        @_,
    );
    $sec->weaken('parent');
    
    return bless $sec,$class;
}

# -----------------------------------------------------------------------------

=head2 Intern

=head3 attributes() - Liste der zulässigen Abschnitts-Attribute

=head4 Synopsis

    @attributes | $attributeA = $class->attributes;

=head4 Description

Ermittele die Liste der Namen der zulässigen Abschnitts-Attribute
entlang der Klassenhierarchie und liefere diese zurück. Die
Liste ist alphabetisch sortiert.

=head4 Returns

Liste der Namen der Abschnitts-Attribute. Im Skalar-Kontext wird
eine Referenz auf die Liste geliefert.

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

=head4 Description

Ermittele, ob Abschnitte des Entitätstyps einen Inhalt haben dürfen.
Wenn ja, liefert die Methode 1, andernfalls 0.

=head4 Returns

Boolscher Wert

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

1.106

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2017 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
