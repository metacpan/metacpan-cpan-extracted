package Quiq::ApplicationPaths;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Cwd ();
use Hash::Util ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ApplicationPaths - Ermittele Pfade einer Unix-Applikation

=head1 SYNOPSIS

    # Homedir: <prefix>/opt/<application> (<prefix> kann leer sein)
    
    use FindBin qw/$Bin/;
    use lib "$Bin/../lib/perl5";  # .. d.h. $depth == 1
    use Quiq::ApplicationPaths;
    
    my $app = Quiq::ApplicationPaths->new;
    
    my $name = $app->name;        # <application>
    my $prefix = $app->prefix;    # <prefix>
    
    my $homeDir = $app->homeDir;  # <prefix>/opt/<application>
    my $etcDir = $app->etcDir;    # <prefix>/etc/opt/<application>
    my $varDir = $app->varDir;    # <prefix>/var/opt/<application>

=head1 DESCRIPTION

Die Klasse ermöglicht einer Perl-Applikation unter Unix ohne
hartkodierte absolute Pfade auszukommen. Alle Pfade, unter denen
sich die verschiedenen Teile der Applikation (opt-, etc-,
var-Bereich) im Dateisystem befinden, werden von der Klasse aus
dem Pfad des ausgeführten Programms hergeleitet.

Das Layout entspricht der opt-Installationsstruktur eines
Unix-Systems:

=over 2

=item *

/opt/<application> (Programmcode und statische Daten)

=item *

/etc/opt/<application> (Konfiguration)

=item *

/var/opt/<application> (Bewegungsdaten)

=back

Die Pfade müssen nicht im Root-Verzeichnis beginnen, ihnen kann
auch ein Präfix-Pfad <prefix> vorangestellt sein. Z.B. kann sich die
Struktur im Home-Verzeichnis des Benutzers befinden
(siehe Abschnitt L<EXAMPLES|"EXAMPLES">).

=head1 EXAMPLES

/opt/<application>/...

    prefix()  : (Leerstring)
    name()    : <application>
    homeDir() : /opt/<application>
    etcDir()  : /etc/opt/<application>
    varDir()  : /var/opt/<application>

/home/<user>/opt/<application>/...

    prefix()  : /home/<user>
    name()    : <application>
    homeDir() : /home/<user>/opt/<application>
    etcDir()  : /home/<user>/etc/opt/<application>
    varDir()  : /home/<user>/var/opt/<application>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $app = $class->new;
    $app = $class->new($depth);

=head4 Arguments

=over 4

=item $depth (Default: 1)

Gibt an, wie viele Subverzeichnisse tief das Programm unterhalb des
Applikations-Homedir (<prefix>/opt/<application>) angesiedelt ist.

=back

=head4 Description

Instantiiere ein Objekt der Klasse und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $depth = shift || 1;

    # Wir arbeiten nicht mit den Variablen von FindBin, da diese
    # Symlinks auflösen und wir keinen Symbolischen Namen wie
    # 'prod' als Version erhalten, wenn dies ein Symlink auf eine
    # reale Version ist.

    my $path = $0;
    if ($path !~ m|^/|) {
        # Einen relativen Pfad ergänzen wir um das aktuelle Verzeichnis.
        # Achtung: getcwd liefert möglicherweise nicht den Versionspfad
        # den wir meinen, wenn wir unterhalb von version/<version> stehen.
        # Denn getcwd liefert den realen Pfad und beinhaltet keine Symlinks.
        # Wenn <version> ein Symlink ist, erscheint der reale Name im Pfad.

        $path =~ s|^./||;
        $path = sprintf '%s/%s',Cwd::getcwd,$path;
    }

    # HomeDir bestimmen, indem wir das Programm und $depth
    # Verzeichnisse darüber vom Pfad entfernen
 
    my @path = split m|/|,$path;
    splice @path,-($depth+1);
    my $homeDir = join '/',@path;

    # <application> ist die letzte Pfadkomponente

    my ($application,$etcPath,$varPath);
    $application = pop @path;

    # <prefix> erhalten wir nach dem Entfernen des
    # Verzeichnisses oberhalb von <application>

    pop @path; # opt entfernen
    my $prefix = join('/',@path);

    my $etcDir = "$prefix/etc/opt/$application";
    my $varDir = "$prefix/var/opt/$application";

    my $self = bless {
        name => $application,
        prefix => $prefix,
        homeDir => $homeDir,
        etcDir => $etcDir,
        varDir => $varDir,
    },$class;
    Hash::Util::lock_ref_keys($self);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 name() - Name der Applikation

=head4 Synopsis

    $name = $app->name;

=head4 Description

Liefere den Namen <name> der Applikation.

=cut

# -----------------------------------------------------------------------------

sub name {
    shift->{'name'};
}

# -----------------------------------------------------------------------------

=head3 prefix() - Pfad-Präfix der Installation

=head4 Synopsis

    $prefix = $app->prefix;
    $prefix = $app->prefix($subPath);

=head4 Description

Liefere den Pfad-Präfix <prefix> der Applikations-Installation,
also den Pfad oberhalb des opt-Verzeichnisses. Ist die Applikation
in /opt (opt im Wurzelverzeichnis) installiert, wird ein
Leerstring geliefert. Ist Zeichenkette $subPath angegeben,
wird diese mit '/' getrennt angefügt.

=cut

# -----------------------------------------------------------------------------

sub prefix {
    my $self = shift;
    # @_: $subPath

    my $path = $self->{'prefix'};
    if (@_) {
        $path .= '/'.shift;
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head3 homeDir() - Home-Verzeichnis der Applikation

=head4 Synopsis

    $homeDir = $app->homeDir;
    $homeDir = $app->homeDir($subPath);

=head4 Description

Liefere das Verzeichnis, in dem der Programmcode und die
statischen Daten der Applikation abgelegt sind. Ist Zeichenkette
$subPath angegeben, wird diese mit '/' getrennt angefügt.

=cut

# -----------------------------------------------------------------------------

sub homeDir {
    my $self = shift;
    # @_: $subPath

    my $path = $self->{'homeDir'};
    if (@_) {
        $path .= '/'.shift;
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head3 etcDir() - Konfigurations-Verzeichnis der Applikation

=head4 Synopsis

    $etcDir = $app->etcDir;
    $etcDir = $app->etcDir($subPath);

=head4 Description

Liefere das Verzeichnis, in dem die Konfigurationsdateien der
Applikation abgelegt sind. Ist Zeichenkette $subPath angegeben,
wird diese mit '/' getrennt angefügt.

=cut

# -----------------------------------------------------------------------------

sub etcDir {
    my $self = shift;
    # @_: $subPath

    my $path = $self->{'etcDir'};
    if (@_) {
        $path .= '/'.shift;
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head3 varDir() - Bewegungsdaten-Verzeichnis der Applikation

=head4 Synopsis

    $varDir = $app->varDir;
    $varDir = $app->varDir($subPath);

=head4 Description

Liefere das Verzeichnis, in dem die Applikation Bewegungsdaten speichert.
Ist Zeichenkette $subPath angegeben, wird diese mit '/' getrennt angefügt.

=cut

# -----------------------------------------------------------------------------

sub varDir {
    my $self = shift;
    # @_: $subPath

    my $path = $self->{'varDir'};
    if (@_) {
        $path .= '/'.shift;
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head1 DETAILS

=head2 Mögliche Erweiterungen

=head3 Andere Layouts

Andere Layouts sind möglich und könnten von der Klasse ebenfalls
behandelt werden. Bei Bedarf kann der Konstruktor um eine Option
C<< -layout=>$layout >> erweitert und das betreffende Layout innerhalb
des Konstruktors behandelt werden. Beispiele:

Installation mit Unterscheidung nach Versionsnummer:

    <prefix>/opt/<application>/<version>
    <prefix>/etc/opt/<application>/<version>
    <prefix>/var/opt/<application>/<version>

Installation mit Unterscheidung nach Versionsnummer in eigenem
Subverzeichnis:

    <prefix>/opt/<application>/version/<version>
    <prefix>/etc/opt/<application>/<version>
    <prefix>/var/opt/<application>/<version>

Kein opt-Unterverzeichnis in etc und var:

    <prefix>/opt/<application>
    <prefix>/etc/<application>
    <prefix>/var/<application>

=head3 Optionaler Trenner bei etcDir() und varDir()

Die Methoden etcDir() und varDir() könnten um eine Variante mit
zwei Parametern erweitert werden, die die Vorgabe des
Trennzeichens erlaubt:

    $path = $app->etcDir('','.conf');
    # <prefix>/etc/opt/<application>.conf
    
    $path = $app->varDir('','.log');
    # <prefix>/etc/opt/<application>.log

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
