package Quiq::MediaWiki::Api;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.131;

use Quiq::Parameters;
use Quiq::AnsiColor;
use Quiq::Hash;
use LWP::UserAgent ();
use Quiq::Option;
use Quiq::Debug;
use Quiq::Path;
use Quiq::Record;
use Quiq::Url;
use JSON ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::MediaWiki::Api - Clientseitiger Zugriff auf MediaWiki API

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Diese Klasse implementiert verschiedene clientseitige Methoden für
den Zugriff auf die serverseitige L<MediaWiki-API|https://www.mediawiki.org/w/api.php?action=help&recursivesubmodules=1>.

Die MediaWiki-API wird über api.php (statt index.php) angesprochen.
Die Doku der API wird angezeigt, wenn api.php ohne Parameter
oder mit "action=help&recursivesubmodules=1" (alles auf einer Seite)
aufgerufen wird.

Die MediaWiki-API empfängt und liefert alle Daten in UTF-8.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere MediaWiki-API Client

=head4 Synopsis

    $mwa = $class->new($url,@opt);
    $mwa = $class->new($url,$user,$password,@opt);

=head4 Arguments

=over 4

=item $url

API-URL des MediaWiki, z.B. L<https://en.wikipedia.org/w/api.php>.

=item $user

Benutzername (für automatisches Login statt explizites Login).

=item $password

Passwort (für automatisches Login statt explizites Login).

=back

=head4 Options

=over 4

=item -color => $bool (Default: 1)

Gib die Laufzeitinformation (wird mit -debug=>1 eingeschaltet)
in Farbe aus.

=item -debug => $bool (Default: 0)

Gib Laufzeit-Information wie den Kommunikationsverlauf auf STDERR aus.

=back

=head4 Returns

Client-Objekt

=head4 Description

Instantiiere einen Client für die MediaWiki-API $url und liefere eine
Referenz auf dieses Objekt zurück. Sind Benutzername $user und Passwort
$password angegeben, wird der Benutzer mit dem ersten Request automatisch
eingeloggt. Alternativ kann die Methode $mwa->login() genutzt werden,
um den Benutzer zu einem beliebigen Zeitpunkt einzuloggen.

=head4 Examples

=over 2

=item *

https://www.mediawiki.org/w/api.php

=item *

http://lxv0103.ruv.de:8080/api.php

=back

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: $url,@opt -or- $url,$user,$passw,@opt

    # Optionen und Argumente

    my $color = 1;
    my $debug = 0;
    my $warnings = 0;

    my $argA = Quiq::Parameters->extractToVariables(\@_,1,3,
        -color => \$color,
        -debug => \$debug,
        -warnings => \$warnings,
    );
    my ($url,$user,$password) = @$argA;

    # UserAgent instantiieren

    my $ua = LWP::UserAgent->new(
        agent => 'MediaWikiClient',
        cookie_jar => {},
    );

    # Objekt instantiieren

    return $class->SUPER::new(
        a => Quiq::AnsiColor->new($color),
        autoLogin => $user && $password? 1: 0,
        color => $color,
        debug => $debug,
        warnings => $warnings,
        tokenH => Quiq::Hash->new->unlockKeys,
        ua => $ua,
        url => $url,
        user => $user,
        password => $password,
    );
}

# -----------------------------------------------------------------------------

=head2 Meta-Operationen

=head3 login() - Logge Nutzer ein

=head4 Synopsis

    $res = $mw->login($user,$password);

=head4 Arguments

=over 4

=item $user

Name des Nutzers

=item $password

Passwort des Nutzers

=back

=head4 Description

Logge den Benutzer $user mit Passwort $password auf dem MediaWiki-Server ein.
Alternativ ist ein automatisches Login möglich, siehe Konstruktor.

=head4 Example

    $ perl -MQuiq::MediaWiki::Api -E 'Quiq::MediaWiki::Api->new("http://lxv0103.ruv.de:8080/api.php",-debug=>1)->login("XV882JS","<PASSWORD>")'

=cut

# -----------------------------------------------------------------------------

sub login {
    my ($self,$user,$password) = @_;

    my $res = $self->send(
        POST => 'login',
        lgname => $user,
        lgpassword => $password,
    );        

    if ($res->{'login'}->{'result'} eq 'NeedToken') {
        $res = $self->send(
            POST => 'login',
            lgname => $user,
            lgpassword => $password,
            lgtoken => $res->{'login'}->{'token'},
        );        
    }

    if ($res->{'login'}->{'result'} ne 'Success') {
        $self->throw(
            q~MEDIAWIKI-00099: Login failed~,
            User => $user,
            Reason => $res->{'login'}->{'result'},
        );
    }

    return $res;
}

# -----------------------------------------------------------------------------

=head3 getToken() - Besorge Token für Operation

=head4 Synopsis

    $token = $mwa->getToken($action);

=head4 Arguments

=over 4

=item $action

Operation, für die das Token benötigt wird.

=back

=head4 Description

Besorge vom Server ein Token zum Ausführen von Operation $action und
liefere dieses zurück. Da das Token je Session für alle Seiten identisch
ist, cachen wir die Tokens, so dass nur eine Serveranfrage je
Operationstyp nötig ist.

=cut

# -----------------------------------------------------------------------------

sub getToken {
    my ($self,$action) = @_;

    return $self->tokenH->memoize($action,sub {
        my $res = $self->send(
            GET => 'tokens',
        );

        my $token = $res->{'tokens'}->{$action.'token'};
        if (!$token) {
            $self->throw(
                q~MEDIAWIKI-00099: No token~,
                Action => $action,
            );
        }

        return $token; 
   });
}

# -----------------------------------------------------------------------------

=head2 Seiten-Operationen

=head3 getPage() - Liefere Seite

=head4 Synopsis

    $pag = $mwa->getPage($pageId,@opt);
    $pag = $mwa->getPage($title,@opt);

=head4 Arguments

=over 4

=item $pageId

Page-Id der Seite.

=item $title

Titel der Seite.

=back

=head4 Options

=over 4

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn die Seite nicht gefunden wird.

=back

=head4 Returns

Page-Objekt (Hash)

=head4 Description

Ermittele die Seite mit der PageId $pageId bzw. dem Titel $title
und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub getPage {
    my ($self,$arg) = splice @_,0,2;
    # @_: @opt

    # Optionen

    my $sloppy = 0;

    Quiq::Option->extract(\@_,
        -sloppy => \$sloppy,
    );

    # Request ausführen

    my $res = $self->send(
        GET => 'query',
        $arg =~ /^\d+$/? (pageids => $arg): (titles => $arg),
        prop => 'revisions',
        rvprop => 'ids|flags|timestamp|user|comment|size|content',
    );

    # Extrahiere Seite aus Seitenliste
    my $pag = $self->reduceToPage($res,$sloppy);
    if (!$pag) {
        return undef;
    }

    # Wir bauen die gelieferte Struktur in einen einzelnen Hash um.
    # Dieser besitzt die Komponenten:
    #
    # * * (= Inhalt der Seite)
    # * comment
    # * contentformat
    # * contentmodel
    # * ns
    # * pageid
    # * parentid
    # * revid
    # * size
    # * timestamp
    # * title
    # * user

    my $rev = $pag->{'revisions'}->[0];
    delete $pag->{'revisions'};
    $pag = {%$pag,%$rev};

    if ($self->debug) {
        $self->log('PAGE',Quiq::Debug->dump($pag,colored=>$self->color));
    }

    return Quiq::Hash->new($pag);
}

# -----------------------------------------------------------------------------

=head3 editPage() - Erzeuge/ändere Seite

=head4 Synopsis

    $res = $mwa->editPage($title,$text);
    $res = $mwa->editPage($pageId,$text);

=head4 Arguments

=over 4

=item $title

Titel der Seite.

=item $pageId

Page-Id der Seite.

=item $text

Text der Seite

=back

=head4 Returns

Response

=head4 Description

Setze den Inhalt der Seite mit dem Titel $title auf Text $text.
Drei Fälle lassen sich unterscheiden:

=over 4

=item 1.

Existiert die Seite nicht, wird sie angelegt.

=item 2.

Existiert die Seite und der Text ist verschieden, wird der
bestehende Text ersetzt.

=item 3.

Existiert die Seite und der Text ist identisch, wird der
Aufruf vom Wiki ignoriert.

=back

=head4 Example

=over 2

=item *

Response nach Neuanlage einer Seite

    $mwa->editPage("XV882JS - API Testseite 8","Ein Text")';

produziert (Log)

    ---JSON---
    \ {
        edit   {
            contentmodel   "wikitext",
            new            "",
            newrevid       13318,
            newtimestamp   "2018-12-27T11:54:51Z",
            oldrevid       0,
            pageid         2446,
            result         "Success",
            title          "XV882JS - API Testseite 8"
        }
    }

=back

=cut

# -----------------------------------------------------------------------------

sub editPage {
    my ($self,$arg,$text) = @_;

    # Edit-Token besorgen
    my $token = $self->getToken('edit');

    # Seite bearbeiten

    return $self->send(
        POST => 'edit',
        token => $token,
        $arg =~ /^\d+$/? (pageid => $arg): (title => $arg),
        text => $text,
    );
}

# -----------------------------------------------------------------------------

=head3 movePage() - Benenne Seite um

=head4 Synopsis

    $res = $mwa->movePage($oldTitle,$newTitle,@opt);
    $res = $mwa->movePage($pageId,$newTitle,@opt);

=head4 Arguments

=over 4

=item $oldTitle

Titel der Seite.

=item $pageId

Page-Id der Seite.

=item $newTitle

Zukünftiger Titel der Seite.

=back

=head4 Options

=over 4

=item -reason => $text

Grund für die Umbenennung.

=item -redirect => $bool (Default: 1)

Erzeuge ein Redirekt von der alten zur neuen Seite.

=back

=head4 Description

Benenne die Seite mit dem Titel $oldTitle bzw. der Page-Id $pageId
in $newTitle um. Die alte Seite existiert weiterhin. Das Wiki
richtet automatisch eine Umleitung von der alten zur neuen Seite ein.

=cut

# -----------------------------------------------------------------------------

sub movePage {
    my ($self,$arg,$newTitle) = @_;

    # Optionen

    my $reason = undef;
    my $redirect = 1;

    Quiq::Option->extract(\@_,
        -reason => \$reason,
        -redirect => \$redirect,
    );

    # Edit-Token besorgen (ein Move-Token gibt es nicht)
    my $token = $self->getToken('edit');

    # Seite umbenennen

    return $self->send(
        POST => 'move',
        token => $token,
        $arg =~ /^\d+$/? (fromid => $arg): (from => $arg),
        to => $newTitle,
        $reason? (reason => $reason): (),
        !$redirect? (noredirect => ''): (),
    );
}

# -----------------------------------------------------------------------------

=head3 loadPage() - Lade Seite ins Wiki

=head4 Synopsis

    $mwa->loadPage($mirrorDir,$pageName,$input,@opt);

=head4 Arguments

=over 4

=item $mirrorDir

Pfad zum Spiegel-Verzeichnis. Der Inhalt des Spiegel-Verzeichnisses wird
von der Methode verwaltet. Es enthält Kopien der MediaWiki-Seiten (*.mw).

=item $pageName

Name für die Seite im Spiegel-Verzeichnis. Dieser Name identifiziert die
Seite im Spiegel-Verzeichnis (und ist nicht zu verwechseln mit dem Titel
der Seite). Der Name $pageName muss eindeutig sein.

=item $input

Pfad der MediaWiki Seitendatei oder eine Stringreferenz auf den
Inhalt der Seitendatei.

=back

=head4 Description

Lade die Seite $input mit dem eindeutigen Namen $pageName (im
Spiegel-Verzeichnis) ins MediaWiki. Der $pageName ist nicht zu verwechseln
mit dem Titel der Seite. Der Titel der Seite ist zusammen mit
dem Inhalt der Seite Teil der externen Seitenrepräsentation $input.
Die Methode erkennt, ob die externe Seite $input

=over 2

=item *

bereits im Wiki existiert oder neu angelegt werden muss

=item *

sich der Titel geändert hat -> movePage()

=item *

sich der Inhalt gegenüber dem letzten Stand geändert hat -> editPage()

=item *

eine Änderung im Wiki erfahren hat und diese Änderung in die externe
Seite eingepflegt werden muss -> Fehlermeldung

=back

=cut

# -----------------------------------------------------------------------------

sub loadPage {
    my $self = shift;
    # @_: $mirrorDir,$pageName,$input,@opt

    # Optionen und Argumente

    my $force = 1;

    my $argA = Quiq::Parameters->extractToVariables(\@_,3,3,
        -force => \$force,
    );
    my ($mirrorDir,$pageName,$input) = @$argA;

    # Pfad-Objekt für diverse Pfad-Operationen instantiieren
    my $p = Quiq::Path->new;

    # Externe Seite: Information (Titel, Inhalt) ermitteln

    my $pageCode = ref $input? $$input: $p->read($input,-decode=>'utf-8');
    my $recNew = Quiq::Hash->new(Quiq::Record->fromString($pageCode));
    my ($titleNew,$contentNew) = $recNew->get('Title','Content');

    # Mirror-Seite: Information (Id, Titel, Inhalt) ermitteln.
    # Existiert keine Mirror-Seite, versuchen wir, die Seite über
    # den Titel im Wiki zu finden. Falls sie im Wiki existiert, erzeugen
    # wir aus ihr die Mirror-Seite. Falls nicht, legen wir eine leere
    # Mirror-Seite an (die notwendig von der externen Seite differiert).

    my $varFile = sprintf '%s/%s.mw',$mirrorDir,$pageName;
    if (!$p->exists($varFile)) {
        my $pageId = '';
        my $title = '';
        my $content = '';

        if (my $pag = $self->getPage($titleNew,-sloppy=>1)) {
            $pageId = $pag->{'pageid'};
            $title = $pag->{'title'};
            $content = $pag->{'*'};
        }

        my $data = Quiq::Record->toString(
            Id => $pageId,
            Title => $title,
            Content => $content,
        );
        $p->write($varFile,$data,
            -recursive => 1,
            -encode => 'UTF-8',
        );
    }

    my $recOld = Quiq::Hash->new(Quiq::Record->fromFile(
        $varFile,-encoding=>'UTF-8'));
    my ($pageId,$titleOld,$contentOld) = $recOld->get('Id','Title','Content');

    if ($pageId) {
        # Wiki-Seite existiert bereits

        if ($titleNew eq $titleOld && $contentNew eq $contentOld) {
            # Keine Differenz, es gibt nichts zu tun.
            return;
        }
        if ($contentNew ne $contentOld) {
            # Der Inhalt zwischen der externen Seite und der Mirror-Seite
            # hat sich geändert. Wir prüfen ob die Wiki-Seite geändert
            # wurde, also zwischen dem Inhalt der Mirror-Seite und
            # der Wiki-Seite ein Unterschied besteht.

            if (my $pag = $self->getPage($pageId)) {
                if ($pag->{'*'} ne $contentOld) {
                    if (!$force) {
                        printf "ERROR: Page has changed in Wiki: pageId=%s".
                            " '%s'. Update skipped! Use --force to update the".
                            " page.\n",$pageId,$pag->{'title'};
                        return;
                    }
                    else {
                        printf "WARNING: Page has changed in Wiki: pageId=%s".
                        " '%s'\n",$pageId,$pag->{'title'};
                    }
                }
            }
        }
        if ($titleNew ne $titleOld) {
            # Der Titel zwischen der externen Seite und der Mirror-Seite
            # hat sich geändert. Wir benennen die Wiki-Seite um.

            $self->movePage($pageId,$titleNew);
            print "Page moved: pageId=$pageId '$titleOld' => '$titleNew'\n";
        }
    }

    # Die Seite ist neu oder hat sich geändert. Wir bringen den
    # neusten Stand aufs Wiki und speichern ihn im Cache.

    my $op = $pageId? 'update': 'create'; # 

    my $res = $self->editPage($pageId || $titleNew,$contentNew);
    $pageId = $res->{'edit'}->{'pageid'};
    my $data = Quiq::Record->toString(
        Id => $pageId,
        Title => $titleNew,
        Content => $contentNew,
    );
    $p->write($varFile,$data,
        -encode => 'UTF-8',
    );

    printf "Page %sd: pageId=%s '%s'\n",$op,$pageId,$titleNew;

    return;
}

# -----------------------------------------------------------------------------

=head3 siteInfo() - Allgemeine Information über das MediaWiki

=head4 Synopsis

    $res = $mwa->siteInfo;
    $res = $mwa->siteInfo(@properties);

=head4 Arguments

=over 4

=item @properties

Liste der Sysinfo-Properties, die abgefragt werden sollen. Sind keine
Properties angegeben, werden alle (zur Zeit der Implementierung
bekannten) Properties abgefragt.

=back

=head4 Returns

Response

=head4 Example

    $ quiq-mediawiki ruv statistics --debug

=cut

# -----------------------------------------------------------------------------

sub siteInfo {
    my ($self,@properties) = @_;

    my %property = (
         general => 1,
         namespaces => 1,
         namespacealiases => 1,
         specialpagealiases => 1,
         magicwords => 1,
         statistics => 1,
         interwikimap => 1,
         dbrepllag => 1,
         usergroups => 1,
         extensions => 1,
         fileextensions => 1,
         rightsinfo => 1,
         languages => 1,
         skins => 1,
         extensiontags => 1,
         functionhooks => 1,
         showhooks => 1,
         variables => 1,
         protocols => 1,
    );
    if (!@properties) {
        @properties = keys %property;
    }

    return $self->send(
        GET => 'query',
        meta => 'siteinfo',
        siprop => join('|',@properties),
    );
}

# -----------------------------------------------------------------------------

=head2 Kommunikation

=head3 send() - Sende HTTP-Anfrage, empfange HTTP-Antwort

=head4 Synopsis

    $res = $mwa->send($method,$action,@keyVal);

=head4 Arguments

=over 4

=item $method

Die HTTP Request-Methode: 'GET' oder 'POST'.

=item $action

Die Aktion, die ausgeführt werden soll, z.B. 'query'.

=item @keyVal

Die Liste der Schlüssel/Wert-Paare, die an den Server übermittelt werden,
entweder als URL-Parameter im Falle von GET oder im Body des Requests
im Falle von POST.

=back

=head4 Returns

Dekodiertes JSON in UTF-8 als Perl-Hash

=head4 Description

Grundlegende Methode, über die sämtliche Interaktion mit dem
MediaWiki-Server läuft. Die Interaktion besteht in einem Austausch
von Schlüssel/Wert-Paaren via HTTP mittels GET oder POST. Der Client
sendet mit einem Request eine Menge von Schlüssel/Wert-Paaren und erhält
vom Server in der Response eine Menge von Schlüssel/Wert-Paaren zurück.
In beide Richtungen wird UTF-8 Encoding vorausgesetzt. D.h. die
@keyVal-Elemente müssen UTF-8 kodiert sein, die Elemente in der
Response $res sind es ebenfalls.

=cut

# -----------------------------------------------------------------------------

sub send {
    my ($self,$method,$action) = splice @_,0,3;
    # @_: @keyVal

    if ($action ne 'login' && $self->autoLogin) {
        # Wir loggen uns mit dem ersten Request automatisch ein

        $self->login($self->user,$self->password);
        $self->autoLogin(0);
    }
    
    my ($ua,$url) = $self->get(qw/ua url/);

    # Wir wollen die Antwort in JSON
    # my @keyVal = (action=>$action,formatversion=>2,format=>'json',@_);
    my @keyVal = (action=>$action,format=>'json',@_);

    # HTTP-Request erzeugen und ausführen

    my $res;
    if ($method eq 'GET') {
        my $queryString = Quiq::Url->queryEncode(-separator=>'&',@keyVal);
        $res = $ua->get("$url?$queryString");
    }
    elsif ($method eq 'POST') {
        $res = $ua->post($url,{@keyVal});
    }
    else {
        $self->throw(
            q~MEDIAWIKI-00099: Unknown request method~,
            Method => $method,
        );
    }

    # Logge Request

    if ($self->debug) {
        $self->log('REQUEST',$res->request->as_string);
    }

    if (!$res->is_success) {
        $self->throw(
            q~MEDIAWIKI-00099: HTTP request failed~,
            StatusLine => $res->status_line,
            Response => $res->content,
        );
    }

    # Logge Response

    if ($self->debug) {
        $self->log('RESPONSE',$res->as_string);
    }

    # Wandele Body von JSON in Perl-Datenstruktur
    my $json = JSON::decode_json($res->content);

    # Logge JSON

    if ($self->debug) {
        $self->log('JSON',Quiq::Debug->dump($json,colored=>$self->color));
    }

    # Prüfe auf MediaWiki API Error

    if ($res->header('MediaWiki-API-Error')) {
        $self->throw(
            q~MEDIAWIKI-00099: API error~,
            Code => $json->{'error'}->{'code'},
            Info => $json->{'error'}->{'info'},
        );
    }

    # Warnungen schreiben wir nach STDERR

    if ($self->warnings && (my $h = $json->{'warnings'})) {
        for my $key (keys %$h) {
            warn "WARNING: $key - $h->{$key}->{'*'}\n";
            # formatversion=2
            # warn "WARNING: $key - $h->{$key}->{'warnings'}\n";
        }
    }

    return $json;
}

# -----------------------------------------------------------------------------

=head2 Response Handling

=head3 reduceToPage() - Reduziere Seitenliste auf Einzelseite

=head4 Synopsis

    $pag = $mwa->reduceToPage($res);
    $pag = $mwa->reduceToPage($res,$sloppy);

=head4 Arguments

=over 4

=item $res

Response vom Server mit Seitenliste.

=item $sloppy

Wirf keine Exception, wenn keine Seite existiert.

=back

=head4 Returns

Reduzierte Response

=head4 Description

Reduziere die Server-Response $res mit einer Seitenliste der Art

    {
        query => {
            pages => {
                $pageId => {
                     @keyVal
                },
                ...
            },
        }
    }

auf

    {
        @keyVal
    }

also auf ein Element und liefere dieses zurück.

Enthält die Seitenliste mehr als ein Element, oder handelt es sich um
ein ungültiges (als "missing" gekennzeichnetes) Element, wird eine
Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub reduceToPage {
    my ($self,$res,$sloppy) = @_;

    # Mehr als ein Element?

    my @pageIds = keys %{$res->{'query'}->{'pages'}};
    if (@pageIds > 1) {
        $self->throw(
            q~MEDIAWIKI-00099: More than one page~,
            PageIds => "@pageIds",
        );
    }

    # Ungültiges Element?
    # Existiert die Seite nicht, hat die pageid den Wert -1 oder die
    # Seiteninformation enthält die Komponente missing (missing => '').

    my $pag = $res->{'query'}->{'pages'}->{$pageIds[0]};
    if ($pageIds[0] == -1 || exists $pag->{'missing'}) {
        if ($sloppy) {
            return undef;
        }
        $self->throw(
            q~MEDIAWIKI-00099: Page not found~,
        );
    }

    return $pag;
}

# -----------------------------------------------------------------------------

=head2 Logging

=head3 log() - Schreibe Debug Log

=head4 Synopsis

    $mwa->log($title,$text);

=head4 Description

Schreibe den Text $text unter der Überschrift $title nach STDERR.

=cut

# -----------------------------------------------------------------------------

sub log {
    my ($self,$title,$text) = @_;

    my $a = $self->a;
    warn $a->str('dark red',"---$title---"),"\n";
    $text =~ s/\n+$//;
    warn $a->str('dark blue',$text),"\n";

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.131

=head1 SEE ALSO

=over 2

=item *

L<https://www.mediawiki.org/wiki/API>

=back

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
