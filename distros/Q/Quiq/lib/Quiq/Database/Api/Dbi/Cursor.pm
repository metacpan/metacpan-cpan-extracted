package Quiq::Database::Api::Dbi::Cursor;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Database::Api::Dbi::Cursor - DBI Datenbank-Cursor

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen DBI-Datenbank-Cursor.

=head1 ATTRIBUTES

=over 4

=item sth => $sth

DBI Statement-Handle.

=item bindVars => $n

Anzahl an Bind-Variablen, die im Statement enthalten sind. Ist
die Anzahl größer 0, handelt es sich um einen Bind-Cursor.

=item titles => \@titles

Array der Kolumentitel. Ist das Array nicht leer, handelt es
sich um einen Select-Cursor.

=item hits => $n

Anzahl der getroffenen Datensätze.

=item id => $id

Id nach INSERT in Tabelle mit AUTOINCREMENT-Kolumne (MySQL, SQLite)

=back

=head1 METHODS

=head2 Konstruktor/Destruktor

=head3 new() - Instantiiere Cursor

=head4 Synopsis

    $cur = $class->new(@keyVal);

=head4 Description

Instantiiere ein Cursor-Objekt mit den Attributen @keyVal
und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(
        sth => undef,
        bindVars => 0,
        bindTypes => [],
        db => undef,
        titles => [],
        hits => 0,
        id => 0,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head3 destroy() - Schließe Cursor

=head4 Synopsis

    $cur->destroy;

=head4 Description

Schließe Cursor. Die Objektreferenz ist anschließend ungültig.
Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub destroy {
    my ($self) = @_;

    if (my $sth = $self->{'sth'}) {
        $sth->finish;
    }
    $_[0] = undef;

    return;
}

# -----------------------------------------------------------------------------

=head2 Akzessoren

=head3 bindVars() - Liefere die Anzahl der Bind-Variablen

=head4 Synopsis

    $n = $cur->bindVars;

=head4 Description

Liefere die Anzahl der Bind-Variablen, die im SQL-Statement enthalten
waren.

=cut

# -----------------------------------------------------------------------------

sub bindVars {
    return shift->{'bindVars'};
}

# -----------------------------------------------------------------------------

=head3 bindTypes() - Setze/Liefere Datentypen der Bind-Variablen

=head4 Synopsis

    @arr|$arr = $cur->bindTypes(@dataTypes);
    @arr|$arr = $cur->bindTypes;

=cut

# -----------------------------------------------------------------------------

sub bindTypes {
    my $self = shift;
    # @_: @types

    my $arr = $self->{'bindTypes'};
    if (@_) {
        @$arr = ();
        my $dbms = $self->{'db'}->{'dbms'};
        for my $type (@_) {
            if (!defined $type) {
                push @$arr,undef;
            }
            elsif ($type eq 'BLOB') {
                if ($dbms eq 'oracle') {
                    push @$arr,{ora_type=>DBD::Oracle::SQLT_BIN()};
                }
                elsif ($dbms eq 'postgresql') {
                    push @$arr,{pg_type=>DBD::Pg::PG_BYTEA()};
                }
                else {
                    push @$arr,undef;
                }
            }
            elsif ($type eq 'TEXT') {
                if ($dbms eq 'oracle') {
                    push @$arr,{ora_type=>DBD::Oracle::SQLT_CHR()};
                }
                else {
                    push @$arr,undef;
                }
            }
            elsif ($type eq 'NUMBER') {
                if ($dbms eq 'oracle') {
                    push @$arr,{ora_type=>DBD::Oracle::ORA_NUMBER()};
                }
                else {
                    push @$arr,undef;
                }
            }
            elsif ($type eq 'XML') {
                if ($dbms eq 'oracle') {
                    push @$arr,{ora_type=>DBD::Oracle::ORA_XMLTYPE()};
                }
                else {
                    push @$arr,undef;
                }
            }
            else {
                push @$arr,$type;
            }
        }
    }

    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 hits() - Liefere die Anzahl der getroffenen Datensätze

=head4 Synopsis

    $n = $cur->hits;

=head4 Description

Liefere die Anzahl der Datesätze, die bei der Ausführung des
Statement getroffen wurden. Im Falle einer Selektion ist dies die
Anzahl der (bislang) gelesenen Datensätze.

=cut

# -----------------------------------------------------------------------------

sub hits {
    return shift->{'hits'};
}

# -----------------------------------------------------------------------------

=head3 id() - Liefere die Id des eingefügten Datensatzes

=head4 Synopsis

    $id = $cur->id;

=cut

# -----------------------------------------------------------------------------

sub id {
    return shift->{'id'};
}

# -----------------------------------------------------------------------------

=head3 titles() - Liefere eine Referenz auf Liste der Kolumnentitel

=head4 Synopsis

    $titlesA = $cur->titles;

=cut

# -----------------------------------------------------------------------------

sub titles {
    return shift->{'titles'};
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 bind() - Führe Bind-Statement aus

=head4 Synopsis

    $cur = $cur->bind(@vals);

=head4 Description

Führe Bind-Statement aus und liefere einen (neuen) Cursor über
das Resultat der Statement-Ausführung zurück.

=cut

# -----------------------------------------------------------------------------

sub bind {
    my $self = shift;

    my ($sth,$bindVars,$bindTypes) = $self->get(qw/sth bindVars bindTypes/);

    my $hits = 0;
    while (@_) {
        my @vals;
        if (ref $_[0]) {
            # Wert ist (Array-)Referenz, wir expandieren die Referenz
            @vals = @{shift()}
        }
        else {
            # Abfolge von Werten
            @vals = splice @_,0,$bindVars;
        }

        # '' auf undef umsetzen

        for (@vals) {
            if (defined $_ && $_ eq '') {
                $_ = undef;
            }
        }

        # Werte binden und Statement ausführen. BindType kann
        # undef sein. Im Falle von Oracle und BLOB oder CLOB sollte
        # ein Type spezifiziert sein (siehe Methode bindTypes)

        for (my $i = 0; $i < @vals; $i++) {
            $sth->bind_param($i+1,$vals[$i],$bindTypes->[$i]);
        }
        my $r = $sth->execute;
        $hits += $r if $r > 0;
    }
    $self->{'hits'} = $hits;

    # Die Kolumnentitel sind bei SELECT-Statements mit Bind-Variablen
    # erst nach dem Bind verfügbar.

    if ($sth->{'NUM_OF_FIELDS'}) {
        $self->{'titles'} = $sth->{'NAME_lc'};
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head3 fetch() - Liefere den nächsten Datensatz

=head4 Synopsis

    $row = $cur->fetch;

=head4 Description

Liefere eine Referenz auf den nächsten Datensatz der Ergebnismenge.
Ist das Ende der Ergebnismenge erreicht, liefere undef.

Der Datensatz ist ein Array mit den Kolumnenwerten.

Bei DBI liefert jeder Aufruf dieselbe Referenz, so dass das Array vom
Aufrufer normalerweise kopiert werden muss.

Nullwerte werden durch einen Leerstring repräsentiert.
Da DBI einen Nullwert durch undef repräsentiert, nimmt die
Methode eine Abbildung von undef auf '' vor.

=cut

# -----------------------------------------------------------------------------

sub fetch {
    my $self = shift;
    my $curName = shift;
    my $chunkSize = shift;
    my $chunkPosS = shift;

    if ($curName) { # PostgreSQL
        if ($$chunkPosS == $chunkSize) {
            my $stmt = "FETCH $chunkSize FROM $curName";
            my $cur = $self->{'db'}->sql($stmt,-log=>0);
            $self->{'sth'} = $cur->{'sth'};
            # $self->{'sth'} = $self->{'db'}->{'dbh'}->prepare($stmt);
            # $self->{'sth'}->execute;
            $$chunkPosS = 1; # nicht 0, da wir den ersten Satz unten fetchen!
        }
        else {
            $$chunkPosS++;
        }
    }

    my $row = $self->{'sth'}->fetchrow_arrayref;
    if ($row) {
        grep { $_ = '' if !defined $_ } @$row; # undef -> ''
    }

    return $row;
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
