package Quiq::MediaWiki::Client;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Parameters;
use Quiq::AnsiColor;
use LWP::UserAgent ();
use Quiq::Option;
use Quiq::Debug;
use Quiq::Hash;
use Quiq::Path;
use Quiq::Record;
use Quiq::Url;
use JSON ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::MediaWiki::Client - Clientseitiger Zugriff auf ein MediaWiki

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Diese Klasse implementiert Methoden zur Kommunikation mit einem
MediaWiki über die sogenannte MediaWiki-API.

Die MediaWiki-API wird über api.php (statt index.php) angesprochen.
Die Doku der API wird angezeigt, wenn api.php ohne Parameter
oder mit "action=help&recursivesubmodules=1" (alles auf einer Seite)
aufgerufen wird.

Die MediaWiki-API empfängt und liefert alle Daten in UTF-8.

Insbesondere implementiert die Klasse die Methode $mw->L<load|"load() - Lade Seite oder Mediendatei ins Wiki">(), mit
welcher sowohl Seiten als auch Mediendateien (z.B. Bilder)
"intelligent" geladen werden können.

Bei Angabe der Option -debug => 1 bei Aufruf des Konstruktors
wird die gesamte Kommunikation auf STDERR protokolliert.

=head1 SEE ALSO

=over 2

=item *

L<API Dokumentation|https://www.mediawiki.org/wiki/API> (www.mediawiki.org)

=item *

L<API Lowlevel-Dokumentation|https://www.mediawiki.org/w/api.php?action=help&recursivesubmodules=1>
(www.mediawiki.org)

=item *

Client-Implementierung: quik-mediawiki

=back

=head1 EXAMPLES

Beispiele für MediaWiki URLs:

=over 2

=item *

L<https://www.mediawiki.org/w/api.php>

=item *

L<http://localhost/mediawiki/api.php>
(nicht allgemein aufrufbar)

=item *

L<http://lxv0103.ruv.de:8080/api.php>
(nicht allgemein aufrufbar)

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere MediaWiki-API Client

=head4 Synopsis

    $mw = $class->new($url,@opt);
    $mw = $class->new($url,$user,$password,@opt);

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

Client-Objekt (Referenz)

=head4 Description

Instantiiere einen Client für die MediaWiki-API $url und liefere eine
Referenz auf dieses Objekt zurück.

Der Konstruktor-Aufruf löst I<keinen> Server-Request aus. Sind
$user und $password angegeben, wird der Benutzer erst mit dem
ersten Token-Request eingeloggt. Er wird also nur eingeloggt, wenn
es nötig ist. Vorteil: Ein Client, bei dem sich erst im Laufe der
Ausführung herausstellt, ob er Requests ausführt, muss nicht vorab
einen - ggf.  unnötigen - Login-Request ausführen. (De facto besteht
ein Login-Request aus zwei Requests, da mit dem ersten Aufruf
lediglich der Login-Token geliefert wird.) Solange der Client
Requests ausführt, die kein Login benötigen, werden diese beiden
Requests ebenfalls gespart.

Bei Angabe der Option -debug => 1 bei Aufruf des Konstruktors
wird die gesamte Kommunikation auf STDERR protokolliert.

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
        ua => $ua,
        url => $url,
        user => $user,
        password => $password,
        tokenH => undef, # memoize
        version => undef, # memoize
    );
}

# -----------------------------------------------------------------------------

=head2 Grundlegende Operationen

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

=head4 Returns

Response (Hash-Referenz)

=head4 Description

Melde den Benutzer $user mit Passwort $password auf dem
MediaWiki-Server an. Alternativ ist ein automatisches Login
möglich, was eleganter ist. Siehe Konstruktor.

=head4 Example

    $ perl -MQuiq::MediaWiki::Client -E 'Quiq::MediaWiki::Client->new("http://lxv0103.ruv.de:8080/api.php",-debug=>1)->login("XV882JS","<PASSWORD>")'

=cut

# -----------------------------------------------------------------------------

sub login {
    my ($self,$user,$password) = @_;

    # Login-Request

    my $res = $self->send('POST','login',
        lgname => $user,
        lgpassword => $password,
    );        

    if ($res->{'login'}->{'result'} eq 'NeedToken') {
        # Der erste Login-Request ist fehlgeschlagen, hat aber ein
        # Login-Token geliefert. Wir wiederholen den Aufruf
        # mit dem Login-Token.

        $res = $self->send('POST','login',
            lgname => $user,
            lgpassword => $password,
            lgtoken => $res->{'login'}->{'token'},
        );        
    }

    if ($res->{'login'}->{'result'} ne 'Success') {
        $self->throw(
            'MEDIAWIKI-00099: Login failed',
            User => $user,
            Reason => $res->{'login'}->{'result'},
        );
    }

    # Kein automatisches Login mehr
    $self->autoLogin(0);

    return $res;
}

# -----------------------------------------------------------------------------

=head3 getToken() - Besorge Token für Operation

=head4 Synopsis

    $token = $mw->getToken($action);

=head4 Arguments

=over 4

=item $action

Operation, für die das Token benötigt wird.

=back

=head4 Returns

Token (String)

=head4 Description

Besorge vom Server ein Token zum Ausführen von Operation $action und
liefere dieses zurück. Da das Token je Session für alle Seiten identisch
ist, cachen wir die Tokens, so dass nur eine Serveranfrage nötig ist.

=cut

# -----------------------------------------------------------------------------

sub getToken {
    my ($self,$action) = @_;

    if ($self->autoLogin) {
        # Wir loggen uns mit dem ersten Token-Request automatisch ein.
        # Autologin wird in der Methode login() abgestellt, müssen
        # wir hier nicht machen.
        $self->login($self->user,$self->password);
    }

    my $h = $self->memoize('tokenH',sub {
        my $res = $self->send('GET','tokens');
        my %token = %{$res->{'tokens'}};
        return \%token;
    });

    my $token = $h->{$action.'token'};
    if (!$token) {
        $self->throw(
            'MEDIAWIKI-00099: No token',
            Action => $action,
        );
    }

    return $token;
}

# -----------------------------------------------------------------------------

=head3 editPage() - Speichere Seite

=head4 Synopsis

    $res = $mw->editPage($pageId,$text); # [1]
    $res = $mw->editPage($title,$text);  # [2]

=head4 Arguments

=over 4

=item $pageId

Page-Id der Seite.

=item $title

Titel der Seite.

=item $text

Text der Seite

=back

=head4 Returns

Response (Hash-Referenz)

=head4 Description

Dies ist die Lowlevel-Methode zum Speichern einer Seite oder
des Contents einer Seite. Eine weitergehende Logik, die auch
Titelnderungen erlaubt, implementiert die  Methode $mw->L<load|"load() - Lade Seite oder Mediendatei ins Wiki">().

In Fassung [1] wird der Content der Seite mit der Page-Id $pageId
auf Text $text gesetzt. Die Seite muss existieren.

In Fassung [2] muss die Seite nicht existieren.  Der MediaWiki-Server
implementiert folgende Logik:

=over 2

=item *

Existiert die Seite nicht, wird sie angelegt.

=item *

Existiert die Seite und ist der Text verschieden, wird der
bestehende Text ersetzt.

=item *

Existiert die Seite und ist der Text identisch, wird der
Aufruf vom Wiki-Server ignoriert.

=back

=cut

# -----------------------------------------------------------------------------

sub editPage {
    my ($self,$arg,$text) = @_;

    # Edit-Token besorgen
    my $token = $self->getToken('edit');

    # Seite speichern

    my $res = $self->send('POST','edit',
        token => $token,
        $arg =~ /^\d+$/? (pageid => $arg): (title => $arg),
        text => $text,
    );

    # CAPTCHA behandeln. Wir behandeln den CAPTCH-Type "simple" automatisch.

    if (my $h = $res->{'edit'}->{'captcha'}) {
        my $captchaType = $h->{'type'};
        if ($captchaType eq 'simple') {
            my $captchaId = $h->{'id'};
            my $captchaQuestion = $h->{'question'};

            # Request mit gelöstem CAPTCHA wiederholen

            $res = $self->send('POST','edit',
                captchaid => $captchaId,
                captchaword => eval "$captchaQuestion",
                token => $token,
                $arg =~ /^\d+$/? (pageid => $arg): (title => $arg),
                text => $text,
            );
        }
        else {
            $self->throw(
                'MEDIAWIKI-00099: Unknown CAPTCHA type',
                CaptchaType => $captchaType,
            );
        }
    }

    return $res;
}

# -----------------------------------------------------------------------------

=head3 getPage() - Liefere Seite

=head4 Synopsis

    $pag = $mw->getPage($pageId,@opt);
    $pag = $mw->getPage($title,@opt);

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

Wirf keine Exception, wenn die Seite nicht gefunden wird, sondern
liefere undef.

=back

=head4 Returns

Page-Objekt (Hash-Referenz)

=head4 Description

Ermittele die Seite mit der Page-Id $pageId bzw. dem Titel $title und
liefere diese zurück. Die Methode erkennt eine Page-Id daran, dass
der Wert ausschließlich aus Ziffern besteht. Alles andere wird als
Seitentitel interpretiert.

Der geliefere Hash besitzt folgende Komponenten, die auch per
Accessor-Methode abgefragt werden können:

=over 2

=item *

=over 2

=item *

(= Inhalt der Seite)

=back

=item *

comment

=item *

contentformat

=item *

contentmodel

=item *

ns

=item *

pageid

=item *

parentid

=item *

revid

=item *

size

=item *

timestamp

=item *

title

=item *

user

=back

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

    my $res = $self->send('GET','query',
        $arg =~ /^\d+$/? (pageids => $arg): (titles => $arg),
        prop => 'revisions',
        rvprop => 'ids|flags|timestamp|user|comment|size|content',
    );

    # Extrahiere Seite aus Seitenliste
    my $pag = $self->reduceToPage($res,$sloppy);
    if (!$pag) {
        return undef;
    }

    # Wir bauen die gelieferte Struktur in einen einzelnen Hash um

    my $rev = $pag->{'revisions'}->[0];
    delete $pag->{'revisions'};
    $pag = {%$pag,%$rev};

    if ($self->debug) {
        $self->log('PAGE',Quiq::Debug->dump($pag,colored=>$self->color));
    }

    return Quiq::Hash->new($pag);
}

# -----------------------------------------------------------------------------

=head3 movePage() - Benenne Seite um

=head4 Synopsis

    $res = $mw->movePage($pageId,$newTitle,@opt);
    $res = $mw->movePage($oldTitle,$newTitle,@opt);

=head4 Arguments

=over 4

=item $pageId

Page-Id der Seite.

=item $oldTitle

Titel der Seite.

=item $newTitle

Zukünftiger Titel der Seite.

=back

=head4 Options

=over 4

=item -reason => $text

Grund für die Umbenennung.

=item -redirect => $bool (Default: 1)

Erzeuge ein Redirekt von der alten zur neuen Seite. Wird
-redirect => 0 gesetzt, unterbleibt dies.

=back

=head4 Returns

Response (Hash-Referenz)

=head4 Description

Benenne die Seite mit Page-Id $pageId oder dem Titel $oldTitle
in $newTitle um. Die alte Seite existiert weiterhin. Das Wiki
richtet automatisch eine Umleitung von der alten zur neuen
Seite ein, sofern beim Aufruf nicht -redirect => 0 angegeben wird.

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

    # Edit-Token besorgen
    my $token = $self->getToken('edit');

    # Seite umbenennen

    return $self->send('POST','move',
        token => $token,
        $arg =~ /^\d+$/? (fromid => $arg): (from => $arg),
        to => $newTitle,
        $reason? (reason => $reason): (),
        !$redirect? (noredirect => ''): (),
    );
}

# -----------------------------------------------------------------------------

=head3 siteInfo() - Liefere Information über Server

=head4 Synopsis

    $res = $mw->siteInfo;
    $res = $mw->siteInfo(@properties);

=head4 Arguments

=over 4

=item @properties

Liste der Sysinfo-Properties, die abgefragt werden sollen.

=back

=head4 Returns

Response (Hash-Referenz)

=head4 Description

Ermittele die Server-Eigenschaften (genauer: Eigenschaften-Gruppen)
@properties und liefere das Resultat zurück. Sind keine
Properties angegeben, werden I<alle> (zur Zeit der Implementierung
bekannten) Properties abgefragt.

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

    return $self->send('GET','query',
        meta => 'siteinfo',
        siprop => join('|',@properties),
    );
}

# -----------------------------------------------------------------------------

=head3 uploadFile() - Lade Mediendatei hoch

=head4 Synopsis

    $res = $mw->uploadFile($file);

=head4 Arguments

=over 4

=item $file

Pfad der Datei.

=back

=head4 Options

=over 4

=item -force => $bool (Default: 0)

Lade die Datei auch im Falle von Warnungen hoch, z.B. dass die Datei
im Wiki bereits existiert.

=back

=head4 Returns

Response

=head4 Description

Lade die lokale Mediendatei $file über die Upload-Schnittstelle ins
MediaWiki hoch. Dies ist typischerweise eine Bilddatei.

=head4 See Also

=over 2

=item *

L<API:Upload|https://www.mediawiki.org/wiki/API:Upload>

=item *

L<File Upload per LWP|http://lwp.interglacial.com/ch05_07.htm>

=back

=cut

# -----------------------------------------------------------------------------

sub uploadFile {
    my $self = shift;

    # Optionen und Argumente

    my $force = 0;

    my $argA = Quiq::Parameters->extractToVariables(\@_,1,1,
        -force => \$force,
    );
    my $file = Quiq::Path->expandTilde(shift @$argA);

    # Edit-Token besorgen
    my $token = $self->getToken('edit');

    # Datei hochladen ($file wird von LWP gelesen)

    my $filename = Quiq::Path->filename($file);
    return $self->send('POST','upload',
        token => $token,
        filename => $filename,
        file => [$file],
        ignorewarnings => $force,
    );

=pod

    # Datei hochladen (wir lesen $file selbst)

    my $p = Quiq::Path->new;
    my $data = $p->read($file);

    # Datei hochladen

    my $filename = $p->filename($file);
    return $self->send('POST','upload',
        token => $token,
        filename => $filename,
        file => [undef,$filename,Content=>$data],
    );

=cut
}

# -----------------------------------------------------------------------------

=head3 version() - Versionsnummer des Servers

=head4 Synopsis

    $version = $mw->version;

=head4 Description

Ermittele die Versionsnummer des MediaWiki-Servers und liefere
diese zurück. Die Information wird im Objekt gecached.

=cut

# -----------------------------------------------------------------------------

sub version {
    my $self = shift;

    return $self->memoize('version',sub {
        my $res = $self->siteInfo('general');
        my $version = $res->{'query'}->{'general'}->{'generator'};
        $version =~ s/^MediaWiki\s+//;
        return $version;
   });
}

# -----------------------------------------------------------------------------

=head2 Höhere Operationen

=head3 load() - Lade Seite oder Mediendatei ins Wiki

=head4 Synopsis

    $mw->load($cacheDir,$file,@opt);

=head4 Arguments

=over 4

=item $cacheDir

Pfad zum Spiegel-Verzeichnis. Der Inhalt des Spiegel-Verzeichnisses wird
von der Methode verwaltet. Es enthält Kopien der geladenen Dateien.

=item $file

Pfad der Datei, die geladen werden soll. Dies kann eine Seitendatei
(*.mw) oder eine sonstige Datei sein (*.png, *.jpg, *.gif, ...),
die über die Upload-Schnittstelle des MediaWiki geladen werden kann.

=back

=head4 Options

=over 4

=item -force => $bool (Default: 0)

Lade die Datei ins Wiki, auch wenn sie sich nicht geändert hat
(gegenüber dem Cache).

=back

=head4 Returns

nichts

=head4 Description

Lade Seite oder Mediendatei $file ins Wiki. Hierbei wird ein
"intelligentes" Verfahren angewendet, das verschiedene Sonderfälle
berücksichtigt (siehe unten). Eine Kopie der hochgeladenen Datei
wird im Cache-Verzeichnis $cacheDir abgelegt. Ist die Cache-Version
eines früheren Aufrufs identisch zu zur aktuellen Version $file,
kehrt der Aufruf sofort zurück (außer bei Option -force => 1).
Den Schlüssel stellt der Dateiname dar. Dieser muss über
allen Dateien eindeutig sein und darf sich extern nicht ändern.

Die Datei einer Seite muss die Endung *.mw besitzen und sowohl den
Titel als auch den Inhalt der Seite als Record (siehe
Quiq::Record) enthalten. Eine Mediendatei (*.png, *.jpg, ...)
wird wie sie ist an die Methode übergeben.

In der Cache-Datei einer Seite speichert die Methode die Page-Id
der Seite. Dadurch kann die Methode auch bei Titeländerungen die
Seite im Wiki ermitteln und vor dem Speichern eine move-Operation
ausführen. Die Fälle im Einzelnen:

=over 4

=item Aufruf wird ignoriert

Die Datei existiert im Cache und ist identisch zu dieser
und -force ist nicht gesetzt.

=item Seite oder Mediendatei wird im Wiki gespeichert

=over 2

=item *

Die Datei existiert nicht im Cache

=item *

Die Datei existiert im Cache und ist gegenüber der externen
Datei verschieden

=item *

Option -force ist gesetzt

=back

=item Aufruf wird mit Fehlermeldung zurückgewiesen

Die Datei ist eine Seite und soll gespeichert werden, wobei ein
Unterschied zwischen Cache- und Wiki-Datei festgestellt wird.
Das bedeutet, im Wiki wurde die Datei seit dem letzten Speichern
geändert. Der Aufruf ist nur durch Setzen der Option -force möglich,
denn die Änderung muss händisch in die externe Datei eingepflegt
werden.

=item Seite wird vor dem Speichern umbenannt

Die Datei ist eine Seite und der Titel der Seite ist zwischen
Cachedatei und externer Datei unterschiedlich. Die Seite wird
automatisch im Wiki umbenannt.

=back

=cut

# -----------------------------------------------------------------------------

sub load {
    my $self = shift;
    # @_: $cacheDir,$file,@opt

    # Optionen und Argumente

    my $force = 1;

    my $argA = Quiq::Parameters->extractToVariables(\@_,2,2,
        -force => \$force,
    );
    my ($cacheDir,$file) = @$argA;

    # Pfad-Objekt für Pfad-Operationen instantiieren
    my $p = Quiq::Path->new;

    my $cacheName = $p->filename($file);
    my $varFile = sprintf '%s/%s',$cacheDir,$cacheName;

    my $ext = $p->extension($file);
    if ($ext ne 'mw') {
        # Datei Upload

        my $exists = $p->exists($varFile);
        if ($force || !$exists || $p->compare($file,$varFile)) {
            my $res = $self->uploadFile($file,-force=>1);
            printf "File %s: %s\n",$exists? 'updated': 'created',
                ucfirst $cacheName;
            $p->copy($file,$varFile);
        }

        return;
    }

    # Externe Seite: Information (Titel, Inhalt) ermitteln

    my $pageCode = $p->read($file,-decode=>'utf-8');
    my $recNew = Quiq::Hash->new(Quiq::Record->fromString($pageCode));
    my ($titleNew,$contentNew) = $recNew->get('Title','Content');

    # Cache-Seite: Information (Id, Titel, Inhalt) ermitteln.
    # Existiert keine Cache-Seite, versuchen wir, die Seite über
    # den Titel im Wiki zu finden. Falls sie im Wiki existiert, erzeugen
    # wir aus ihr die Cache-Seite. Falls nicht, legen wir eine leere
    # Cache-Seite an (die notwendig von der externen Seite differiert).

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
            -format => '@',
            -space => 1,
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

        if (!$force && $titleNew eq $titleOld && $contentNew eq $contentOld) {
            # Keine Differenz, es gibt nichts zu tun.
            return;
        }
        if ($contentNew ne $contentOld) {
            # Der Inhalt zwischen der externen Seite und der Cache-Seite
            # hat sich geändert. Wir prüfen ob die Wiki-Seite geändert
            # wurde, also zwischen dem Inhalt der Cache-Seite und
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
            # Der Titel zwischen der externen Seite und der Cache-Seite
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
        -format => '@',
        -space => 1,
    );
    $p->write($varFile,$data,
        -encode => 'UTF-8',
    );

    printf "Page %sd: pageId=%s '%s'\n",$op,$pageId,$titleNew;

    return;
}

# -----------------------------------------------------------------------------

=head2 Kommunikation

=head3 send() - Sende Request, empfange Response

=head4 Synopsis

    $res = $mw->send($method,$action,@keyVal);

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

    my ($ua,$url) = $self->get(qw/ua url/);

    # Wir wollen die Antwort in JSON

    # my @keyVal = (action=>$action,formatversion=>2,format=>'json',@_);
    my @keyVal = (action=>$action,format=>'json',@_);

    # HTTP-Request erzeugen und ausführen (lassen sich die Aufrufe
    # ohne Fallunterscheidung vereinheitlichen?)

    my $res;
    if ($action eq 'upload') {
        # Im Falle eines File-Upload muss die Liste der Schlüssel/Wert-Paare
        # per Array-Referenz übergeben werden und die hochzuladende Datei
        # per file => [undef,$name,Content=>$data] (siehe Methode upload)
        $res = $ua->post($url,[@keyVal],Content_Type=>'form-data');
    }
    elsif ($method eq 'GET') {
        my $queryString = Quiq::Url->queryEncode(-separator=>'&',@keyVal);
        $res = $ua->get("$url?$queryString");
    }
    elsif ($method eq 'POST') {
        $res = $ua->post($url,[@keyVal]);
    }
    else {
        $self->throw(
            'MEDIAWIKI-00099: Unknown request method',
            Method => $method,
        );
    }

    # Logge Request

    if ($self->debug) {
        $self->log('REQUEST',$res->request->as_string);
    }

    if (!$res->is_success) {
        $self->throw(
            'MEDIAWIKI-00099: HTTP request failed',
            Request => $res->request->as_string,
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
            'MEDIAWIKI-00099: API error',
            Request => $res->request->as_string,
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

=head3 reduceToPage() - Reduziere Antwort auf Einzelseite

=head4 Synopsis

    $pag = $mw->reduceToPage($res);
    $pag = $mw->reduceToPage($res,$sloppy);

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

Reduziere die Server-Response $res mit einer einelementigen
Seitenliste der Art

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
            'MEDIAWIKI-00099: More than one page',
            PageIds => "@pageIds",
        );
    }

    # Ungültiges Element?
    # Existiert die Seite nicht, hat die pageid den Wert -1 oder die
    # Seiteninformation enthält die Komponente missing (missing => ''),
    # wirf eine Exception-

    my $pag = $res->{'query'}->{'pages'}->{$pageIds[0]};
    if ($pageIds[0] == -1 || exists $pag->{'missing'}) {
        if ($sloppy) {
            return undef;
        }
        $self->throw(
            'MEDIAWIKI-00099: Page not found',
        );
    }

    return $pag;
}

# -----------------------------------------------------------------------------

=head2 Logging

=head3 log() - Schreibe Debug Log

=head4 Synopsis

    $mw->log($title,$text);

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

1.147

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
