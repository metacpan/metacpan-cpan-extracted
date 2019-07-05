package Quiq::ModelCache;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ModelCache - Verwaltung/Caching von Modell-Objekten

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

Instantiiere das Modell-Objekt für eine Reihe von Tabellen:

    $mod = Quiq::ModelCache->new($db,@types);

Liefere alle Datensätze einer Tabelle:

    @rows|$tab = $mod->all($type);

Liefere Datensatz zu Primärschlüssel:

    $row = $mod->lookup($type,$id);

Liefere zu einem Datensatz alle Kind-Datensätze einer Kind-Tabelle:

    @rows|$tab = $mod->childs($row,$childType);

Liefere zu einem Datensatz den Eltern-Datensatz einer Eltern-Tabelle:

    $row = $mod->parent($row,$parentType);

=head1 DESCRIPTION

Ein Objekt der Klasse stellt einen Cache für eine Reihe von
Tabellen/Views einer Datenbank dar. Mit den Methoden der Klasse
kann über die Datensätze navigiert werden, wobei diese sukzessive
geladen werden. Tabellen, deren Inhalt nicht zugegriffen wird,
werden auch nicht geladen.

ACHTUNG: Da eine Tabelle/View beim ersten Zugriff vollständig geladen
wird, ist die Klasse nicht für Tabellen mit Massendaten geeignet.

=head1 EXAMPLES

=head2 Telefonliste

Tabellen:

    Person  Telefon
    ------  -------
    id      id
    name    person_id
            nummer

Programm:

    my $mod = Quiq::ModelCache->new($db,
        'person',
        'telefon',
    );
    
    for my $per ($mod->all('person')) {
        printf "%s\n",$per->name;
        for my $tel ($mod->childs($per,'telefon')) {
            printf "  %s\n",$tel->nummer;
        }
    }
    __END__
    Frank Seitz
      0176/78243503

=head2 Kolumnen mit Präfix

Tabellen:

    Person    Telefon
    ------    -------
    per_id    tel_id
    per_name  tel_person_id
              tel_nummer

Programm:

    my $mod = Quiq::ModelCache->new($db,
        [person => 'per'],
        [telefon => 'tel'],
    );
    
    for my $per ($mod->all('person')) {
        printf "%s\n",$per->per_name;
        for my $tel ($mod->childs($per,'telefon')) {
            printf "  %s\n",$tel->tel_nummer;
        }
    }
    __END__
    Frank Seitz
      0176/78243503

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $mod = $class->new($db,@types);

=head4 Description

Instantiiere einen Cache für Modell-Objekte @types der Datenbank $db
und liefere eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$db,@types) = @_;

    my (@keyVal,%prefix);
    for (@types) {
        my ($type,$prefix) = ref($_)? @$_: ($_,'');
        if ($prefix) {
            $prefix .= '_';
        }
        $prefix{$type} = $prefix;
        push @keyVal,"${type}T"=>undef,"${type}H"=>undef;
    }

    return $class->SUPER::new(
        db => $db,
        prefixH => \%prefix,
        @keyVal,
    );
}

# -----------------------------------------------------------------------------

=head2 Navigation

=head3 all() - Entitätsmenge

=head4 Synopsis

    @rows|$tab = $mod->all($type);

=head4 Description

Liefere alle Datensätze vom Typ $type. Im Skalarkontext liefere ein
Tabellenobjekt mit den Datensätzen.

=cut

# -----------------------------------------------------------------------------

sub all {
    my ($self,$type) = @_;

    my $tab = $self->{"${type}T"} //= do {
        # Entitätsmenge selektieren
        my $tab = $self->db->select($type);

        # Jeder Entität den Typ und eine Referenz auf den Cache hinzufügen
        
        for my $ent ($tab->rows) {
            # Typbezeichnung hinzufügen
            $ent->add(type => $type);
            
            # Referenz auf Cache hinzufügen
            $ent->add(model => $self);
            $ent->weaken('model');
        }
        
        $tab;
    };

    return wantarray? $tab->rows: $tab;
}

# -----------------------------------------------------------------------------

=head3 lookup() - Datensatz zu Schlüsselwert

=head4 Synopsis

    $ent = $mod->lookup($type,$id);

=head4 Description

Ermittele in der Tabelle $type den Datensatz mit dem Schlüsselwert $id
und liefere diesen zurück. Existiert kein Datensatz mit dem
Schlüsselwert $id, wird eine Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub lookup {
    my ($self,$type,$id) = @_;

    my $h = $self->{"${type}H"} //= do {
        my %h;
        my $pk = $self->pk($type);
        for my $ent ($self->all($type)) {
            $h{$ent->$pk} = $ent;
        };
        \%h;
    };

    return $h->{$id} || $self->throw(
        'MODEL-00001: Entity not found',
        Type => $type,
        PrimaryKey => $id,
    );
}

# -----------------------------------------------------------------------------

=head3 childs() - Kind-Datensätze eines Datensatzes

=head4 Synopsis

    @rows|$tab = $mod->childs($row,$childType);

=head4 Description

Ermittele zu Datensatz $row alle Kind-Datensätze vom Typ $childType
und liefere diese zurück. Im Skalarkontext liefere ein
Tabellenobjekt mit diesen Datensätzen.

=cut

# -----------------------------------------------------------------------------

sub childs {
    my ($self,$ent,$childType) = @_;

    if (!$ent->childTypeExists($childType)) {
        # Kind-Typ zu allen Eltern-Entitäten hinzufügen
        
        my $parentType = $ent->type;
        for my $par ($self->all($parentType)) {
            $par->addChildType($childType);
        }

        # Alle Kind-Entitäten ihren Eltern-Entitäten hinzufügen
        
        my $fk = $self->fk($childType,$parentType);
        for my $cld ($self->all($childType)) {
            my $par = $self->lookup($parentType,$cld->$fk);
            $par->addChild($childType,$cld);
        }
    }

    return $ent->getChilds($childType);
}

# -----------------------------------------------------------------------------

=head3 parent() - Eltern-Datensatz eines Datensatzes

=head4 Synopsis

    $par = $mod->parent($row,$parentType);

=head4 Description

Liefere zu Datensatz $row dessen Eltern-Datensatz vom Typ $parentType.

=cut

# -----------------------------------------------------------------------------

sub parent {
    my ($self,$ent,$parentType) = @_;

    if (!$ent->parentExists($parentType)) {
        my $fk = $self->fk($ent->type,$parentType);
        my $parentId = $ent->$fk;
        my $par = $parentId? $self->lookup($parentType,$ent->$fk): undef;
        $ent->addParent($parentType,$par);
    }

    return $ent->getParent($parentType);
}

# -----------------------------------------------------------------------------

=head2 Kolumnen

=head3 pk() - Name Primärschlüsselkolumne

=head4 Synopsis

    $pk = $mod->pk($type);

=head4 Description

Liefere den Namen der Primärschlüsselkolumne des Modell-Objekts $type.
Ohne vereinbarten Kolumnenpräfix lautet der Name

    id

Mit vereinbarten Kolumnenpräfix lautet der Name

    <prefix>_id

=cut

# -----------------------------------------------------------------------------

sub pk {
    my ($self,$type) = @_;
    return sprintf '%sid',$self->{'prefixH'}->{$type};
}

# -----------------------------------------------------------------------------

=head3 fk() - Name Fremdschlüsselkolumne

=head4 Synopsis

    $fk = $mod->fk($type,$parentType);

=head4 Description

Liefere den Namen der Fremdschlüsselkolumne eines Modell-Objekts
vom Typ $type für ein Parent-Modell-Objekt vom Typ $parentType.

Ohne vereinbarten Kolumnenpräfix für $type lautet der Name

    <parentType>_id

Mit vereinbarten Kolumnenpräfix für $type lautet der Name

    <prefix>_<parentType>_id

=cut

# -----------------------------------------------------------------------------

sub fk {
    my ($self,$type,$parentType) = @_;
    return sprintf '%s%s_id',$self->{'prefixH'}->{$type},$parentType;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.149

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
