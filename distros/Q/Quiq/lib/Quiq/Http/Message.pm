# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Http::Message - HTTP-Nachricht

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt dieser Klasse repräsentiert eine HTTP-Nachricht. Eine
HTTP-Nachricht besteht aus einer oder mehreren Kopfzeilen (Header) und
einem optionalen Rumpf (Body). Kopfzeilen und Rumpf werden von der Klasse
als Attribute implementiert, die durch Methoden der Klasse manipuliert
werden können. Eine HTTP-Nachricht, die versendet werden kann,
entsteht durch Erzeugen einer Stringrepräsentation des Objekts.

Die Klasse kann für HTTP-Requests als auch für HTTP-Responses
verwendet werden. Ggf. müssen weitere Header eingeführt werden.

MEMO: Die Klasse ist nach dem Vorbild von R1::HttpResponse entstanden.
Diese sollte so angepasst werden, dass sie Quiq::Http::Message
als Basisklasse verwendet.

=head1 EXAMPLES

=head2 Einfache HTTP-Nachricht

  my $msg = Quiq::Http::Message->new(
      contentType => 'text/plain',
      body => "Hello world\n"
  );
  print $msg->asString;

generiert auf STDOUT

  Content-Type: text/plain
  Content-Length: 12
  
  Hello world

=head2 HTTP-Nachricht über Socket schicken (siehe auch Quiq::Http::Client)

  my $sock = Quiq::Socket->new($host,$port);
  
  my $msg = Quiq::Http::Message->new(
      contentType => 'text/plain',
      body => "Hello world\n"
  );
  
  print $sock $msg->asString;

=head2 HTTP-Nachricht vom Server empfangen

  my $msg = Quiq::Http::Message->new(received=>1,$socket);
  print $msg->asString;

Die Setzung received=>1 bewirkt, dass wir bei der Auswertung der
Headerzeilen nicht strikt sind, d.h. bei unbekannten Headern wird
keine Exception geworfen, und die Methode $msg->L<asString|"asString() - Liefere HTTP-Nachricht als Zeichenkette">()
liefert die Headerinformation exakt so wie sie empfangen wurde, d.h.
sie wird nicht aus den Attributen gewonnen.

=head2 HTTP-Nachricht aus Datei

  my $msg = Quiq::Http::Message->new('http/message01.txt');
  print $msg->asString;

=cut

# -----------------------------------------------------------------------------

package Quiq::Http::Message;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;
use utf8;

our $VERSION = '1.228';

use Quiq::Reference;
use Quiq::Http::Cookie;
use Quiq::FileHandle;
use Scalar::Util ();
use MIME::Base64 ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=cut

# -----------------------------------------------------------------------------

# Private Methode zum Ermitteln/Setzen eines Attributs

my $GetSet = sub {
    my $self = shift;
    my $key = shift;
    # @_: $val

    my $ref = \$self->{$key};
    if (@_) {
        $$ref = shift;
    }

    return $$ref;
};

# -----------------------------------------------------------------------------

=head3 new() - Instantiiere ein HTTP Nachrichten-Objekt

=head4 Synopsis

  $http = $class->new(@keyVal);
  $http = $class->new(@keyVal,$fh);
  $http = $class->new(@keyVal,$file);
  $http = $class->new(@keyVal,\$str);

=head4 Returns

Referenz auf HTTP-Objekt.

=head4 Description

Instantiiere ein HTTP Nachrichten-Objekt mit den Eigenschaften @keyVal.

Folgende Eigenschaften können (u.a.) gesetzt werden:

=over 2

=item *

contentType => $type

=item *

charset => $charset

=item *

contentLength => $n | -1

=item *

expires => $date | 'now' | 0

=item *

location => $url

=item *

setCookie => [$name=>$value,@keyVal]

=item *

refresh => [$n,$url]

=item *

body => $data

=back

Zum Setzen von Eigenschaften siehe auch die Methoden $msg->L<set|"set() - Setze Objekteigenschaften">()
und $msg->L<fromString|"fromString() - Setze Objektattribute aus Zeichenkette">().

Ist eine ungerade Anzahl an Parametern angegeben, wird zunächst
die (ggf. leere) Liste von Attribut/Wert-Paaren @keyVal zugewiesen.
Alle weiteren Eigenschaften werden via Handle $fh, Datei $file
oder String $str gewonnen.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal -or- @keyVal,$source -or- $source

    my $self = $class->SUPER::new(
        received => 0,
        protocol => undef,
        status => undef,
        statusText => undef,
        contentType => undef,
        transferEncoding => undef,
        charset => undef,
        contentLength => undef,
        expires => undef,
        location => undef,
        refresh => [undef,undef],
        setCookie => [],
        host => undef,
        connection => undef,
        #wwwAuthenticate => undef,
        authorization => undef,
        userAgent => undef,
        body => '',
    );

    if (@_%2) {
        # Ungerade Anzahl an Parametern. Letztes Argument ist die Quelle,
        # aus der weitere Eigenschaften des Objekts gelesen werden.

        my $source = pop;
        $self->set(@_);
        $self->fromString($source);
    }
    else {
        $self->set(@_);
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Attribute

=head3 set() - Setze Objekteigenschaften

=head4 Synopsis

  $http->set(@keyVal);

=head4 Returns

Die Methode liefert keinen Wert zurück.

=head4 Description

Setze die Objekteigenschaften @keyVal. Für die Liste der
Eigenschaften siehe L<new|"new() - Instantiiere ein HTTP Nachrichten-Objekt">().

=head4 Examples

Ein HTTP-Request ohne Inhalt:

  $http->set(
      host => $host,
      connection => 'close',
  );

Eine HTTP-Response:

  $http->set(
      contentType => 'text/html',
      charset => 'utf-8',
      setCookie => [id=>4711],
      setCookie => [user=>'seitzf'],
      body => "Test\n",
  );

=cut

# -----------------------------------------------------------------------------

sub set {
    my $self = shift;
    # @_: @keyVal

    while (@_) {
        my $key = shift;
        my $val = shift;
        $self->$key(Quiq::Reference->isArrayRef($val)? @$val: $val);
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Kopfzeilen (Header)

Dieser Abschnitt beschreibt die Methoden zum Setzen und Abfragen
von Kopfzeilen. Generell gilt: Ist ein Argument angegeben, wird die
betreffende Kopfzeile gesetzt. Ist kein Argument angegeben, wird der
Wert der Kopfzeile geliefert.

Der Name der Methode entspricht dem Namen der HTTP-Kopfzeile unter
Anwendung folgender Transformationsregeln:

=over 2

=item *

der erste Buchstabe ist klein geschrieben

=item *

Bindestriche sind entfernt

=item *

mehrere Worte sind in "camel case" zusammengesetzt

=back

Beispiel: Die Kopfzeile "Content-Type" wird von der
Methode contentType() verwaltet.

Der Wert einer Kopfzeilen-Methode ist nicht immer eine Zeichenkette.
Er kann auch eine Datenstruktur sein. Dies hängt von der jeweiligen
Kopfzeile ab. Im Skalarkontext wird eine Referenz auf die Datenstruktur
geliefert, im Array-Kontext die Liste der Elemente (siehe L<contentType|"contentType() - Setze/Liefere Content-Type Header">()
oder L<setCookie|"setCookie() - Setze/Liefere Set-Cookie Header">()).

=head3 received() - Setze/Liefere received-Eigenschaft

=head4 Synopsis

  $bool = $http->received($bool);
  $bool = $http->received;

=cut

# -----------------------------------------------------------------------------

sub received {
    return shift->$GetSet('received',@_);
}

# -----------------------------------------------------------------------------

=head3 protocol() - Setze/Liefere Protokoll-Bezeichnung

=head4 Synopsis

  $protocol = $http->protocol($protocol);
  $protocol = $http->protocol;

=head4 Description

Die Protokoll-Bezeichnung steht in der ersten Zeile einer Server-Antwort
und hat die Form "HTTP/X.Y".

=cut

# -----------------------------------------------------------------------------

sub protocol {
    return shift->$GetSet('protocol',@_);
}

# -----------------------------------------------------------------------------

=head3 status() - Setze/Liefere HTTP-Status

=head4 Synopsis

  $status = $http->status($status);
  $status = $http->status;

=head4 Description

Der Status steht in der ersten Zeile einer Server-Antwort
und ist ein dreistelliger Code in der Form NNN.

=cut

# -----------------------------------------------------------------------------

sub status {
    return shift->$GetSet('status',@_);
}

# -----------------------------------------------------------------------------

=head3 statusText() - Setze/Liefere HTTP-StatusText

=head4 Synopsis

  $statusText = $http->statusText($statusText);
  $statusText = $http->statusText;

=head4 Description

Der StatusText steht in der ersten Zeile einer Server-Antwort
und ist eine textuelle Beschreibung des Statuscode.

=cut

# -----------------------------------------------------------------------------

sub statusText {
    return shift->$GetSet('statusText',@_);
}

# -----------------------------------------------------------------------------

=head3 contentType() - Setze/Liefere Content-Type Header

=head4 Synopsis

  $type = $http->contentType($type);
  $type = $http->contentType;

=cut

# -----------------------------------------------------------------------------

sub contentType {
    return shift->$GetSet('contentType',@_);
}

# -----------------------------------------------------------------------------

=head3 charset() - Setze/Liefere Charset

=head4 Synopsis

  $charset = $http->charset($charset);
  $charset = $http->charset;

=head4 Description

Setze/Liefere den Zeichensatz, der ergänzend im Content-Type
Header angegeben wird.

=cut

# -----------------------------------------------------------------------------

sub charset {
    return shift->$GetSet('charset',@_);
}

# -----------------------------------------------------------------------------

=head3 authorization() - Setze/Liefere Authorization-Information

=head4 Synopsis

  $userPass = $http->authorization($userPass);
  $userPass = $http->authorization;

=cut

# -----------------------------------------------------------------------------

sub authorization {
    return shift->$GetSet('authorization',@_);
}

# -----------------------------------------------------------------------------

=head3 transferEncoding() - Setze/Liefere Transfer-Encoding

=head4 Synopsis

  $val = $http->transferEncoding($val);
  $val = $http->transferEncoding;

=cut

# -----------------------------------------------------------------------------

sub transferEncoding {
    return shift->$GetSet('transferEncoding',@_);
}

# -----------------------------------------------------------------------------

=head3 contentLength() - Setze/Liefere Content-Length Header

=head4 Synopsis

  $n = $http->contentLength($n);
  $n = $http->contentLength;

=cut

# -----------------------------------------------------------------------------

sub contentLength {
    return shift->$GetSet('contentLength',@_);
}

# -----------------------------------------------------------------------------

=head3 expires() - Setze/Liefere Expires Header

=head4 Synopsis

  $val = $http->expires($val);
  $val = $http->expires;

=cut

# -----------------------------------------------------------------------------

sub expires {
    return shift->$GetSet('expires',@_);
}

# -----------------------------------------------------------------------------

=head3 host() - Setze/Liefere Header Host:

=head4 Synopsis

  $host = $http->host($host);
  $host = $http->host;

=cut

# -----------------------------------------------------------------------------

sub host {
    return shift->$GetSet('host',@_);
}

# -----------------------------------------------------------------------------

=head3 userAgent() - Setze/Liefere Wert von Header UserAgent:

=head4 Synopsis

  $userAgent = $http->userAgent($userAgent);
  $userAgent = $http->userAgent;

=cut

# -----------------------------------------------------------------------------

sub userAgent {
    return shift->$GetSet('userAgent',@_);
}

# -----------------------------------------------------------------------------

=head3 connection() - Setze/Liefere Header Connection:

=head4 Synopsis

  $val = $http->connection($val);
  $val = $http->connection;

=cut

# -----------------------------------------------------------------------------

sub connection {
    return shift->$GetSet('connection',@_);
}

# -----------------------------------------------------------------------------

=head3 location() - Setze/Liefere Location: Header

=head4 Synopsis

  $url = $http->location($val);
  $url = $http->location;

=cut

# -----------------------------------------------------------------------------

sub location {
    return shift->$GetSet('location',@_);
}

# -----------------------------------------------------------------------------

=head3 refresh() - Setze/Liefere Refresh-Header

=head4 Synopsis

  $http->refresh($n);
  $http->refresh($n,$url);
  ($n,$url) = $http->refresh;
  $arr = $http->refresh;

=cut

# -----------------------------------------------------------------------------

sub refresh {
    my $self = shift;
    # @_: $n,$url

    my $arr = $self->$GetSet('refresh');
    if (@_ == 0) {
        return wantarray? @$arr: $arr;
    }
    elsif (@_ == 1) {
        $arr->[0] = shift;
    }
    else {
        @$arr = @_;
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 setCookie() - Setze/Liefere Set-Cookie Header

=head4 Synopsis

  $http->setCookie($name=>$value,@options);
  @cookies = $http->setCookie;
  $cookieA = $http->setCookie;

=head4 Description

Definiere Cookie $name mit Wert $value und Optionen @options.
Existiert Cookie $name bereits, wird seine Definition überschrieben.
Die Methode liefert beim Setzen keinen Wert zurück.

Ohne Parameter gerufen liefert die Methode die Liste der
Cookie-Objekte zurück. Im Skalarkontext wird eine Referenz auf
die Liste geliefert.

=head4 Example

Generiere Id und setze permanenten Cookie, der nach 5 Jahren abläuft:

  $id = Quiq::Converter->intToWord(time);
  $http->setCookie(
      id => $id,
      expires => '+5y',
  );

=cut

# -----------------------------------------------------------------------------

sub setCookie {
    my $self = shift;
    # @_: $name=>$value,@options

    my $arr = $self->$GetSet('setCookie');
    if (@_ == 0) {
        return wantarray? @$arr: $arr;
    }

    # Wir prüfen, ob ein Cookie des angegebenen Namens bereits existiert.
    # Wenn ja, ersetzen wir ihn. Wenn nein, fügen wir ihn hinzu.

    my $cok = Quiq::Http::Cookie->new(@_);
    for (my $i = 0; $i < @$arr; $i++) {
        if ($arr->[$i]->get('name') eq $_[0]) {
            $arr->[$i] = $cok;
            return;
        }
    }
    push @$arr,$cok;

    return;
}

# -----------------------------------------------------------------------------

=head2 Rumpf (Body)

Der Body der HTTP-Antwort ist per Default leer, d.h. sein Wert ist,
sofern beim Konstruktoraufruf nichts anderes angegeben wird,
ein Leerstring.

Der Body kann gesetzt werden:

  $http->body($data);

Oder er kann per Referenz "in place" manipuliert werden:

  $ref = $http->bodyRef;
  $$ref =~ /__TIME__/strftime '%F %H:%M:%S %Z',localtime/eg;

Sein Wert wird geliefert durch:

  $data = $http->body;

=head3 body() - Setze/Liefere Body

=head4 Synopsis

  $body = $http->body($body);
  $body = $http->body;

=cut

# -----------------------------------------------------------------------------

sub body {
    return shift->$GetSet('body',@_);
}

# -----------------------------------------------------------------------------

=head3 bodyRef() - Liefere Referenz auf Body

=head4 Synopsis

  $ref = $http->bodyRef;

=cut

# -----------------------------------------------------------------------------

sub bodyRef {
    return \shift->{'body'};
}

# -----------------------------------------------------------------------------

=head3 append() - Füge Daten zum Rumpf hinzu

=head4 Synopsis

  $http->append($data);

=cut

# -----------------------------------------------------------------------------

sub append {
    my ($self,$data) = @_;

    my $ref = $self->bodyRef;
    $$ref .= $data;

    return;
}

# -----------------------------------------------------------------------------

=head2 Externe Repräsentation

=head3 fromString() - Setze Objektattribute aus Zeichenkette

=head4 Synopsis

  $http->fromString($fh);
  $http->fromString($file);
  $http->fromString(\$str);

=head4 Description

Die Methode liest eine HTTP-Message als Zeichenkette ein, zerlegt sie
in ihre Bestandteile und weist die enthaltene Information den
Komponenten des Objektes zu.

Als Quelle kann eine Handle (Filehandle, Socket) eine Datei (Dateiname)
oder eine Zeichenkette (Skalar-Referenz) angegeben werden.

=cut

# -----------------------------------------------------------------------------

sub fromString {
    my ($self,$fh) = @_;

    my $received = $self->received;

    my $refType = Scalar::Util::reftype($fh) || '';
    if ($refType ne 'GLOB') {
        # $fh ist Dateiname oder Stringreferenz
        $fh = Quiq::FileHandle->new('<',$fh);
    }

    my $transferEncoding = '';

    while (<$fh>) {
        s/\r?\n$//;
        if (/^$/) {
            last;
        }

        # Headerzeilen an Attribute zuweisen

        if (/^HTTP/) {
            # erste Zeile: PROTOCOL STATUS STATUSTEXT

            my ($protocol,$status,$statusText) = split ' ';
            $self->protocol($protocol);
            $self->status($status);
            $self->statusText($statusText);

            next;
        }
        elsif (/^Status: (\d+) (.*)/i) {
            $self->status($1);
            $self->statusText($2);
        }
        elsif (/^Content-Type: (.*)/i) {
            my $str = $1;

            $str =~ /([^;\s]+)/;
            $self->contentType($1);

            if ($str =~ /charset=([^;\s]+)/) {
                $self->charset($1);
            }
        }
        elsif (/^Location: (.*)/i) {
            $self->location($1);
        }
        elsif (/^Content-Length: (.*)/i && !$received) {
            $self->contentLength($1);
        }
        elsif (/^Transfer-Encoding: (.*)/i && $received) {
            $transferEncoding = $1;
        }
        # Date:
        # Pragma:
        # Connection:
        # Set-Cookie:
        # Expires:
        # Server:
        # Cache-Control:
        # Accept-Ranges:
        # Alternate-Protocol:
        # Vary:
        # P3P:
        # X-(.*?):
        elsif (!$received) {
            $self->throw(
                'HTTP-00003: Unbekannte HTTP Headerzeile',
                Line => $_,
            );
        }
    }

    my $body = '';
    if ($transferEncoding =~ /chunked/i) {
        while (<$fh>) {
            # Länge Chunk

            s/\r?\n$//;
            my $n = hex;
            if ($n == 0) {
                scalar <$fh>; # \r\n am Schluss überlesen
                last;
            }

            # Chunk lesen

            my $r = read $fh,(my $data),$n;
            if (!$r) {
                last;
            }
            $body .= $data;

            # \r\n nach Chunk überlesen
            read $fh,$data,2;
        }
    }
    elsif (!$transferEncoding) {
        while (<$fh>) {
            $body .= $_;
        }
    }
    else {
        $self->throw(
            'HTTP-00001: Transfer-Encoding nicht unterstützt',
            Value => $transferEncoding,
        );
    }
    $fh->close;

    # Dekodiere Body

    my $charset = $self->charset || 'ISO-8859-1';
    $self->body(Encode::decode($charset,$body));

    return;
}

# -----------------------------------------------------------------------------

=head3 asString() - Liefere HTTP-Nachricht als Zeichenkette

=head4 Synopsis

  $str = $http->asString;

=cut

# -----------------------------------------------------------------------------

sub asString {
    my $self = shift;

    my $str = '';
    my $bodyRef = $self->bodyRef;

    # Host:

    if (my $host = $self->host) {
        $str .= "Host: $host\n";
    }

    # UserAgent:

    if (my $userAgent = $self->userAgent) {
        $str .= "UserAgent: $userAgent\n";
    }

    # Location:

    if (my $location = $self->location) {
        $str .= "Location: $location\n";
    }

    # Authorization:

    if (my $userPass = $self->authorization) {
        $str .= sprintf "Authorization: Basic %s\n",
            MIME::Base64::encode_base64($userPass,'');
    }

    # Content-Type:

    if (my $type = $self->contentType) {
        $str .= "Content-Type: $type";

        # charset=

        if (my $charset = $self->charset) {
            $str .= "; charset=$charset";
        }
        $str .= "\n";
    }

    # Content-Length: (bei -1 wird der Wert berechnet)

    my $len = $self->contentLength;
    if (defined $len) {
        if ($len == -1) {
            $len = bytes::length($$bodyRef);
        }
        $str .= sprintf "Content-Length: $len\n",;
    }

    # Set-Cookie:

    for my $cok ($self->setCookie) {
        $str .= sprintf "Set-Cookie: %s\n",$cok->asString;
    }

    # Refresh:

    my ($n,$url) = $self->refresh;
    if (defined $n) {
        # Frage: Ist $url erforderlich?
        $str .= "Refresh: $n; url=$url\n";
    }

    # Expires:

    if (my $expires = $self->expires) {
        $str .= "Expires: $expires\n";
    }

    # Connection:

    if (my $connection = $self->connection) {
        $str .= "Connection: $connection\n";
    }

    # Body

    $str .= "\n";
    $str .= $$bodyRef;

    return $str;
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
