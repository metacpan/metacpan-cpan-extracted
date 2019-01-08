package Prty::MediaWiki::Loader;
use base qw/Prty::MediaWiki::Api/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.128;

use Prty::Config;
use Prty::Path;
use Prty::Hash;
use Prty::Record;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::MediaWiki::Loader - MediaWiki Seiten-Lader

=head1 BASE CLASS

L<Prty::MediaWiki::Api>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen MediaWiki Seiten-Lader,
der Seiten im Dateisystem hält und diese ins Wiki spiegelt. Dies ist
ein spezieller Client. Die allgemeine MediaWiki Client-Schnittstelle
wird von der Klasse Prty::MediaWiki::Api implementiert.

=head1 FILES

=over 4

=item ~/etc/mediawiki/<WIKI_NAME>/client.conf

Enthält den URL des Wiki-API des MediaWiki <WIKI_NAME> und (optional)
Name und Passwort des Nutzers für das Login. Inhalt:

    url => 'http://lxv0103.ruv.de:8080/api.php',
    user => 'XV882JS',
    password => 'geheim',

Enthält die Datei Benutzername und Passwort, darf sie nur für den
Benutzer selbst lesbar und schreibbar sein. Der Konstruktor prüft
dies und wirft bei Verletzung eine Exception.

=item ~/var/mediawiki/<WIKI_NAME>/*.mw

Cache mit den MediaWiki-Seiten (*.mw). Eine MediaWiki-Seite wird nur
aktualisiert, wenn die externe Datei von der Cache-Datei verschieden
ist. Die Zuordnung von Externe Datei zu Cache-Datei erfolgt über den
Grundnamen. Dieser muss also eindeutig sein.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere MediaWiki Seiten-Lader

=head4 Synopsis

    $mwl = $class->new($name,@opt);

=head4 Arguments

=over 4

=item $name

Name des Wiki, z.B. 'ruv'.

=back

=head4 Options

=over 4

=item -color => $bool (Default: 0)

Gib die Laufzeitinformation (wenn -debug => 1) in Farbe aus.

=item -debug => $bool (Default: 0)

Gib Laufzeit-Information wie den Kommunikationsverlauf auf STDERR aus.

=back

=head4 Returns

Loader-Objekt

=head4 Description

Instantiiere Seiten-Lader für MediaWiki $name und liefere eine
Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$name) = splice @_,0,2;
    # @_: @opt

    # Konfigurationsdatei
    my $configFile = "~/etc/mediawiki/$name/client.conf";

    # Konfiguration lesen
    my $conf = Prty::Config->new($configFile);

    # Einloggen (optional)

    if ($conf->user && $conf->password) {
        # Wenn die Konfigurationsdatei Benutzername und Passwort enthält,
        # prüfen wir, ob die Datei gegen fremdes Lessen geschützt ist

        my $mode = Prty::Path->mode($configFile);
        if ($mode & 00066) {
            $class->throw(
                q~MEDIAWIKI-00099: File is readable or writable for others~,
                File => $configFile,
            );
        }

        # Benutzername und Passwort zu den Konstruktorparametern hinzufügen
        unshift @_,$conf->user,$conf->password;
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new($conf->url,@_);
    $self->add(
        name => $name,
    );

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Seite laden

=head3 loadPage() - Lade Seite ins Wiki

=head4 Synopsis

    $mwl->loadPage($name,$input);

=head4 Arguments

=over 4

=item $name

Eindeutiger Name der Wiki-Seite. Dieser Name identifiziert die Seite
im Cache.

=item $input

Pfad der MediaWiki Seitendatei oder eine Stringreferenz auf den
Inhalt der Seitendatei.

=back

=cut

# -----------------------------------------------------------------------------

sub loadPage {
    my ($self,$name,$input) = @_;

    # Pfad-Objekt für diverse Pfad-Operationen instantiieren
    my $p = Prty::Path->new;

    # PageCode lesen

    my $pageCode = ref $input? $$input: $p->read($input,-decode=>'utf-8');

    my $recNew = Prty::Hash->new(Prty::Record->fromString($pageCode));
    my ($titleNew,$contentNew) = $recNew->get('Title','Content');

    # Id, Titel, Content der Cache-Datei bestimmen. Wenn die Cache-Datei
    # nicht existiert, versuchen wir, die Seite über den Titel im
    # Wiki zu finden. Wenn dies nicht gelingt, legen wir die Seite
    # mit leerer Information im cache an. Dann ist die Seite neu.

    my $varFile = sprintf '~/var/mediawiki/%s/%s.mw',$self->name,$name;
    if (!$p->exists($varFile)) {
        my $pageId = '';
        my $title = '';
        my $content = '';

        if (my $pag = $self->getPage($titleNew,-sloppy=>1)) {
            $pageId = $pag->{'pageid'};
            $title = $pag->{'title'};
            $content = $pag->{'*'};
        }

        my $data = Prty::Record->toString(
            Id => $pageId,
            Title => $title,
            Content => $content,
        );
        $p->write($varFile,$data,
            -recursive => 1,
            -encode => 'UTF-8',
        );
    }

    # Wir lesen den letzten Stand der Seite aus dem Cache

    my $recOld = Prty::Hash->new(Prty::Record->fromFile(
        $varFile,-encoding=>'UTF-8'));
    my ($pageId,$titleOld,$contentOld) = $recOld->get('Id','Title','Content');

    # Entscheiden, welche Operation(en) auf dem Wiki auszuführen sind

    if ($titleNew eq $titleOld && $contentNew eq $contentOld) {
        # Keine Änderung, nichts zu tun
        return;
    }

    if ($titleOld && $titleNew ne $titleOld) {
        # Der Seitentitel hat sich geändert, wir benennen die Seite um
        $self->movePage($pageId,$titleNew);
        print "Page moved: '$titleOld' => '$titleNew'\n";
    }

    # Die Seite ist neu oder hat sich geändert. Wir bringen den
    # neusten Stand aufs Wiki und speichern ihn im Cache.

    my $res = $self->editPage($pageId || $titleNew,$contentNew);
    my $data = Prty::Record->toString(
        Id => $res->{'edit'}->{'pageid'},
        Title => $titleNew,
        Content => $contentNew,
    );
    $p->write($varFile,$data,
        -encode => 'UTF-8',
    );
    print qq|Page updated: $pageId "$titleNew"\n|;

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.128

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
