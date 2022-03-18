# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Web::Navigation - Webseiten-Navigation

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse erstellt eine Seitenhistorie auf Basis des HTTP-Headers
C<Referer:> und speichert diese in einer Navigationsdatenbank.
Dadurch wird eine Navigation zwischen Webseiten möglich,
insbesondere eine Zurücknavigation zu einer zuvor festgelegten
Rückkehrseite.

=head2 Navigationsdatenbank

Die Navigationssdatenbanken aller Sitzungen werden in einem
ausgezeichneten Verzeichnis DIR gespeichert. In jedem
Unterverzeichnis SID befindet sich die Navigationsdatenbank zu
einer Sitzung. DIR und SID werden beim Konstruktoraufruf
angegeben.

  DIR/SID/            Verzeichnis zu einer Sitzung
  DIR/SID/rid         aktuelle Request-Id
  DIR/SID/referer.db  Request-Ids zu URLs der Sitzung
  DIR/SID/call.db     Seitenaufrufe der Sitzung
  DIR/nosession.log   Log der sitzungslosen Zugriffe

Folgende Datenbankdateien werden von der Klasse sitzungsbezogen
geschrieben und gelesen. Alle Dateien werden von der Klasse
automatisch angelegt, wenn sie benötigt werden.

=over 4

=item rid

Datei mit einer einzigen Zeile, die die aktuelle Request-Id
enthält. Die Datei stellt den Request-Zähler für die Sitzung
dar. Die Zählung beginnt mit 1. Ferner findet über dieser
Datei die Synchronisation von parallel verlaufenden Schreib-
und Leseoperationen statt. Sie wird vor Schreiboperationen auf
einer oder mehreren Datenbankdateien mit einem Exklusiv-Lock
belegt und bei Leseoperationen mit einem Shared-Lock.

=item referer.db

Hash-Datei, die Request-Ids zu Referer-URLs speichert. Über diese
Zuordnung stellt die Klasse ohne weitere Information von außen die
Aufrufreihenfolge her. Schlüssel der Datei ist der URL des Aufrufs.

  referer | rid
  
  referer : Referer-URL des Aufrufs
  -------
  rid     : Request-Id des jüngsten Aufrufs des betreffenden URL

=item call.db

Hash-Datei, in der die Aufrufe protokolliert werden. Schlüssel
ist die Request-Id des Aufrufs.

  rid | url \0 rrid \0 brid
  
  rid     : Request-Id des aktuellen Aufrufs
  -------
  url     : URL des Aufrufs in Querystring-Kodierung
  rrid    : Request-Id der rufenden Seite
  brid    : Request-Id der Rückkehrseite

Die Request-Id der Rückkehrseite wird automatisch von Request
zu Request weiter gereicht.

=back

=head2 Direktiven

Die Klasse reserviert folgende Parameternamen, die vom Konstruktor
als Direktiven zur Verwaltung der Sitzungsdaten interpretiert
werden. Diese werden bei einem Seitenübergang dem URL der
Zielseite optional hinzugefügt.

=over 4

=item navPrev=rid

Teilt dem Navigation-Konstruktor der Folgeseite die
Vorgängerseite mit. Diese Angabe ist normalerweise nicht
nötig, da die Vorgängerseite automatisch durch Auswertung
Referer-Headers ermittelt wird. Es gibt aber exotische
Situtionen, in denen dies nicht oder nicht portabel
funktioniert. Dies ist evtl. beim Übergang von einer Seite zu
einem Popup-Menü und beim Übergang vom Popup-Menü zur
Folgeseite der Fall.

=item navBack=rid

Teilt dem Navigation-Konstruktor der Folgeseite mit, dass die
Seite mit der Request-Id rid als Rückkehrseite gespeichert
werden soll. Die Request-Id der Rückkehrseite wird von der
Klasse automatisch von Aufruf zu Aufruf weitergereicht, bis
sie durch eine neue Setzung überschrieben wird. Anstelle
einer numerischen Request-Id können folgende symbolischen
Werte angegeben werden:

=over 4

=item -1

Als Rückkehrseite wird die Vorgängerseite, also die
rufende Seite, eingetragen. Diese Direktive wird in den
abgehenden Links der Seite angegeben, wenn die aktuelle
Seite für die Folgeseite(n) die Rückkehrseite darstellt.

=item x

Der Eintrag für die Rückkehrseite wird gelöscht.

=back

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Web::Navigation;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.200';

use Quiq::Path;
use Quiq::LockedCounter;
use Quiq::Hash::Db;
use POSIX ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Navigationsobjekt

=head4 Synopsis

  $nav = $class->new($dir,$sid,$obj);

=head4 Arguments

=over 4

=item $dir

Verzeichnis, in dem die Daten zur Session-Id $sid gespeichert werden.

=item $sid

Id für der Session.

=item $obj

Objekt mit Informationen zum aktuellen Aufruf. Im Falle von Mojolicious
übergeben wir das Controller-Objekt.

=back

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$dir,$sid,$obj) = @_;

    # Allgemeine Objekte
    my $p = Quiq::Path->new;

    # Request-Information, die wir im Zuge der folgenden
    # Verarbeitung benötigen. Hier für Mojolicious.
    # FIXME: In einem speziellen Request-Objekt kapseln

    my $absUrl = $obj->req->url->to_abs;
    my $url = $obj->req->url;
    my $referer = $obj->req->headers->referer;
    my $browser = $obj->req->headers->user_agent;
    my $remoteAddr = $obj->tx->original_remote_address;
    # my $post = $obj->req->body_params->to_string;
    my $rrid = $obj->param('navPrev') // '';
    my $brid = $obj->param('navBack') // '';

    # Navigationsobjekt mit der Rückkehrseite, falls existent

    my $self = $class->SUPER::new(
        backUrl => '',
    );

    # Allgemeines Navigations-Verzeichnis erzeugen
    $p->mkdir($dir);

    # Aufrufe ohne Session-Id speichern wir in einer speziellen Datei.
    # Bei diesen Aufrufen ohne $sid ist keine Navigation möglich.

    if (!$sid) {
        my $time = POSIX::strftime '%Y-%m-%d %H:%M:%S',localtime;
        $p->write("$dir/no-session.log","$time|$remoteAddr|$browser|$absUrl\n",
            -append => 1,
            -lock => 1,
        );

        # Wir liefern ein "leeres" Navigationsobjekt
        return $self;
    }

    # Navigationsdatenbank für Session aufbauen

    my $sidDir = "$dir/$sid";
    $p->mkdir($sidDir);

    # Die Dateien im Navigationsverzeichnis der Session

    my $ridFile = "$sidDir/rid";
    my $refererDb = "$sidDir/referer.db";
    my $callDb = "$sidDir/call.db";

    # Wir ermitteln die Request-Id der aktuellen Seite. Der Counter
    # ist gleichzeitig ein Lock, der bis zum Ende des Konstruktors
    # aufrechterhalten wird.

    my $cnt = Quiq::LockedCounter->new($ridFile)->increment;
    my $rid = $cnt->count;

    my $refererH = Quiq::Hash::Db->new($refererDb,'rw');

    # Wir ermitteln die Request-Id der Vorgängerseite. Von dort übernehmen
    # die Request-Id der Rückkehr-Seite.
    $rrid ||= $referer && $refererH->{$referer} || '';

    # Wir speichern die Request-Id des aktuellen Seitenaufrufs
    $refererH->{$absUrl} = $rid;

    $refererH->close;

    # Wir schreiben einen neuen Eintrag in die Call-DB, wobei wir
    # die Request-Id der Rückkehr-Seite übernehmen
    
    my $callH = Quiq::Hash::Db->new($callDb,'rw');
    if ($brid) {
        if ($brid == -1) {
            $brid = $rrid;
        }
        elsif ($brid eq 'x') {
            $brid = '';
        }
    }
    elsif ($rrid) {
        my $data = $callH->{$rrid} // $class->throw;
        # $url,$rrid,$brid
        (undef,undef,$brid) = split /\0/,$data,4;
    }
    $callH->{$rid} = "$url\0$rrid\0$brid";

    if ($brid) {
        my $data = $callH->{$rrid} // $class->throw;
        # $url,$rrid,$brid
        ($url,undef,undef) = split /\0/,$data,4;
        $self->set(backUrl=>$url);
    }

    $callH->close;

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Attribute

=head3 backUrl() - URL der Rückkehrseite

=head4 Synopsis

  $url = $nav->backUrl;

=head4 Returns

(String) URL

=head4 Description

Liefere den URL der Rückkehrseite als Zeichenkette. Gibt es keine
Rückkehrseite, liefere einen Leerstring.

=head1 VERSION

1.200

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2022 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
