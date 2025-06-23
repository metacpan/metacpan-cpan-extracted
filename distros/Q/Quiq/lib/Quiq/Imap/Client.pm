# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Imap::Client - IMAP Client

=head1 BASE CLASSES

=over 2

=item *

Net::IMAP::Simple

=item *

L<Quiq::Object>

=back

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen IMAP-Client.

Die Klasse realisiert ihre Funktionalität unter Rückgriff auf
L<Net::IMAP::Simple|https://metacpan.org/pod/Net::IMAP::Simple> durch Ableitung.
Detaillierte Dokumentation siehe dort.

Die Klasse zeichnet sich gegenüber ihrer Basisklasse dadurch aus, dass

=over 2

=item *

sie Fehler nicht über Returnwerte anzeigt, sondern im Fehlerfall
eine Exception wirft

=item *

die Methode get() die Mail als vollständigen Text liefert

=back

Der Mail-Text kann zur Instantiierung eines Objekts zur weiteren
Verarbeitung genutzt werden kann (z.B. via Email::Simple, Email::MIME
oder MIME::Parser)

=cut

# -----------------------------------------------------------------------------

package Quiq::Imap::Client;
use base qw/Net::IMAP::Simple Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $imap = $class->new($host,%opt);

=head4 Arguments

=over 4

=item $host

(String) IMAP-Host, ggf. mit Port

=item %opt

Optionale Angaben als Schlüssel/Wert-Paare

=back

=head4 Returns

Object

=head4 Description

Instantiiere eine Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=head4 Example

  my $imap = Quiq::Imap::Client->new('imap.example.com');

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$host) = splice @_,0,2;
    # @_: %opt

    my $self = $class->SUPER::new($host,@_);
    if (!$self) {
        $class->throw(
            'IMAP-00099: Object instatiation failed',
            Message => $Net::IMAP::Simple::errstr,
        );
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 login() - Führe Authentisierung gegenüber Server durch

=head4 Synopsis

  $imap->login($user,$password);

=head4 Arguments

=over 4

=item $user

(String) Name des Benutzers

=item $password

(String) Passwort des Benutzers

=back

=head4 Description

Führe eine Authetisierung gegenüber dem Server durch.

=head4 Example

  $imap->login('kallisto','geheim');

=cut

# -----------------------------------------------------------------------------

sub login {
    my ($self,$user,$password) = @_;

    my $bool = $self->SUPER::login($user,$password);
    if (!$bool) {
        $self->throw(
            'IMAP-00099: Authentication failed',
            User => $user,
            Message => $self->errstr,
        );
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head3 select() - Wähle Verzeichnis

=head4 Synopsis

  $n = $imap->select($folder);

=head4 Arguments

=over 4

=item $folder

(String) Name des Verzeichnisses

=back

=head4 Returns

(Integer) Anzahl der Mails im Verzeichnis

=head4 Description

Wähle Verzeichnis $folder aus und liefere die Anzahl der darin enthaltenen
Mails zurück.

=head4 Example

  $n = $imap->select('INBOX');

=cut

# -----------------------------------------------------------------------------

sub select {
    my ($self,$folder) = @_;

    my $n = $self->SUPER::select($folder);
    if (!defined $n) {
        $self->throw(
            'IMAP-00099: Selection of folder failed',
            Folder => $folder,
            Message => $self->errstr,
        );
    }
    
    return $n;
}

# -----------------------------------------------------------------------------

=head3 search() - Suche Mails

=head4 Synopsis

  @arr = $imap->search($query);

=head4 Arguments

=over 4

=item $query

(String) Anfrage-Zeichenkette (Details s. Originaldoku)

=back

=head4 Returns

(Array) Liste der Mail-Nummern

=head4 Description

Suche alle Mails im ausgewählten Verzeichnis (s. $imap->select())
und liefere die Liste der Mail-Nummern zurück.

=head4 Example

  @arr = $imap->search('FROM "john@example.com"');

=cut

# -----------------------------------------------------------------------------

# Implementierung in der Basisklasse

# -----------------------------------------------------------------------------

=head3 get() - Liefere Mail als Text

=head4 Synopsis

  $message = $imap->get($i);

=head4 Arguments

=over 4

=item $i

(Integer) Mail-Nummer innerhalb des Verzeichnisses

=back

=head4 Returns

(String) Mail als Zeichenkette

=head4 Description

Hole die Mail mit der Nummer $i aus dem gewählten IMAP-Verzeichnis
und liefere sie als Zeichnkette zurück.

=cut

# -----------------------------------------------------------------------------

sub get {
    my ($self,$i) = @_;

    my $message = $self->SUPER::get($i);
    if (!defined $message) {
        $self->throw(
            'IMAP-00099: Can\'t fetch message',
            Numer => $i,
            Message => $self->errstr,
        );
    }

    return "$message";
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
