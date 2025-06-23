# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Confluence::Client - Confluence-Wiki Client

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Client, der über die
L<Confluence REST API|https://docs.atlassian.com/confluence/REST/latest/> mit einem
Confluence-Server kommunizieren kann.

Doku für Python: L<https://atlassian-python-api.readthedocs.io/>.Authentisierung gegen REST API der Cloud-Version s.
Abschnitt I<To authenticate to the Atlassian Cloud APIs Jira, Confluence,
ServiceDesk>. Als Passwort muss ein Token angegeben werden, das
im unter "Konto / Konto verwalten / Sicherheit / API Token"
angelegt und verwaltet werden kann.

Die Implementierung der Klasse stellt die maßgeblichen Mechnismen
zur Kommunikation mit dem Server zur Verfügung, realisiert
z.Zt. jedoch nur einen kleinen Ausschnitt der Funktionalität der
Confluence REST API. Die Implementierung wird nach Bedarf
erweitert.

=cut

# -----------------------------------------------------------------------------

package Quiq::Confluence::Client;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;
use utf8;

our $VERSION = '1.228';

use LWP::UserAgent ();
use Quiq::Option;
use Quiq::Confluence::Markup;
use JSON ();
use Quiq::Confluence::Page;
use HTTP::Request::Common ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Confluence-Client

=head4 Synopsis

  $cli = $class->new(@keyVal);

=head4 Arguments

=over 4

=item url => $url

Basis-URL des Confluence Wiki, z.B. "https://<name>.atlassian.net".

=item user => $user

Name des Confluence-Benutzers, z.B. "admin".

=item password => $password

Passwort des Confluence-Benutzers.

=item verbose => $bool (Default: 0)

Gib Laufzeit-Informationen auf STDERR aus.

=back

=head4 Returns

Client-Objekt (Typ Quiq::Confluence::Client)

=head4 Description

Instantiiere einen Client für Confluence mit den Eigenschaften
@keyval und liefere eine Referenz auf dieses Objekt zurück.

=head4 Example

Client für Atlassian Demo-Instanz:

  $cli = Quiq::Confluence::Client->new(
      url => 'https://<name>.atlassian.net',
      user => 'admin',
      password => '<password>',
      verbose => 1,
  );

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        url => undef,
        user => undef,
        password => undef,
        verbose => 0,
        ua => LWP::UserAgent->new,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Confluence Operationen

=head3 createPage() - Erzeuge Confluence Seite

=head4 Synopsis

  $pag = $cli->createPage($parentId,$title,$markup,@opts);

=head4 Arguments

=over 4

=item parentId => $pageId

Die Page-Id der übergeordneten Seite.

=item $title

Der Titel der Seite.

=item $markup

Seiteninhalt in Confluence Wiki Markup.

=back

=head4 Options

=over 4

=item -warning => $bool (Default: 0)

Setze eine Warnung an den Anfang der Seite, dass die Seite automatisch
generiert wurde.

=back

=head4 Returns

nichts

=head4 Description

Erzeuge eine Confluence-Seite mit Titel $title und Inhalt $markup
(= Wiki Code) als Unterseite von der Seite mit der Seiten-Id
$parentId und liefere das Seiten-Objekt der der erzeugten Seite
zurück.

Die erzeugte Seite ist (notwendigerweise) demselben Space wie die
übergeordnete Seite zugeordnet.

=cut

# -----------------------------------------------------------------------------

sub createPage {
    my ($self,$parentId,$title,$markup,@opts) = @_;

    # Optionen

    my $warning = 0;

    Quiq::Option->extract(\@_,
        -warning => \$warning,
    );

    # Führe Operation aus

    if ($warning) {
        my $gen = Quiq::Confluence::Markup->new;
        $markup = $gen->paragraph(
            $gen->fmt('italic',q~
                Achtung: Diese Seite wurde von einem Programm erzeugt.
                Manuelle Änderungen gehen mit der nächsten Erzeugung
                verloren!
            ~),
        ).$markup;
    }

    my $pag = $self->getPage($parentId);

    my $res = $self->send(
        POST => "rest/api/content",
        'application/json',
        JSON::encode_json({
            title => $title,
            type => 'page',
            space => {
                key => $pag->space,
            },
            $parentId? (
                ancestors => [{
                    id => $parentId,
                }],
            ): (),
            body => {
                storage => {
                    representation => 'wiki',
                    value => $markup,
                },
            },
        })
    );

    # Instantiiere Seiten-Objekt der erzeugten Seite und liefere
    # dieses zurück

    $pag = Quiq::Confluence::Page->new($res->content);
    if ($self->verbose) {
        warn sprintf "---RESULT---\n%s\n",$pag->asString;
    }

    return $pag;
}

# -----------------------------------------------------------------------------

=head3 deletePage() - Lösche Confluence Seite

=head4 Synopsis

  $pag = $cli->deletePage($pageId);

=head4 Arguments

=over 4

=item $pageId

Seiten-Id

=back

=head4 Returns

Nichts

=head4 Description

Lösche die Confluence-Seite mit der Seiten-Id $pageId.

=cut

# -----------------------------------------------------------------------------

sub deletePage {
    my ($self,$pageId) = @_;

    my $res = $self->send('DELETE',"rest/api/content/$pageId");
    my $pag = Quiq::Confluence::Page->new($res->content);
    if ($self->verbose) {
        warn sprintf "---RESULT---\n%s\n",$pag->asString;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 getPage() - Liefere Confluence Seite

=head4 Synopsis

  $pag = $cli->getPage($pageId);

=head4 Arguments

=over 4

=item $pageId

Seiten-Id

=back

=head4 Returns

Seiten-Objekt (Typ Quiq::Confluence::Page)

=head4 Description

Rufe die Confluence-Seite mit der Seiten-Id $pageId ab und liefere
ein Seiten-Objekt vom Typ Quiq::Confluence::Page zurück.

=cut

# -----------------------------------------------------------------------------

sub getPage {
    my ($self,$pageId) = @_;

    # my $res = $self->send('GET',"rest/api/content/$pageId");
    my $res = $self->send('GET',"wiki/rest/api/content/$pageId");
    my $pag = Quiq::Confluence::Page->new($res->content);
    if ($self->verbose) {
        warn sprintf "---RESULT---\n%s\n",$pag->asString;
    }

    return $pag;
}

# -----------------------------------------------------------------------------

=head3 updatePage() - Aktualisiere Confluence Seite

=head4 Synopsis

  $cli->updatePage($pageId,$markup,@opts);

=head4 Arguments

=over 4

=item $pageId

Seiten-Id

=item $markup

Seiteninhalt in Confluence Wiki Markup

=back

=head4 Options

=over 4

=item -warning => $bool (Default: 0)

Setze eine Warnung an den Anfang der Seite, dass die Seite automatisch
erzeugt wurde.

=item -title => $title

Setze den Seitentitel.

=back

=head4 Returns

nichts

=head4 Description

Ersetze den Inhalt der Confluence-Seite $pageId durch den neuen
Inhalt $markup. Für die Aktualisierung sind vier Angaben
erforderlich:

=over 2

=item *

die PageId der Seite

=item *

der Inhalt der Seite

=item *

der Titel der Seite

=item *

die I<neue> Versionsnummer der Seite

=back

Um die neue Versionsnummer der Seite vergeben zu können, wird
intern zunächst der aktuelle Stand der Seite abgerufen, der
u.a. die bestehende Versionsnummer enthält. Die Versionsnummer ist
eine ganze Zahl, die mit jeder Aktualisierung um 1 erhöht werden
muss.

Der Titel der Seite wird aus dem aktuellen Stand der Seite
übernommen, sofern er nicht mit der Option -title überschrieben
wird.

=cut

# -----------------------------------------------------------------------------

sub updatePage {
    my ($self,$pageId,$markup,@opts) = @_;

    # Optionen

    my $warning = 0;
    my $title = undef;

    Quiq::Option->extract(\@_,
        -warning => \$warning,
        -title => \$title,
    );

    # Führe Operation aus

    if ($warning) {
        my $gen = Quiq::Confluence::Markup->new;
        $markup = $gen->paragraph(
            $gen->fmt('italic',q~
                Achtung: Diese Seite wurde von einem Programm erzeugt.
                Manuelle Änderungen gehen mit der nächsten Erzeugung
                verloren!
            ~),
        ).$markup;
    }
            
    my $pag = $self->getPage($pageId);

    $self->send(
        # PUT => "rest/api/content/$pageId",
        PUT => "wiki/rest/api/content/$pageId",
        'application/json',
        JSON::encode_json({
            type => 'page',
            title => $title || $pag->title,
            body => {
                storage => {
                    representation => 'wiki',
                    value => $markup,
                },
            },
            version => {
                number => $pag->version+1,
            },
        })
    );

    return;
}

# -----------------------------------------------------------------------------

=head3 createAttachment() - Füge Attachment zu Confluence-Seite hinzu

=head4 Synopsis

  $pag = $cli->createAttachment($parentId,$file);

=head4 Arguments

=over 4

=item parentId => $pageId

Die Page-Id der übergeordneten Seite.

=item $file

Pfad zur Attchment-Datei.

=back

=head4 Returns

nichts

=head4 Description

Füge Datei $file als Attachment zur Confluence-Seite mit der
Seiten-Id $pageId hinzu.

=cut

# -----------------------------------------------------------------------------

sub createAttachment {
    my ($self,$parentId,$path) = @_;

    $self->send(
        POST => "rest/api/content/$parentId/child/attachment",
        'form-data',[
            file => [$path],
        ],
    );

    return;
}

# -----------------------------------------------------------------------------

=head2 Hilfsmethoden

Die folgenden Methoden bilden die Grundlage für die Kommunikation
mit dem Confluence-Server. Sie werden normalerweise nicht direkt
gerufen.

=head3 send() - Sende HTTP-Request an Confluence

=head4 Synopsis

  $res = $cli->send($method,$path);
  $res = $cli->send($method,$path,$contentType,$content);

=head4 Arguments

=over 4

=item $method

Die HTTP-Methode, z.B. 'PUT'.

=item $path

Der REST-Pfad, z.B. 'rest/api/content/32788'.

=item $contentType

Der Content-Type des HTTP-Body, z.B. 'application/json'.

=item $content

Der Inhalt des HTTP-Body, z.B. (auf die Toplevel-Attribute umbrochen)

  {"version":{"number":24},
  "body":{"storage":{"representation":"wiki","value":"{cheese}"}},
  "title":"Testseite",
  "type":"page"}

=back

=head4 Returns

HTTP-Antwort (Typ HTTP::Response)

=head4 Description

Sende einen HTTP-Request vom Typ $method mit dem REST-Pfad $path
und dem Body $content vom Typ $contentType an den Confluence-Server
und liefere die resultierende HTTP-Anwort zurück. Im Fehlerfall
wirft die Methode eine Exception.

=cut

# -----------------------------------------------------------------------------

sub send {
    my ($self,$method,$path,$contentType,$content) = @_;
    
    my ($ua,$user,$password,$verbose) =
        $self->get(qw/ua user password verbose/);

    my $req;
    if ($method eq 'POST' && $contentType eq 'form-data') {
        # Attachments. Bei dieser POST-Funktion kann $content
        # eine Array-Referenz mit mehreren Inhalten sein, die
        # per multipart/form-data gepostet werden.

        $req = HTTP::Request::Common::POST(
            $self->url($path),
            'X-Atlassian-Token' => 'nocheck',
            Content_Type => $contentType,
            Content => $content,
        );
    }
    else {
        $req = HTTP::Request->new(
            $method => $self->url($path),
        );
        if ($contentType) {
            $req->header('Content-Type' => "$contentType; charset=utf-8");
            $req->content($content) ;
        }
    }
    $req->authorization_basic($user,$password);

    if ($verbose) {
        warn sprintf "---REQUEST---\n%s",$req->as_string;
    }

    my $res = $ua->request($req);
    if (!$res->is_success) {
        $self->throw(
            'CLIENT-00001: HTTP request failed',
            Request => $self->url($path),
            Method => $method,
            StatusLine => $res->status_line,
            Response => $res->content,
        );
    }
    if ($verbose) {
        warn sprintf "---RESPONSE---\n%s",$res->as_string;
    }

    return $res;
}

# -----------------------------------------------------------------------------

=head3 url() - Erzeuge Request URL

=head4 Synopsis

  $url = $cli->url;
  $url = $cli->url($path);

=head4 Arguments

=over 4

=item $path

REST-API Pfad I<ohne> führenden Slash,
z.B. 'wiki/rest/api/content/32788'.

=back

=head4 Returns

URL (String)

=head4 Description

Erzeuge einen REST-API URL bestehend aus dem beim Konstruktor-Aufruf
angegebenen Server-URL und dem Pfad $path und liefere diesen zurück.
Ohne Argument wird der Server-URL geliefert.

=head4 Example

Der Code

  $cli = Quiq::Confluence::Client->new(
      url => 'https://<name>.atlassian.net',
      ...
  );
  $url = $cli->url('wiki/rest/api/content/32788');

liefert

  https://<name>.atlassian.net/wiki/rest/api/content/32788

=cut

# -----------------------------------------------------------------------------

sub url {
    my ($self,$path) = @_;

    my $url = $self->get('url');
    if ($path) {
        $url .= "/$path";
    }

    return $url;
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
