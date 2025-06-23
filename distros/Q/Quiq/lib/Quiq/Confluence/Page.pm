# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Confluence::Page - Confluence-Wiki Seite

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse kapselt den Body der HTTP Antwort einer
getPage()-Operation des Confluence-Client (Klasse
Quiq::Confluence::Client). Mit den Methoden der Klasse kann
auf die Information in der Antwort zugegriffen werden.

=cut

# -----------------------------------------------------------------------------

package Quiq::Confluence::Page;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use JSON ();
use Quiq::Debug;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $pag = $class->new($json);

=head4 Arguments

=over 4

=item $json

Body der HTTP-Antwort der getPage()-Operation. Der Body enthält
die JSON-Repräsentation der Seite.

=back

=head4 Returns

Page-Objekt (Klasse Quiq::Confluence::Page)

=head4 Description

Instantiiere ein Confluence Seiten-Objekt und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$json) = @_;

    return $class->SUPER::new(
        perl => $json? JSON::decode_json($json) : undef,
    );
}

# -----------------------------------------------------------------------------

=head2 Hash-Zugriff

=head3 hash() - Hash der JSON-Struktur

=head4 Synopsis

  $h = $pag->hash;

=head4 Returns

Space (String)

=head4 Description

Liefere eine Referenz auf den Hash, der der JSON-Struktur der
Seite entspricht.

=cut

# -----------------------------------------------------------------------------

sub hash {
    return shift->{'perl'};
}

# -----------------------------------------------------------------------------

=head2 Akzessoren

=head3 id() - Id der Seite

=head4 Synopsis

  $id = $pag->id;

=head4 Returns

Space (integer)

=head4 Description

Liefere die Id der Seite.

=cut

# -----------------------------------------------------------------------------

sub id {
    my $self = shift;
    return $self->{'perl'}->{'id'} || $self->throw;
}

# -----------------------------------------------------------------------------

=head3 space() - Name des Space, in dem die Seite liegt

=head4 Synopsis

  $space = $pag->space;

=head4 Returns

Space (String)

=head4 Description

Liefere den Namen des Space, in dem die Seite liegt.

=cut

# -----------------------------------------------------------------------------

sub space {
    my $self = shift;
    return $self->{'perl'}->{'space'}->{'key'} || $self->throw;
}

# -----------------------------------------------------------------------------

=head3 title() - Titel der Seite

=head4 Synopsis

  $title = $pag->title;

=head4 Returns

Seitentitel (String)

=head4 Description

Liefere den Titel der Seite. Der Seitentitel ist unabhängig
vom Seiteninhalt.

=cut

# -----------------------------------------------------------------------------

sub title {
    my $self = shift;
    return $self->{'perl'}->{'title'} || $self->throw;
}

# -----------------------------------------------------------------------------

=head3 version() - Version der Seite

=head4 Synopsis

  $n = $pag->version;

=head4 Returns

Versionsnummer (Integer)

=head4 Description

Liefere die Version der Seite. Dies ist eine ganze Zahl > 0.

=cut

# -----------------------------------------------------------------------------

sub version {
    my $self = shift;
    return $self->{'perl'}->{'version'}->{'number'} || $self->throw;
}

# -----------------------------------------------------------------------------

=head2 Debugging

=head3 asString() - Perl-Repräsentation als Zeichenkette

=head4 Synopsis

  $str = $pag->asString;

=head4 Returns

Perl-Datenstruktur (als Text)

=head4 Description

Der Konstruktor der Klasse wandelt die JSON-Darstellung der Seite
in eine analoge Perl-Datenstruktur. Diese Methode liefert die
Zeichenketten-Repäsentation dieser Perl-Datenstruktur.

=cut

# -----------------------------------------------------------------------------

sub asString {
    my $self = shift;
    return Quiq::Debug->dump($self->{'perl'});
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
