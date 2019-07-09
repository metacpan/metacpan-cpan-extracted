package Quiq::Url;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use Quiq::Array;
use Quiq::Option;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Url - URL Klasse

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Klassenmethoden

=head3 encode() - Kodiere Zeichenkette

=head4 Synopsis

    $encStr = $class->encode($str);

=head4 Description

Kodiere die Zeichenkette $str nach MIME-Type
"application/x-www-form-urlencoded" und liefere die resultierende
Zeichenkette zurück.

In der Zeichenkette werden alle Zeichen außer

    * - . _ 0-9 A-Z a-z

durch

    %xx

ersetzt, wobei xx dem Hexadezimalwert des Zeichens entspricht.

=cut

# -----------------------------------------------------------------------------

sub encode {
    my ($class,$str) = @_;

    # FIXME: byte-orientiert encoden! D.h. utf8 geflaggte Strings
    # werden als mehrere Bytes kodiert.

    return '' unless defined $str;
    $str =~ s|([^-*._0-9A-Za-z])|sprintf('%%%02X',ord $1)|eg;
    # $str =~ s|%20|+|g;

    return $str;
}

# -----------------------------------------------------------------------------

=head3 decode() - Dekodiere Zeichenkette

=head4 Synopsis

    $str = $class->decode($encStr);

=head4 Description

Dekodiere die "application/x-www-form-urlencoded" codierte
Zeichenkette $encStr und liefere die resultierende Zeichenkette
zurück.

=cut

# -----------------------------------------------------------------------------

sub decode {
    my ($class,$str) = @_;

    # FIXME: byte-orientiert decoden und nach UTF-8 wandeln, wenn
    # nichts anderes gewüncht ist.

    return '' unless defined $str;
    # $str =~ tr/+/ /;
    $str =~ s/%([\dA-F]{2})/chr hex $1/egi;

    return $str;
}

# -----------------------------------------------------------------------------

=head3 queryEncode() - Kodiere URL-Querystring

=head4 Synopsis

    $queryStr = $class->queryEncode(@opt,@keyVal);
    $queryStr = $class->queryEncode($initialChar,@opt,@keyVal);

=head4 Options

=over 4

=item -null => $bool (Default: 0)

Kodiere auch Schlüssel/Wert-Paare mit leerem Wert (undef oder '').
Per Default werden diese weggelassen.

=item -separator => $char (Default: ';')

Verwende $char als Trennzeichen zwischen den Schlüssel/Wert-Paaren.
Mögliche Werte sind ';' und '&'.

=back

=head4 Description

Kodiere die Schlüssel/Wert-Paare in @keyVal gemäß MIME-Type
"application/x-www-form-urlencoded" und füge sie zu einem Query String
zusammen.

=head4 Examples

Querystring mit Semikolon als Trennzeichen:

    $str = Quiq::Url->queryEncode(a=>1,b=>2,c=>3);
    =>
    a=1;b=2;c=3

Querystring mit Kaufmannsund als Trennzeichen:

    $url .= Quiq::Url->queryEncode(-separator=>'&',d=>4,e=>5);
    =>
    ?a=1&b=2&c=3&d=4,e=5

Querystring mit einleitendem Fragezeichen:

    $url = Quiq::Url->queryEncode('?',a=>1,b=>2,c=>3);
    =>
    ?a=1;b=2;c=3

=head4 Details

Als Trennzeichen zwischen den Paaren wird per Default ein
Semikolon (;) verwendet:

    key1=val1;key2=val2;...;keyN=valN

Ist der erste Parameter ein Fragezeichen (?), Semikolon (;) oder
Kaufmannsund (&), wird dieses dem Query String vorangestellt:

    ?key1=val1;key2=val2;...;keyN=valN

Das Fragezeichen ist für die URL-Generierung nützlich, das Semikolon
und das Kaufmannsund für die Konkatenation von Querystrings.

Ist der Wert eines Schlüssels eine Arrayreferenz, wird für
jedes Arrayelement ein eigenes Schlüssel/Wert-Paar erzeugt:

    a => [1,2,3]

wird zu

    a=1;a=2;a=3

=cut

# -----------------------------------------------------------------------------

sub queryEncode {
    my $class = shift;
    # @_: '?' oder '&' oder ';'

    my $str = '';
    # if (length($_[0]) == 1 && $_[0] =~ /[&;?]/) {
    if (@_%2) {
        # Einleitungszeichen
        $str = shift;
    }

    # Direktiven

    my $null = 0;
    my $separator = ';';

    # Query-String generieren

    my $i = 0;
    while (@_) {
        my $key = shift;
        if (substr($key,0,1) eq '-') {
            # Optionen

            if ($key eq '-null') {
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
            $str .= $class->encode($key);
            $str .= '=';
            $str .= $class->encode($val);
        }
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head3 queryDecode() - Dekodiere URL-Querystring

=head4 Synopsis

    @arr | $arr = $class->queryDecode($queryStr);

=head4 Description

Dekodiere den Querystring $queryStr und liefere die resultierende
Liste von Schlüssel/Wert-Paaren zurück. Im Skalarkontext liefere
eine Referenz auf die Liste.

Die Schlüssel/Wert-Paare können per & oder ; getrennt sein.

=cut

# -----------------------------------------------------------------------------

sub queryDecode {
    my $class = shift;
    my $str = shift;

    my $arr = Quiq::Array->new;
    for (split /[&;]/,$str) {
        next if !$_;
        my ($key,$val) = split /=/;

        $key = $class->decode($key);
        $val = $class->decode($val);
        # $val =~ s/&quot;/"/g; # &quot;-Rueckwandlung

        push @$arr,$key,$val;
    }

    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 split() - Zerlege URL in seine Bestandteile

=head4 Synopsis

    ($schema,$user,$passw,$host,$port,$path,$query,$fragment,@opt) =
        $class->split($url);

=head4 Options

=over 4

=item -defaultSchema => $schema (Default: undef)

Füge Defaultschema hinzu, wenn keins angegeben ist.
Beispiel: -defaultSchema=>'http://'

=item -debug => $bool (Default: 0)

Gib die Zerlegung auf STDOUT aus.

=back

=head4 Description

Zerlege den URL $url in seine Komponenten und liefere diese zurück.
Für eine Komponente, die nicht im URL enthalten ist, wird ein
Leerstring ('') geliefert.

Ein vollständiger URL hat die Form:

    schema://[user[:passw]@]host[:port]/[path][?query][#fragment]
    ------    ----  -----   ----  ----   ----   -----   --------
       1       2      3      4     5      6       7        8
    
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

Der Querystring ist alles zwischen '?' und '#', der konkrete Aufbau,
wie Trennzeichen usw., spielt keine Rolle.

=cut

# -----------------------------------------------------------------------------

sub split {
    my $class = shift;
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
