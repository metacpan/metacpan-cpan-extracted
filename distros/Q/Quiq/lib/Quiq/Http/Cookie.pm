package Quiq::Http::Cookie;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Quiq::Time::RFC822;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Http::Cookie - HTTP-Cookie

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen HTTP-Cookie gemäß der klassischen
L<Netscape-Spezifikation|http://de.wikipedia.org/wiki/HTTP-Cookie#Cookie_nach_Netscape>. Die Klasse wird typischerweise verwendet,
um Set-Cookie Header zu generieren.

=head1 ATTRIBUTES

=over 4

=item name => $name

Der Name des Cookie.

=item value => $value

Der Wert des Cookie.

=item domain => $domain (optional)

Die Domain, an die der Browser den Cookie schickt. Fehlt die Angabe,
nimmt der Browser den Hostnamen des URL an.

=item path => $path (optional)

Der Pfad, an den der Browser den Cookie schickt. Fehlt die Angabe,
nimmt der Browser den Pfad des URL an.

=item expires => $time (optional)

Verfallszeitpunkt des Cookie nach RFC822 im Format
"Wdy, DD Mon YYYY HH:MM:SS GMT" oder mit einer Zeitangabe nach
Quiq::Time::RFC822 (siehe Abschnitt L<EXAMPLES|"EXAMPLES">). Fehlt die Angabe,
verfällt der Cookie mit dem Schließen des Browsers.

=item secure => $bool (optional)

Wenn wahr, wird der Cookie vom Browser nur über eine sichere
HTTPS-Verbindung geschickt.

=back

=head1 SEE ALSO

=over 2

=item *

Cookie-Spezifikation von Netscape
(L<http://de.wikipedia.org/wiki/HTTP-Cookie#Cookie_nach_Netscape>)

=back

=head1 EXAMPLES

=head2 Cookie für eine Browser-Sitzung

    my $cok = Quiq::Http::Cookie->new(sid=>4711);
    print 'Set-Cookie: ',$cok->asString;
    __END__
    Set-Cookie: sid=4711

=head2 Cookie verfällt in einem Jahr (Aufruf am 2011-11-11 12:24:12 GMT)

    my $cok = Quiq::Http::Cookie->new(sid=>4711,expires=>'+1y');
    print 'Set-Cookie: ',$cok->asString;
    __END__
    Set-Cookie: sid=4711; expires=Fri, 11-Nov-2012 12:24:12 GMT

Die Angabe '+1y' wird von Methode L<asString|"asString() - Generiere Zeichenketten-Repräsentation">() durch Aufruf
von Quiq::Time::RFC822->get() in eine gültige RFC822-Datumsangabe
gewandelt. Weitere abkürzende Schreibweisen siehe dort.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $cok = $class->new($name=>$value,@keyVal);

=head4 Returns

Referenz auf das Cookie-Objekt.

=head4 Description

Instantiiere einen Cookie mit Name $name, Wert $value und den
optionalen Attributen @keyVal.

Siehe Abschnitt L<ATTRIBUTES|"ATTRIBUTES"> für mögliche Werte für @keyVal.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $name = shift;
    my $value = shift;
    # @_: @options

    my $self = $class->SUPER::new(
        name => $name,
        value => $value,
        domain => undef,
        path => undef,
        expires => undef,
        secure => 0,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 asString() - Generiere Zeichenketten-Repräsentation

=head4 Synopsis

    $str = $cok->asString;

=head4 Returns

Zeichnketten-Repräsentation des Cookie.

=head4 Description

Generiere eine Zeichenketten-Repräsentation des Cookie, die als
Wert für einen Set-Cookie Header eingesetzt werden kann.

=cut

# -----------------------------------------------------------------------------

sub asString {
    my $self = shift;

    my ($name,$value,$domain,$path,$expires,$secure) =
        $self->get(qw/name value domain path expires secure/);

    my $str = "$name=$value";
    if ($domain) {
        $str .= "; domain=$domain";
    }
    if ($path) {
        $str .= "; path=$path";
    }
    if (defined $expires) {
        if ($expires eq '0' || $expires eq 'now') {
            # 0 ist ungeeignet, da Netscape Cookies
            # mit diesem Datum ignoriert
            $expires = 1;
        }
        $str .= sprintf "; expires=%s",Quiq::Time::RFC822->get($expires);
    }
    if ($secure) {
        $str .= '; secure';
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head1 CAVEATS

Der Name und der Wert des Cookie werden aktuell nicht kodiert.
Name und Wert sollten daher nur aus druckbaren ASCII-Zeichen
ohne Semikolon, Komma, Gleichheitszeichen und Leerzeichen bestehen.

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
