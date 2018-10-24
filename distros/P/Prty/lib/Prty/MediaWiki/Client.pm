package Prty::MediaWiki::Client;
use base qw/Prty::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.125;

use LWP::UserAgent ();
use Prty::MediaWiki::Page;
use Prty::Url;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::MediaWiki::Client - MediaWiki Client

=head1 BASE CLASS

L<Prty::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Client, der mit einem
MediaWiki-Server kommunizieren kann.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere MediaWiki-Client

=head4 Synopsis

    $cli = $class->new(@keyVal);

=head4 Arguments

=over 4

=item url => $url (Default: nichts)

Basis-URL ("Endpoint") des MediaWiki, z.B.
"https://en.wikipedia.org/w/api.php".

=item verbose => $bool (Default: 0)

Gib Laufzeit-Informationen auf STDERR aus.

=back

=head4 Returns

Client-Objekt

=head4 Description

Instantiiere einen Client für ein MediaWiki mit den Eigenschaften
@keyval und liefere eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        url => undef,
        verbose => 0,
        ua => LWP::UserAgent->new,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head3 getPage() - Liefere Seite

=head4 Synopsis

    $pag = $cli->getPage($title);

=head4 Arguments

=over 4

=item $title

Seiten-Titel

=back

=head4 Returns

Seiten-Objekt (Typ Prty::MediaWiki::Page)

=head4 Description

Rufe die Seite mit dem Titel $title ab und liefere ein
Seiten-Objekt vom Typ Prty::MediaWiki::Page zurück.

=cut

# -----------------------------------------------------------------------------

sub getPage {
    my ($self,$title) = @_;

    my $res = $self->send('GET',
        action => 'query',
        titles => $title,
        prop => 'revisions',
        rvprop => 'content',
        format => 'json',
    );
    my $pag = Prty::MediaWiki::Page->new($res->content);
    if ($self->verbose) {
        warn sprintf "---RESULT---\n%s\n",$pag->asString;
    }

    return $pag;
}

# -----------------------------------------------------------------------------

=head2 Hilfsmethoden

Die folgenden Methoden bilden die Grundlage für die Kommunikation
mit dem MediaWiki-Server. Sie werden normalerweise nicht direkt
gerufen.

=head3 send() - Sende HTTP-Request

=head4 Synopsis

    $res = $cli->send($method,@query);

=head4 Arguments

=over 4

=item $method

Die HTTP-Methode, z.B. 'GET'.

=item @query

Die Query-Parameter des Requests als Liste von
Schlüssel/Wert-Paaren.

=back

=head4 Returns

HTTP-Antwort (Typ HTTP::Response)

=head4 Description

Sende einen HTTP-Request vom Typ $method mit den Query-Parametern
@query an den MediaWiki-Server und liefere die resultierende
HTTP-Anwort zurück. Im Fehlerfall wird eine Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub send {
    my $self = shift;
    my $method = shift;
    # @_: @query

    my ($ua,$verbose) = $self->get(qw/ua verbose/);

    my $query = Prty::Url->queryEncode(
        -separator => '&',
        @_,
    );

    my $req = HTTP::Request->new(
        $method => $self->url."?$query",
    );

    if ($verbose) {
        warn sprintf "---REQUEST---\n%s",$req->as_string;
    }

    my $res = $ua->request($req);
    if (!$res->is_success) {
        $self->throw(
            q~CLIENT-00001: HTTP request failed~,
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

=head1 VERSION

1.125

=head1 SEE ALSO

=over 2

=item *

L<https://www.mediawiki.org/wiki/API:Main_page>

=back

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2018 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
