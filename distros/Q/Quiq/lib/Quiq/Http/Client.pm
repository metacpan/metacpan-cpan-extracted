package Quiq::Http::Client;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use Quiq::Option;
use Quiq::Url;
use Quiq::Socket;
use Quiq::Http::Message;
use Time::HiRes ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Http::Client - HTTP-Client

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Die Klasse implementiert einen HTTP-Client für GET- und POST-Requests.

Die zentrale Methode ist $class->L<sendReceive|"sendReceive() - Führe HTTP-Request aus">(). Diese sendet eine
HTTP-Request-Message, die der Aufrufer konfiguriert hat, an einen
Server (URL), und gibt die HTTP-Response-Message des Servers zurück.
Die Methode beherrscht GET- und POSTS-Requests. Auf ihrer Basis
sind die spezielleren Methoden $class->L<get|"get() - Führe GET-Request aus">() und $class->L<post|"post() - Führe POST-Request aus">()
implementiert. Die HTTP-Messages, sowohl gesendete als auch empfangene,
sind Instanzen der Klasse Quiq::HTTP::Message.

=head1 EXAMPLE

=head2 Universeller Client

Siehe quiq-http-client

=head2 GET-Request

    my $msg = Quiq::Http::Client->get($url);
    print $msg->asString;

=head2 POST-Request

    my $sMsg = Quiq::Http::Message->new(
        contentType => 'text/plain',
        contentLength => -1,
        body => 'Dies ist ein Test',
    );
    my $rMsg = Quiq::Http::Client->put($url,$sMsg);
    print $rMsg->asString;

=head1 METHODS

=head2 Klassenmethoden

=head3 sendReceive() - Führe HTTP-Request aus

=head4 Synopsis

    $rMsg = $class->sendReceive($op,$url,$sMsg,@opt);

=head4 Arguments

=over 4

=item $op

Die HTTP-Operation: 'post' oder 'get'.

=item $url

Der URL, gegen den die Operation ausgeführt wird.

=item $sMsg

Die HTTP-Nachricht, die gesendet wird. Dies ist eine Instanz der Klasse
Quiq::Http::Message.

=back

=head4 Options

=over 4

=item -debug => $bool (Default: 0)

Gib die kommunizierten Daten (Request, Response) und Metainformation
(Zeitmessung) auf STDOUT aus.

=item -redirect => $bool (Default: 1)

Führe Redirects automatisch aus.

=back

=head4 Description

Führe HTTP Request vom Typ $op gegen URL $url mit HTTP-Nachricht $sMsg aus
und liefere die vom Server gelieferte Antwort $rMsg zurück.

=cut

# -----------------------------------------------------------------------------

sub sendReceive {
    my $class = shift;
    my $op = shift;
    my $url = shift;
    my $sMsg = shift;
    # @_: @opt

    # Optionen

    my $debug = 0;
    my $redirect = 1;

    if (@_) {
        Quiq::Option->extract([@_],
            -debug => \$debug,
            -redirect => \$redirect,
        );
    }

    # Zerlege URL

    my ($schema,$user,$passw,$host,$port,$path,$query,$fragment) =
        Quiq::Url->split($url,-defaultSchema=>'http://');
    $port ||= 80;
    $path ||= '/';

    # Ermittele Host und Resource

    my $resource = $path;
    if ($query ne '') {
        $resource .= "?$query";
    }

    my $hostPort = $host;
    if ($port ne '80') {
        $hostPort .= ":$port";
    }

    # Setze HTTP/1.1 Pflich-Header Host:, UserAgent:

    my $ua = 
    $sMsg->set(
        host => $hostPort,
        userAgent => 'Perl HTTP Client',
        connection => 'close',
    );

    if ($user) {
        $sMsg->set(authorization=>"$user:$passw");
    }

    # Erzeuge Request

    my $request = sprintf "%s %s HTTP/1.1\n%s",uc($op),$resource,
        $sMsg->asString;

    my $t0;
    my $w = 79;
    if ($debug) {
        printf "%s\n$request%s\n",'='x$w,'-'x$w;
        $t0 = Time::HiRes::gettimeofday;
    }

    # Baue Verbindung auf
    my $sock = Quiq::Socket->new($host,$port);

    # Sende Request
    print $sock $request;

    # Lies die Response
    my $str = $sock->slurp;

    # Schließe Verbindung
    $sock->close;

    if ($debug) {
        printf "%s%s\n%.3f sec\n",$str,'~'x$w,
            Time::HiRes::gettimeofday-$t0;
    }

    # Instantiiere das Message-Objekt der Response
    my $msg = Quiq::Http::Message->new(received=>1,\$str);

    # Führe Redirect aus

    if ($redirect && $msg->status =~ /^30[123]$/) {
        return $class->sendReceive($op,$msg->location,$sMsg,@_);
    }

    if ($debug) {
        printf "%s\n",'#'x$w;
    }

    return $msg;
}

# -----------------------------------------------------------------------------

=head3 get() - Führe GET-Request aus

=head4 Synopsis

    $msg = $class->get($url,@opt);

=head4 Arguments

=over 4

=item $url

Der URL, gegen den der GET-Request ausgeführt wird.

=item $sMsg

Die HTTP-Nachricht, die gesendet wird. Dies ist eine Instanz der Klasse
Quiq::Http::Message.

=back

=head4 Options

Siehe Methode L<sendReceive|"sendReceive() - Führe HTTP-Request aus">().

=head4 Description

Führe HTTP POST-Request mit URL $url aus und liefere die vom Server
gelieferte Antwort zurück.

=cut

# -----------------------------------------------------------------------------

sub get {
    my $class = shift;
    my $url = shift;
    # @_: @opt

    # Bei einem GET-Request hat HTTP Request-Message
    # keinen besonderen Inhalt.

    my $msg = Quiq::Http::Message->new;
    return $class->sendReceive('get',$url,$msg,@_);
}

# -----------------------------------------------------------------------------

=head3 post() - Führe POST-Request aus

=head4 Synopsis

    $rMsg = $class->post($url,$sMsg,@opt);

=head4 Arguments

=over 4

=item $url

Der URL, gegen den der GET-Request ausgeführt wird.

=back

=head4 Options

Siehe Methode L<sendReceive|"sendReceive() - Führe HTTP-Request aus">().

=head4 Description

Führe HTTP POST-Request gegen URL $url und mit HTTP-Nachricht $sMsg aus
und liefere die vom Server gelieferte Antwort zurück.

=cut

# -----------------------------------------------------------------------------

sub post {
    my $class = shift;
    my $url = shift;
    my $msg = shift;
    # @_: @opt

    return $class->sendReceive('post',$url,$msg,@_);
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
