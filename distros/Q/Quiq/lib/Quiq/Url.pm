# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Url - Operationen im Zusammenhang mit URLs

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Die Klasse definiert Operationen, die im Zusammenhang mit URLs
nützlich sind.

=cut

# -----------------------------------------------------------------------------

package Quiq::Url;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Encode ();
use Quiq::Array;
use Quiq::Option;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $u = $class->new;

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück. Da die Klasse ausschließlich Klassenmethoden
enthält, hat das Objekt ausschließlich die Funktion, eine abkürzende
Aufrufschreibweise zu ermöglichen.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    return bless \(my $dummy),$class;
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden

=head3 href() - Erzeuge URL

=head4 Synopsis

  $url = $this->href($baseUrl,@keyVal);

=head4 Arguments

=over 4

=item $baseUrl

(String) URL bis zum Query-String (ohne Fragezeichen)

=item @keyVal

Liste der Query-String Parameter

=back

=head4 Returns

String

=head4 Description

Erzeuge einen URL der Form C<< $baseUrl?<querystring> >> und liefere diesen
zurück.

=cut

# -----------------------------------------------------------------------------

sub href {
    my ($this,$url) = splice @_,0,2;
    # @_: @keyVal

    my $queryStr = $this->queryEncode(@_);
    if ($queryStr) {
        $url .= "?$queryStr";
    }

    return $url;
}

# -----------------------------------------------------------------------------

=head3 encode() - Kodiere Zeichenkette

=head4 Synopsis

  $encStr = $this->encode($str);
  $encStr = $this->encode($str,$encoding);

=head4 Arguments

=over 4

=item $str

Die Zeichenkette, die kodiert wird.

=item $encoding (Default: 'utf-8')

Das Encoding, in dem die Zeichenkette encodiert werden soll.

=back

=head4 Returns

String

=head4 Description

Kodiere die Zeichenkette $str nach MIME-Type
"application/x-www-form-urlencoded" und liefere die resultierende
Zeichenkette zurück.

In der Zeichenkette werden alle Zeichen außer

  * - . _ + 0-9 A-Z a-z

durch eine Folge von

  %xx

ersetzt, wobei die xx dem Hexadezimalwert des betreffenden
Bytes im Encoding des Zeichens entspricht.

=cut

# -----------------------------------------------------------------------------

sub encode {
    my ($this,$str) = splice @_,0,2;
    my $encoding = shift // 'utf-8';

    if (!defined $str) {
        return '';
    }
    $str = Encode::encode($encoding,$str);
    $str =~ s|([^-*._0-9A-Za-z+])|sprintf('%%%02X',ord $1)|eg;
    # $str =~ s|%20|+|g;

    return $str;
}

# -----------------------------------------------------------------------------

=head3 decode() - Dekodiere Zeichenkette

=head4 Synopsis

  $str = $this->decode($encStr);
  $str = $this->decode($encStr,$encoding);

=head4 Arguments

=over 4

=item $str

Die Zeichenkette, die dekodiert wird.

=item $encoding (Default: 'utf-8')

Das Encoding, in dem die Zeichenkette encodiert ist.

=back

=head4 Returns

String

=head4 Description

Dekodiere die "application/x-www-form-urlencoded" codierte
Zeichenkette $encStr und liefere die resultierende Zeichenkette
zurück.

=cut

# -----------------------------------------------------------------------------

sub decode {
    my ($this,$str) = splice @_,0,2;
    my $encoding = shift // 'utf-8';

    if (!defined $str) {
        return '';
    }

    # $str =~ tr/+/ /;
    $str =~ s/%([\dA-F]{2})/chr hex $1/egi;

    return Encode::decode($encoding,$str);
}

# -----------------------------------------------------------------------------

=head3 queryEncode() - Kodiere Querystring

=head4 Synopsis

  $queryStr = $this->queryEncode(@opt,@keyVal);
  $queryStr = $this->queryEncode($initialChar,@opt,@keyVal);

=head4 Alias

qE()

=head4 Arguments

=over 4

=item @keyVal

Liste der Schlüssel/Wert-Paare, die URL-kodiert werden sollen.

=item $initialChar

Zeichen, das der URL-Kodierten Zeichenkette vorangestellt werden
soll. Dies ist, wenn bentigt, typischweise ein Fragezeichen (?).

=back

=head4 Options

=over 4

=item -encoding => $encoding (Default: 'utf-8')

Das Encoding, in dem die Zeichenkette encodiert werden soll.

=item -null => $bool (Default: 0)

Kodiere auch Schlüssel/Wert-Paare mit leerem Wert (undef oder '').
Per Default werden diese weggelassen.

=item -separator => $char (Default: '&')

Verwende $char als Trennzeichen zwischen den Schlüssel/Wert-Paaren.
Mögliche Werte sind '&' und ';'.

=back

=head4 Returns

String

=head4 Description

Kodiere die Schlüssel/Wert-Paare in @keyVal gemäß MIME-Type
"application/x-www-form-urlencoded" und füge sie zu einem Query String
zusammen.

=head4 Examples

Querystring mit Kaufmanns-Und als Trennzeichen:

  $url = Quiq::Url->queryEncode(a=>1,b=>2,c=>3);
  =>
  a=1&b=2&c=3

Querystring mit Semikolon als Trennzeichen:

  $url = Quiq::Url->queryEncode(-separator=>';',d=>4,e=>5);
  =>
  d=4;e=5

Querystring mit einleitendem Fragezeichen:

  $url = Quiq::Url->queryEncode('?',a=>1,b=>2,c=>3);
  =>
  ?a=1&b=2&c=3

=head4 Details

Als Trennzeichen zwischen den Paaren wird per Default ein
Kaufmanns-Und (&) verwendet:

  key1=val1&key2=val2&...&keyN=valN

Ist der erste Parameter ein Fragezeichen (?), wird dieses dem
Query String vorangestellt:

  ?key1=val1&key2=val2&...&keyN=valN

Das Fragezeichen ist für die URL-Generierung nützlich, das Semikolon
und das Kaufmanns-Und für die Konkatenation von Querystrings.

Ist der Wert eines Schlüssels eine Arrayreferenz, wird für
jedes Arrayelement ein eigenes Schlüssel/Wert-Paar erzeugt:

  a => [1,2,3]

wird zu

  a=1&a=2&a=3

=cut

# -----------------------------------------------------------------------------

sub queryEncode {
    my $this = shift;
    # @_: '?' oder '&' oder ';'

    my $str = '';
    my $initialChar = '';
    # if (length($_[0]) == 1 && $_[0] =~ /[&;?]/) {
    if (@_%2) {
        # Einleitungszeichen
        $initialChar = shift;
    }

    # Direktiven

    my $encoding = 'utf-8',
    my $null = 0;
    my $separator = '&';

    # Query-String generieren

    my $i = 0;
    while (@_) {
        my $key = shift;
        if (substr($key,0,1) eq '-') {
            # Optionen

            if ($key eq '-encoding') {
                $encoding = shift;
                next;
            }
            elsif ($key eq '-null') {
                $null = shift;
                next;
            }
            elsif ($key eq '-separator') {
                $separator = shift;
                next;
            }
        }
        my $val = shift;

        for my $val (ref $val? @$val: $val) {
            if (!$null && (!defined $val or $val eq '')) {
                # leere Werte übergehen
                next;
            }
            if ($i++) {
                $str .= $separator;
            }
            $str .= $this->encode($key,$encoding);
            $str .= '=';
            $str .= $this->encode($val,$encoding);
        }
    }

    return $i? "$initialChar$str": $str;
}

{
    no warnings 'once';
    *qE = \&queryEncode;
}

# -----------------------------------------------------------------------------

=head3 queryDecode() - Dekodiere Querystring

=head4 Synopsis

  @arr | $arr = $this->queryDecode($queryStr);
  @arr | $arr = $this->queryDecode($queryStr,$encoding);

=head4 Arguments

=over 4

=item $queryStr

Querystring, der dekodiert werden soll.

=item $encoding (Default: 'utf-8')

Das Encoding, in dem der Querystring encodiert ist.

=back

=head4 Returns

Liste der dekodierten Schüssel/Wert-Paare. Im Skalarkontext
eine Referenz auf die Liste.

=head4 Description

Dekodiere den Querystring $queryStr und liefere die resultierende
Liste von Schlüssel/Wert-Paaren zurück. Im Skalarkontext liefere
eine Referenz auf die Liste.

Die Schlüssel/Wert-Paare können per & oder ; getrennt sein.

=cut

# -----------------------------------------------------------------------------

sub queryDecode {
    my ($this,$str) = splice @_,0,2;
    my $encoding = shift // 'utf-8';

    my $arr = Quiq::Array->new;
    for (split /[&;]/,$str) {
        next if !$_;
        my ($key,$val) = split /=/;

        $key = $this->decode($key,$encoding);
        $val = $this->decode($val,$encoding);

        push @$arr,$key,$val;
    }

    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 split() - Zerlege URL in seine Bestandteile

=head4 Synopsis

  ($schema,$user,$passw,$host,$port,$path,$query,$fragment,@opt) =
      $this->split($url);

=head4 Options

=over 4

=item -defaultSchema => $schema (Default: undef)

Füge Defaultschema hinzu, falls keins angegeben ist.
Beispiel: -defaultSchema=>'http://'

=item -debug => $bool (Default: 0)

Gib die Zerlegung auf STDOUT aus.

=back

=head4 Description

Zerlege den URL $url in seine Komponenten und liefere diese zurück.
Für eine Komponente, die nicht im URL enthalten ist, wird ein
Leerstring ('') geliefert.

Ein vollständiger URL hat die Form:

  schema://[user[:password]@]host[:port]/[path][?query][#fragment]
  ------    ----  --------   ----  ----   ----   -----   --------
  1         2     3          4     5      6      7       8
  
  1 = Schema (http, ftp, ...)
  2 = Benutzername
  3 = Passwort
  4 = Hostname (kann auch IP-Adresse sein)
  5 = Port
  6 = Pfad (Gesamtpfad, evtl. einschließlich Pathinfo)
  7 = Querystring
  8 = Searchstring (wird nicht an den Server übermittelt)

Die Funktion akzeptiert auch unvollständige HTTP URLs:

  http://host.domain
  
  http://host.domain:port/
  
  http://host.domain:port/this/is/a/path
  
  /this/is/a/path?arg1=val1&arg2=val2&arg3=val3#text
  
  is/a/path?arg1=val1&arg2=val2&arg3=val3
  
  path?arg1=val1&arg2=val2&arg3=val3
  
  ?arg1=val1&arg2=val2&arg3=val3

Der Querystring ist alles nach '?' und ggf. bis '#', falls angegeben.
Der konkrete Aufbau des Querystring, wie Trennzeichen usw., spielt
keine Rolle.

=cut

# -----------------------------------------------------------------------------

sub split {
    my $this = shift;
    my $url = shift;
    # @_: @opt

    # Optionen

    my $debug = 0;
    my $defaultSchema = undef;

    if (@_) {
        Quiq::Option->extract(\@_,
            -defaultSchema => \$defaultSchema,
            -debug => \$debug,
        );
    }

    # Code

    my ($schema,$user,$passw,$host,$port,$path,$query,$frag) = ('') x 8;

    if ($defaultSchema && $url !~ m|^(.+)://|) {
        # Wir fügen Defaultschema hinzu, wenn keins angegeben ist
        $url = "$defaultSchema$url";
    }
    if ($url =~ s|^(.+)://([^/?#]+)||) {
        # protocol://user:passw@host:port
        $schema = $1;
        my ($part1,$part2) = split /@/,$2;
        ($user,$passw) = split /:/,$part1 if $part2;
        $passw = '' if !defined $passw;
        ($host,$port) = split /:/,$part2? $part2: $part1;
        $port = '' if !defined $port;
    }
    if ($url =~ s|#([^#]*)$||) {
        # Searchstring nach #
        $frag = $1;
    }
    if ($url =~ s|\?([^?]*)$||) {
        # Querystring nach ?
        $query = $1;
    }

    $path = $url; # Rest ist Pfad

    if ($debug) {
        print "schema=$schema\n";
        print "user=$user\n";
        print "password=$passw=\n";
        print "host=$host\n";
        print "port=$port\n";
        print "path=$path\n";
        print "query=$query\n";
        print "frag=$frag\n";
    }

    return ($schema,$user,$passw,$host,$port,$path,$query,$frag);
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
