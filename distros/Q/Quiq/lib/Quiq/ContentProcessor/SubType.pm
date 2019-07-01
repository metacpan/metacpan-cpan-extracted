package Quiq::ContentProcessor::SubType;
use base qw/Quiq::ContentProcessor::BaseType/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ContentProcessor::SubType - Sub-Typ

=head1 BASE CLASS

L<Quiq::ContentProcessor::BaseType>

=head1 METHODS

=head2 Erzeugung

=head3 create() - Wandele Abschnitts-Objekt in Subtyp-Objekt

=head4 Synopsis

    $sty = $class->create($sec,$parent);

=head4 Arguments

=over 4

=item $sec

Referenz auf Abschnitts-Objekt.

=item $parent

Referenz auf übergeordnetes (Sub)Typ-Objekt.

=back

=head4 Returns

Zum Subtyp geblesstes Abschnitts-Objekt.

=head4 Description

Erweitere Abschnitts-Objekt $sec und blesse es zu einem Subtyp-Objekt.

=cut

# -----------------------------------------------------------------------------

sub create {
    my ($class,$sec,$parent) = splice @_,0,3;
    # @_: @keyVal

    # Inhalt und Abschnitts-Attribute prüfen
    $sec->validate($class->contentAllowed,scalar $class->attributes);
        
    $sec->set(
        parent => $parent,
        # memoize
        name => undef,
        # Subklassen-Attribute
        @_,
    );
    $sec->weaken('parent');
    
    return bless $sec,$class;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 name() - Name der Sub-Entität

=head4 Synopsis

    $name = $sty->name;

=head4 Description

Liefere den Namen der Sub-Entität. Dies ist der Wert
des Attributs C<Name:>, bereinigt um Besonderheiten:

=over 2

=item *

ein Sigil am Namensanfang (z.B. C<°°>) wird entfernt

=back

=cut

# -----------------------------------------------------------------------------

sub name {
    my $self = shift;

    return $self->memoize('name',sub {
        my ($self,$key) = @_;
        
        my ($name) = $self->get('Name');
        if (!$name) {
            $self->throw;
        }
        $name =~ s/^\W+//; # Sigil entfernen

        return $name;
    });
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.148

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
