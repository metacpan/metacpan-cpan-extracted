package Quiq::SoapWsdlServiceCgi;
use base qw/Quiq::Object/;
push our @ISA,qw/SOAP::Server::Parameters/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Pod::WSDL ();
use SOAP::Transport::HTTP ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::SoapWsdlServiceCgi - Basisklasse für SOAP Web Services via CGI

=head1 BASE CLASSES

=over 2

=item *

L<Quiq::Object>

=item *

SOAP::Server::Parameters

=back

=head1 DESCRIPTION

Die Klasse stellt die Grundfunktionalität eines SOAP Web Service
mit WSDL zur Verfügung. Ein konkreter Service wird realisiert,
indem eine Klasse mit der Implementierung konkreter
Service-Methoden von dieser Basisklasse abgeleitet wird.

Der Web Service wird angesprochen (SOAP-Call oder Abruf der
WSDL-Spezifikation), wenn die Klassenmethode $class->run() über
die abgeleitete Klasse aus einem CGI-Programm heraus aufgerufen
wird.

=head2 Web Service implementieren

Vorgehen bei der Realisierung eines konkreten Web Service:

=over 4

=item 1.

Abgeleitete Klasse mit den Methoden des Web Service implementieren

    package MyWebServiceClass;
    use base qw/Quiq::SoapWsdlServiceCgi/;
    
    =begin WSDL
    
    <Pod::WSDL-Spezifikation für Methode myWebServiceMethod1()>
    
    =end WSDL
    
    =cut
    
    sub myWebServiceMethod1 {
        my ($class,<Parameter der Methode>,$som) = @_;
    
        <Implementierung der Methode>
    
        return <Return Wert>;
    }
    
    <weitere Methoden>
    
    # eof

Die Signatur der Methoden (Parameter und Returnwerte) muss in
einem POD-Abschnitt (C<=begin WSDL ... =end WSDL>) gemäß den
Konventionen von Pod::WSDL vorgenommen werden (Beschreibung
siehe dort).

Die Klasse Quiq::SoapWsdlServiceCgi ist von SOAP::Server::Parameters abgeleitet.
Daher wird der Parameterliste der Methoden der deserialisierte
Client-Request in Form eines SOAP::SOM-Objekts hinzugefügt. In den
Methoden kann also auf sämtliche Request-Information zugegriffen
werden, z.B. Header-Information, die für eine Authentisierung
benötigt wird.

=item 2.

CGI-Programm my-webservice implementieren, das den Web Service
ausführt:

    #!/usr/bin/env perl
    
    use MyWebServiceClass;
    
    MyWebServiceClass->run;
    
    # eof

Der Webservice kann unter einem beliebigen URI installiert
werden. Wird der URI vom Client mit angehägtem "?wsdl"
aufgerufen, liefert der Web Service seine
WSDL-Spezifikation. Alle anderen Aufrufe behandelt der Service
als SOAP-Request.

=back

=head2 Web Service unter mod_perl ausführen

Der Web Service (my-webservice, MyWebServiceClass.pm) kann ohne
Änderung auch unter mod_perl ausgeführt werden. Dadurch wird der
serverseitige Overhead je Methodenaufruf deutlich reduziert. Bei
einem Test über das Internet

    Client <--Internet--> Server

ergab sich eine Beschleunigung um Faktor 3 (0.06s statt 0.2s
Sekunden für einen Methodenaufruf ohne Parameter, ohne Code und
ohne Returnwert).

Getestetes Setup (Apache2, ModPerl2) auf Ebene eines VirtualHost:

    <VirtualHost ...>
      ...
      PerlResponseHandler ModPerl::Registry
      PerlOptions +ParseHeaders +Parent
      PerlSwitches -ILIBRARY_PATH
      RewriteEngine on
      RewriteRule ^/URI$ PROGRAM_PATH/my-webservice [H=perl-script]
    </VirtualHost>

Hierbei ist:

=over 4

=item LIBRARY_PATH

Pfad des Verzeichnisses mit der WebService-Klasse (MyWebServiceClass).

=item URI

URI des Web Service.

=item PROGRAM_PATH

Pfad des Verzeichnisses mit dem WebService-Programm (my-webservice).

=back

Sollte der Service nicht ansprechbar sein, kann dem im Apache
error.log auf den Grund gegangen werden.

=head2 An der Kommandozeile testen

Die WSDL-Generierung durch die WebService-Klasse kann an der
Kommandozeile getestet werden:

    $ SCRIPT_URI=http://x QUERY_STRING=wsdl perl -MMyWebServiceClass
        -e 'MyWebServiceClass->run'

Der gleiche Test über das CGI-Programm, das die WebService-Klasse ruft:

    $ SCRIPT_URI=http://x QUERY_STRING=wsdl perl ./mywebservice.cgi

=head1 METHODS

=head2 Klassenmethoden

=head3 run() - Führe Aufruf aus

=head4 Synopsis

    $class->run;

=head4 Description

Führe einen Aufruf über Klasse $class aus und liefere
die Antwort an den Client. Der Aufruf ist entweder eine Abfrage der
WSDL-Spezifikation des Service (URI?wsdl) oder ein SOAP-Aufruf.

Die Methode liefert keinen Wert zurück.

=cut

# -----------------------------------------------------------------------------

sub run {
    my $class = shift;

    if ($ENV{'QUERY_STRING'} && $ENV{'QUERY_STRING'} eq 'wsdl') {
        # Generiere WSDL-Spezifikation und schreibe sie nach STDOUT

        my $wsdl = Pod::WSDL->new(
            source => $class, 
            location => $ENV{'SCRIPT_URI'} ||
                "$ENV{'REQUEST_SCHEME'}://$ENV{'SERVER_NAME'}".
                "$ENV{'REQUEST_URI'}",
            pretty => 1,
            withDocumentation => 0,
        );
        print "Content-Type: text/xml\n\n",$wsdl->WSDL;
    }
    else {
        # Führe SOAP-Request aus
        SOAP::Transport::HTTP::CGI->dispatch_to($class)->handle;
    }
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
