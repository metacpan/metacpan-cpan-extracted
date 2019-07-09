package Quiq::Database::Row::Array;
use base qw/Quiq::Database::Row/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Database::Row::Array - Datensatz als Array

=head1 BASE CLASS

L<Quiq::Database::Row>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Datensatz mit
einer einfachen Array-Repräsentation.

Das Objekt ist eine Liste von Attributwerten, es besitzt
keine weitere Information über Titel, Datensatz-Status usw.

=cut

# -----------------------------------------------------------------------------

our $TableClass = 'Quiq::Database::ResultSet::Array'; # Default-Tabellenklasse

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $row = $class->new(\@values);
    $row = $class->new(\@titles,\@values);

=head4 Description

Instantiiere ein Datensatz-Array-Objekt mit den Kolumnenwerten
@values und liefere eine Referenz auf dieses Objekt zurück.

Beim einparametrigen Aufruf wird @values einfach auf die
Klasse geblesst.

Der zweiparametrige Aufruf ist der normierte Aufruf, mit dem
$cur->fetch() Datensatzobjekte instantiiert. In dem Fall
kopieren wir das Array, da DBI das Array wiederbenutzt
(readonly-Array).

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;

    if (@_ == 2) {
        # Aufruf aus $cur->fetch() heraus. Wir kopieren das
        # Array, da DBI das Array wiederbenutzt (readonly-Array).
        # Bei anderen Schnittstellen (die momentan nicht existieren)
        # ist ein kopieren eventuell nicht notwendig, dies sollten
        # wir dann auf irgend einem Wege unterscheiden.
        return bless [@{$_[1]}],$class;
    }

    return bless $_[0],$class;
}

# -----------------------------------------------------------------------------

=head2 Common

=head3 asArray() - Liefere Datensatz als Array

=head4 Synopsis

    $arr|@arr = $row->asArray;

=head4 Description

Liefere den Datensatz als Array, entweder in Form einer Referenz
(Skalarkontext) oder als Array von Werten (Listkontext).

Da der Datensatz bereits ein Array ist, scheint die Methode
überflüssig. Sie existiert jedoch, damit Object-Rows und
Array-Rows einheitlich behandelt werden können.

=cut

# -----------------------------------------------------------------------------

sub asArray {
    return wantarray? @{$_[0]}: $_[0];
}

# -----------------------------------------------------------------------------

=head3 asString() - Liefere Datensatz als Zeichenkette

=head4 Synopsis

    $str = $row->asString;
    $str = $row->asString($colSep);

=head4 Description

Liefere den Datensatz als Zeichenkette. Per Default werden die Kolumnen
per TAB getrennt. Der Trenner kann mittels $colSep explizit angegeben
werden.

=cut

# -----------------------------------------------------------------------------

sub asString {
    my $self = shift;
    my $colSep = @_? shift: "\t";
    return join $colSep,@$self;
}

# -----------------------------------------------------------------------------

=head3 copy() - Kopiere Datensatz

=head4 Synopsis

    $newRow = $row->copy;

=cut

# -----------------------------------------------------------------------------

sub copy {
    my $self = shift;
    return bless [@$self],ref($self);
}

# -----------------------------------------------------------------------------

=head3 isRaw() - Liefere, ob Klasse Raw-Datensätze repräsentiert

=head4 Synopsis

    $bool = $row->isRaw;

=cut

# -----------------------------------------------------------------------------

sub isRaw {
    return 1;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.151

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
