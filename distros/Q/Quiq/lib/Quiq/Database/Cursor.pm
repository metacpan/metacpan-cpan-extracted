package Quiq::Database::Cursor;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.134;

use Quiq::Database::Row::Array;
use Quiq::Database::Row::Object;
use Quiq::Database::ResultSet::Array;
use Quiq::Database::ResultSet::Object;
use Quiq::Database::Connection;
use Time::HiRes ();
use Quiq::Database::Cursor;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Database::Cursor - Datenbank-Cursor

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert das Resultat einer
Statement-Ausführung auf einer Relationalen Datenbank.

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
    # @_: @keyVal

    my $self = $class->SUPER::new(
        apiCur=>undef,
        bindVars=>0,
        db=>undef,
        hits=>0,
        id=>0,
        # Attribut rowOperation wird bei save() gesetzt: 0, 'I', 'U', 'D'
        rowOperation=>0,
        rowClass=>undef, # Quiq::Database::Connection->defaultRowClass, # Initial. nötig?
        tableClass=>undef,
        titles=>[],
        stmt=>undef,
        startTime=>scalar(Time::HiRes::gettimeofday),
        execTime=>0,
        curName=>undef,
        chunkSize=>0,
        chunkPos=>0,
    );

    $self->set(@_);
    $self->weaken('db');

    return $self;
}

# -----------------------------------------------------------------------------

=head3 close() - Schließe Cursor

=head4 Synopsis

    $cur->close;

=head4 Alias

destroy()

=head4 Description

Schließe Cursor. Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub close {
    my ($self) = @_;

    if (my $curName = $self->{'curName'}) {
        $self->{'db'}->sql("CLOSE $curName",-log=>0); # PostgreSQL
    }

    $_[0] = undef;
}

{
    no warnings 'once';
    *destroy = \&close;
}

# -----------------------------------------------------------------------------

=head2 Accessors

=head3 bindVars() - Liefere Anzahl der Bind-Variablen

=head4 Synopsis

    $n = $cur->bindVars;

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
    return shift->{'apiCur'}->bindTypes(@_);
}

# -----------------------------------------------------------------------------

=head3 db() - Liefere Datenbankverbindung

=head4 Synopsis

    $db = $cur->db;

=cut

# -----------------------------------------------------------------------------

sub db {
    return shift->{'db'};
}

# -----------------------------------------------------------------------------

=head3 hits() - Liefere Anzahl der getroffenen Datensätze

=head4 Synopsis

    $n = $cur->hits;

=head4 Description

Liefere die Anzahl der von einem INSERT, UPDATE oder DELETE
getroffenen Datesätze.

=cut

# -----------------------------------------------------------------------------

sub hits {
    return shift->{'hits'};
}

# -----------------------------------------------------------------------------

=head3 id() - Liefere Wert der Autoincrement-Kolumne

=head4 Synopsis

    $id = $cur->id;

=head4 Alias

insertId()

=head4 Description

Liefere den Wert der Autoinkrement-Kolumne nach einem INSERT.

=cut

# -----------------------------------------------------------------------------

sub id {
    return shift->{'id'};
}

{
    no warnings 'once';
    *insertId = \&id;
}

# -----------------------------------------------------------------------------

=head3 rowOperation() - Liefere die Datensatz-Operation

=head4 Synopsis

    $op = $cur->rowOperation;

=head4 Description

Liefere die von save() durchgeführte Datensatz-Operation: 0, 'I', 'U'
oder 'D'.

=cut

# -----------------------------------------------------------------------------

sub rowOperation {
    return shift->{'rowOperation'};
}

# -----------------------------------------------------------------------------

=head3 rowClass() - Liefere Namen der Datensatz-Klasse

=head4 Synopsis

    $rowClass = $cur->rowClass;

=cut

# -----------------------------------------------------------------------------

sub rowClass {
    return shift->{'rowClass'};
}

# -----------------------------------------------------------------------------

=head3 stmt() - Liefere SQL-Statement

=head4 Synopsis

    $stmt = $cur->stmt;

=head4 Description

Liefere das SQL-Statement, wie es an das DBMS übermittelt und von
ihm ausgeführt wurde. Das von der Methode gelieferte Statement
kann von dem Statement, das beim Aufruf angegeben wurde, verschieden
sein, da ggf. interne Transformationsschritte auf das Statement
anwendet wurden.

=cut

# -----------------------------------------------------------------------------

sub stmt {
    return shift->{'stmt'};
}

# -----------------------------------------------------------------------------

=head3 titles() - Liefere Liste der Kolumnentitel

=head4 Synopsis

    @titles | $titlesA = $cur->titles;

=head4 Description

Liefere die Liste der Kolumnenwerte. Im Skalarkontext liefere
eine Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub titles {
    my $self = shift;
    return wantarray? @{$self->{'titles'}}: $self->{'titles'};
}

# -----------------------------------------------------------------------------

=head2 Tests

=head3 isSelect() - Prüfe, ob Cursor Datensätze liefert

=head4 Synopsis

    $bool = $cur->isSelect;

=head4 Description

Liefere "wahr", wenn der Cursor Datensätze liefert,
andernfalls "falsch".

=cut

# -----------------------------------------------------------------------------

sub isSelect {
    return @{shift->{'titles'}}? 1: 0;
}

# -----------------------------------------------------------------------------

=head2 Time Measurement

=head3 startTime() - Liefere Startzeitpunkt der Statement-Ausführung

=head4 Synopsis

    $time = $cur->startTime;

=cut

# -----------------------------------------------------------------------------

sub startTime {
    return shift->{'startTime'};
}

# -----------------------------------------------------------------------------

=head3 execTime() - Liefere Dauer der Statement-Ausführung

=head4 Synopsis

    $time = $cur->execTime;

=cut

# -----------------------------------------------------------------------------

sub execTime {
    return shift->{'execTime'};
}

# -----------------------------------------------------------------------------

=head3 time() - Liefere Dauer seit Start der Statement-Ausführung

=head4 Synopsis

    $time = $cur->time;

=cut

# -----------------------------------------------------------------------------

sub time {
    my $self = shift;
    return Time::HiRes::gettimeofday-$self->{'startTime'};
}

# -----------------------------------------------------------------------------

=head2 Bind

=head3 bind() - Binde Werte an Statement und führe Statement aus

=head4 Synopsis

    $cur2 = $cur->bind(@vals);

=head4 Description

Binde eine Liste von Werten an die Platzhalter eines zuvor
präparierten SQL-Statements und führe dieses Statement auf der
Datenbank aus. Die Anzahl der Werte muß ein Vielfaches der Anzahl der
Bind-Variablen sein.

=cut

# -----------------------------------------------------------------------------

sub bind {
    my $self = shift;
    # @_: @opt,@vals

    # Werte binden und Statement ausführen

    my $startTime = Time::HiRes::gettimeofday;
    my $apiCur = $self->{'apiCur'}->bind(@_);
    my $execTime = Time::HiRes::gettimeofday-$startTime;

    # Attribute Lowlevel-Cursor abfragen

    my $bindVars = 0;
    my $hits = $apiCur->hits;
    my $titles = $apiCur->titles;
    my $id = $apiCur->id;

    return Quiq::Database::Cursor->new(
        apiCur=>$apiCur,
        bindVars=>$bindVars,
        db=>$self, # schwache Referenz, siehe Cursor-Konstruktor
        hits=>$hits,
        id=>$id,
        rowClass=>$self->{'rowClass'},
        titles=>$titles,
        startTime=>$startTime,
        execTime=>$execTime,
    );
}

# -----------------------------------------------------------------------------

=head2 Fetch

=head3 fetch() - Liefere nächsten Datensatz der Ergebnismenge

=head4 Synopsis

    $row = $cur->fetch;

=head4 Description

Liefere den nächsten Datensatz aus der Ergebnismenge. Ist das Ende der
Ergebnismenge erreicht, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub fetch {
    my $self = shift;

    my ($apiCur,$curName,$chunkSize,$rowClass,$titles) =
        $self->get(qw/apiCur curName chunkSize rowClass titles/);

    # Lowlevel-Cursor ist bereits zu
    return undef if !$apiCur;

    # Datensatz fetchen
    # warn "$curName $chunkSize $self->{'chunkPos'}\n" if $chunkSize;
    my $arr = $apiCur->fetch($curName,$chunkSize,\$self->{'chunkPos'});

    # Wenn Ende erreicht, Lowlevel-Cursor schließen, Fetchzeit setzen.

    if (!$arr) {
        $apiCur->destroy;
        $self->{'apiCur'} = undef;
        return undef;
    }

    # Datensatz-Objekt instantiieren

    my $row = $rowClass->new($titles,$arr);
    if ($row->can('rowStatus')) {
        $row->rowStatus(0);
    }

    return $row;
}

# -----------------------------------------------------------------------------

=head3 fetchAll() - Liefere gesamte Ergebnismenge

=head4 Synopsis

    @rows | $tab = $cur->fetchAll($autoClose);

=head4 Description

Liefere die Ergebnismenge als Liste von Datensätzen oder als
Tabelle. Ist der Parameter $autoCloase angegeben und "wahr" schließe
den Cursor automatisch.

=cut

# -----------------------------------------------------------------------------

sub fetchAll {
    my $self = shift;
    my $autoClose = shift;

    # Alle Datensätze fetchen

    my @rows;
    while (my $row = $self->fetch) {
        push @rows,$row;
    }

    # Table-Objekt instantiieren, wenn !wantarray

    my $tab;
    if (!wantarray) {
        my $rowClass = $self->{'rowClass'};
        my $tableClass = $self->{'tableClass'};

        $tab = $tableClass->new($rowClass,$self->{'titles'},\@rows,
            stmt=>$self->{'stmt'},
            hits=>$self->{'hits'},
            startTime=>$self->{'startTime'},
            execTime=>$self->{'execTime'},
            fetchTime=>$self->time,
        );
    }

    # Cursor schließen, falls $autoClose

    if ($autoClose) {
        $self->close 
    }

    return wantarray? @rows: $tab;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.134

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
