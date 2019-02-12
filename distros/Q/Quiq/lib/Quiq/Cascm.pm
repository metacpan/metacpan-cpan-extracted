package Quiq::Cascm;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.134;

use Quiq::Path;
use Quiq::CommandLine;
use Quiq::Stopwatch;
use Quiq::TempFile;
use Quiq::Shell;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Cascm - Schnittstelle zu CA Harvest SCM

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse stellt eine Schnittstelle zu einem
CA Harvest SCM Server zur Verfügung.

=head2 Begriffe

=over 4

=item Workspace

Lokales Verzeichnis mit (Kopien von) Repository-Dateien. Der
Pfad wird "Clientpath" genannt, Option -cp´, z.B. C<~/var/workspace>.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $scm = $class->new(@attVal);

=head4 Arguments

=over 4

=item @attVal

Liste von Attribut-Wert-Paaren.

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @attVal

    my $self = $class->SUPER::new(
        user => undef,           # -usr (deprecated)
        password => undef,       # -pw (deprecated)
        passwordFile => undef,   # -eh
        broker => undef,         # -b
        projectContext => undef, # -en
        viewPath => undef,       # -vp
        workspace => undef,      # -cp
        defaultState => undef,   # -st
        keepTempFiles => 0,
        verbose => 1,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Externe Dateien

=head3 putFiles() - Füge Dateien zum Repository hinzu

=head4 Synopsis

    $scm->putFiles($package,$repoDir,@files);

=head4 Arguments

=over 4

=item $packge

Package, dem die Dateien innerhalb von CASCM zugeordnet werden.

=item $repoDir

Zielverzeichnis I<innerhalb> des Workspace, in das die Dateien
kopiert werden. Dies ist ein I<relativer> Pfad.

=item @files

Liste von Dateien I<außerhalb> des Workspace.

=back

=head4 Returns

nichts

=head4 Description

Kopiere die Dateien @files in das Workspace-Verzeichnis $repoDir
und checke sie anschließend ein, d.h. füge sie zum Repository hinzu.
Eine Datei, die im Workspace-Verzeichnis schon vorhanden ist, wird
zuvor ausgecheckt.

Mit dieser Methode ist es möglich, sowohl neue Dateien zum Workspace
hinzuzufügen als auch bereits existierende Dateien im Workspace
zu aktualisieren. Dies geschieht für den Aufrufer transparent, er
braucht sich um die Unterscheidung nicht zu kümmern.

=cut

# -----------------------------------------------------------------------------

sub putFiles {
    my ($self,$package,$repoDir,@files) = @_;

    my $workspace = $self->workspace;
    my $p = Quiq::Path->new;

    for my $srcFile (@files) {
        my (undef,$file) = $p->split($srcFile);
        my $repoFile = sprintf '%s/%s',$repoDir,$file;

        if (-e "$workspace/$repoFile") {
            # Die Workspace-Datei existiert bereits. Prüfe, ob Quelldatei
            # und die Workspace-Datei sich unterscheiden. Wenn nein, ist
            # nichts zu tun.

            if (!$p->different($srcFile,"$workspace/$repoFile")) {
                # Bei fehlender Differenz tun wir nichts
                next;
            }

            # Checke Repository-Datei aus
            $self->checkout($package,$repoFile);
        }

        # Kopiere externe Datei in den Workspace. Entweder ist
        # sie neu oder sie wurde zuvor ausgecheckt.

        $p->copy($srcFile,"$workspace/$repoFile",
            -overwrite => 1,
            -preserve => 1,
        );

        # Checke Workspace-Datei ins Repository ein
        $self->checkin($package,$repoFile);
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Workspace-Dateien

=head3 checkout() - Checke Repository-Dateien aus

=head4 Synopsis

    $scm->checkout($package,@repoFiles);

=head4 Arguments

=over 4

=item $package

Package, dem die ausgecheckte Datei (mit reservierter Version)
zugeordnet wird.

=item @repoFiles

Liste von Workspace-Dateien, die ausgecheckt werden.

=back

=head4 Returns

nichts

=head4 Description

Checke die Workspace-Dateien @repoFiles aus.

=cut

# -----------------------------------------------------------------------------

sub checkout {
    my ($self,$package,@repoFiles) = @_;

    # Checke Workspace-Dateien aus

    my $c = Quiq::CommandLine->new;
    for my $repoFile (@repoFiles) {
        $c->addArgument($repoFile);
    }
    $c->addOption(
        $self->credentialOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -st => $self->defaultState,
        -vp => $self->viewPath,
        -cp => $self->workspace,
        -p => $package,
    );
    $c->addBoolOption(
        -up => 1,
        -r => 1,
    );

    $self->run('hco',$c);

    return;
}

# -----------------------------------------------------------------------------

=head3 checkin() - Checke Workspace-Datei ein

=head4 Synopsis

    $scm->checkin($package,$repoFile);

=head4 Arguments

=over 4

=item $package

Package, dem die neue Version der Datei zugeordnet wird.

=item $repoFile

Datei I<innerhalb> des Workspace. Der Dateipfad ist ein I<relativer> Pfad.

=back

=head4 Returns

nichts

=head4 Description

Checke die Workspace-Datei $repoFile ein, d.h. übertrage ihren Stand
als neue Version ins Repository und ordne diese dem Package $package zu.

=cut

# -----------------------------------------------------------------------------

sub checkin {
    my ($self,$package,$repoFile) = @_;

    # Checke Repository-Dateien ein

    my $c = Quiq::CommandLine->new;
    $c->addArgument($repoFile);
    $c->addOption(
        $self->credentialOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -st => $self->defaultState,
        -vp => $self->viewPath,
        -cp => $self->workspace,
        -p => $package,
    );

    $self->run('hci',$c);

    return;
}

# -----------------------------------------------------------------------------

=head3 version() - Versionsnummer Repository-Datei

=head4 Synopsis

    $version = $scm->version($repoFile);

=head4 Arguments

=over 4

=item $repoFile

Repository-Datei

=back

=head4 Returns

Versionsnummer (String)

=cut

# -----------------------------------------------------------------------------

sub version {
    my ($self,$repoFile) = @_;

    my $output = $self->listVersion($repoFile);
    my ($version) = $output =~ /;(\d+)$/m;
    if (!defined $version) {
        $self->throw("Can't find version number");
    }

    return $version;
}

# -----------------------------------------------------------------------------

=head3 listVersion() - Versionsinformation zu Repository-Datei

=head4 Synopsis

    $info = $scm->listVersion($repoFile);

=head4 Arguments

=over 4

=item $repoFile

Der Pfad der Repository-Datei.

=back

=head4 Returns

Informations-Text (String)

=head4 Description

Ermittele die Versionsinformation über Datei $repoFile und liefere
diese zurück.

=cut

# -----------------------------------------------------------------------------

sub listVersion {
    my ($self,$repoFile) = @_;

    my ($dir,$file) = Quiq::Path->split($repoFile);
    my $viewPath = $self->viewPath;

    my $c = Quiq::CommandLine->new;
    $c->addArgument($file);
    $c->addOption(
        $self->credentialOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -vp => $dir? "$viewPath/$dir": $viewPath,
        -st => $self->defaultState,
    );

    return $self->run('hlv',$c);
}

# -----------------------------------------------------------------------------

=head3 deleteVersion() - Lösche Repository-Datei

=head4 Synopsis

    $scm->deleteVersion($repoFile);

=head4 Arguments

=over 4

=item $repoFile

Der Pfad der zu löschenden Repository-Datei.

=back

=head4 Returns

Nichts

=cut

# -----------------------------------------------------------------------------

sub deleteVersion {
    my ($self,$repoFile) = @_;

    my ($dir,$file) = Quiq::Path->split($repoFile);
    my $viewPath = $self->viewPath;

    my $c = Quiq::CommandLine->new;
    $c->addArgument($file);
    $c->addOption(
        $self->credentialOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -vp => $dir? "$viewPath/$dir": $viewPath,
        -st => $self->defaultState,
    );

    return $self->run('hdv',$c);
}

# -----------------------------------------------------------------------------

=head2 Packages

=head3 createPackage() - Erzeuge Package

=head4 Synopsis

    $scm->createPackage($package);

=head4 Arguments

=over 4

=item $packge

Name des Package, das erzeugt werden soll.

=back

=head4 Returns

nichts

=head4 Description

Erzeuge Package $package.

=cut

# -----------------------------------------------------------------------------

sub createPackage {
    my ($self,$package) = @_;

    # Erzeuge Package

    my $c = Quiq::CommandLine->new;
    $c->addArgument($package);
    $c->addOption(
        $self->credentialOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -st => $self->defaultState,
    );

    $self->run('hcp',$c);

    return;
}

# -----------------------------------------------------------------------------

=head3 deletePackage() - Lösche Package

=head4 Synopsis

    $scm->deletePackage($package);

=head4 Arguments

=over 4

=item $packge

Name des Package, das gelöscht werden soll.

=back

=head4 Returns

nichts

=head4 Description

Lösche Package $package.

=cut

# -----------------------------------------------------------------------------

sub deletePackage {
    my ($self,$package) = @_;

    # Lösche Package

    # Anmerkung: Das Kommando hdlp kann auch mehrere Packages auf
    # einmal löschen. Es ist jedoch nicht gut, es so zu
    # nutzen, da dann nicht-existente Packages nicht bemängelt
    # werden, wenn mindestens ein Package existiert.

    my $c = Quiq::CommandLine->new;
    $c->addOption(
        $self->credentialOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -pkgs => $package,
    );

    $self->run('hdlp',$c);

    return;
}

# -----------------------------------------------------------------------------

=head3 renamePackage() - Benenne Package um

=head4 Synopsis

    $scm->renamePackage($oldName,$newName);

=head4 Arguments

=over 4

=item $oldName

Bisheriger Name des Package.

=item $newName

Zukünftiger Name des Package.

=back

=head4 Returns

nichts

=head4 Description

Benenne Package $oldName in $newName um.

=cut

# -----------------------------------------------------------------------------

sub renamePackage {
    my ($self,$oldName,$newName) = @_;

    # Benenne Package um

    my $c = Quiq::CommandLine->new;
    $c->addOption(
        $self->credentialOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -p => $oldName,
        -npn => $newName,
    );

    $self->run('hup',$c);

    return;
}

# -----------------------------------------------------------------------------

=head3 promotePackage() - Promote Package

=head4 Synopsis

    $scm->promotePackage($package,$state);

=head4 Arguments

=over 4

=item $packge

Package, das promotet werden soll.

=item $state

Stufe, auf dem sich das Package befindet.

=back

=head4 Returns

nichts

=head4 Description

promote Package $package, das sich auf Stufe $state befindet
(befinden muss) auf die darüberliegende Stufe. Befindet sich das
Package auf einer anderen Stufe, schlägt das Kommando fehl.

=cut

# -----------------------------------------------------------------------------

sub promotePackage {
    my ($self,$package,$state) = @_;

    # Promote Package

    my $c = Quiq::CommandLine->new;
    $c->addArgument($package);
    $c->addOption(
        $self->credentialOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -st => $state,
    );

    $self->run('hpp',$c);

    return;
}

# -----------------------------------------------------------------------------

=head3 demotePackage() - Demote Package

=head4 Synopsis

    $scm->demotePackage($package,$state);

=head4 Arguments

=over 4

=item $packge

Package, das demotet werden soll.

=item $state

Stufe, auf dem sich das Package befindet.

=back

=head4 Returns

nichts

=head4 Description

Demote Package $package, das sich auf Stufe $state befindet
(befinden muss) auf die darunterliegende Stufe. Befindet sich das
Package auf einer anderen Stufe, schlägt das Kommando fehl.

=cut

# -----------------------------------------------------------------------------

sub demotePackage {
    my ($self,$package,$state) = @_;

    # Demote Package

    my $c = Quiq::CommandLine->new;
    $c->addArgument($package);
    $c->addOption(
        $self->credentialOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -st => $state,
    );

    $self->run('hdp',$c);

    return;
}

# -----------------------------------------------------------------------------

=head2 Workspace

=head3 sync() - Synchronisiere Workspace mit Repository

=head4 Synopsis

    $scm->sync;

=head4 Description

Bringe den Workspace auf den Stand des Repository.

=cut

# -----------------------------------------------------------------------------

sub sync {
    my $self = shift;

    my $c = Quiq::CommandLine->new;
    $c->addOption(
        $self->credentialOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -vp => $self->viewPath,
        -cp => $self->workspace,
        -st => $self->defaultState,
    );

    my $output = $self->run('hsync',$c);
    $output =~ s/^.*No need.*\n//gm;
    $self->writeOutput($output);

    return;
}

# -----------------------------------------------------------------------------

=head2 Privat

=head3 credentialOptions() - Liste der Credential-Optionen

=head4 Synopsis

    @arr = $scm->credentialOptions;

=cut

# -----------------------------------------------------------------------------

sub credentialOptions {
    my $self = shift;

    if (my $passwordFile = $self->passwordFile) {
        return (-eh=>$passwordFile);
    }

    return (-usr=>$self->user,-pw=>$self->password);
}

# -----------------------------------------------------------------------------

=head3 run() - Führe CA Harvest SCM Kommando aus

=head4 Synopsis

    $output = $scm->run($scmCmd,$c);

=head4 Description

Führe das CA Harvest SCM Kommando $scmCmd mit den Optionen des
Kommandozeilenobjekts $c aus und liefere die Ausgabe des
Kommandos zurück.

=cut

# -----------------------------------------------------------------------------

sub run {
    my ($self,$scmCmd,$c) = @_;

    my $stw = Quiq::Stopwatch->new;

    my $keepTempFiles = $self->keepTempFiles;
    my $useParameterFile = 0;

    # Output-Datei zu den Optionen hinzufügen

    # my $fh2 = % C-<File::Temp> %->new(UNLINK=>!$keepTempFiles); 
    # my $outputFile = $fh2->filename;
    my $outputFile = Quiq::TempFile->new(-unlink=>!$keepTempFiles);
    $c->addOption(-o=>$outputFile);

    my $cmd;
    if ($useParameterFile) {
        # CASCM-Optionen in Datei speichern.
        # MEMO: Die Datei wird von dem Harvest-Kommando auf jeden Fall gelöscht!
        #
        # DIESE VARIANTE FUNKTIONIERT AUS IRGENDWELCHEN GRÜNDEN NICHT!
        #
        # Fehlermeldung:
        # I00060040: New connection with Broker cascm  established.
        # E0202011d: Authentication operation failed: Invalid credentials .
        # Error: Could not create session.
        #
        # Hängt das vielleicht mit dem Prozentzeichen (%) in meinem aktuellen
        # Passwort zusammen? Vorher ging es, glaube ich.

        # my $fh1 = % C-<File::Temp> %->new(UNLINK=>0);
        # my $parameterFile = $fh1->filename;
        my $parameterFile = Quiq::TempFile->new(-unlink=>0);
        Quiq::Path->write($parameterFile," ".$c->command."\n");

        $cmd = "$scmCmd -di $parameterFile";
    }
    else {
        # Diese Variante ist nicht so sicher, da das Passwort auf
        # der Kommandozeile erscheint
        $cmd = sprintf '%s %s',$scmCmd,$c->command;
    }

    # Kommando protokollieren

    if ($self->verbose) {
        my $cmd = $cmd;
        if (my $password = $self->password) {
            $cmd =~ s/\Q$password/****/g;
        }
        warn "> $cmd\n";
    }

    # Kommando ausführen, aus Sicherheitsgründen (Benutzername, Passwort)
    # mit den Optionen aus der oben geschriebenen Parameterdatei.
    # Das Kommando schreibt Fehlermeldungen nach stdout (!), daher leiten
    # wir stdout in die Output-Datei um.

    my $r = Quiq::Shell->exec("$cmd >>$outputFile",-sloppy=>1);
    my $output = Quiq::Path->read($outputFile);
    $output .= sprintf "---\n%.2fs\n",$stw->elapsed;
    if ($r) {
        $self->throw(
            q~CASCM-00001: Command failed~,
            Command => $cmd,
            Output => $output,
        );
    }

    # Wir liefern den Inhalt der Output-Datei zurück
    return $output;
}

# -----------------------------------------------------------------------------

=head3 writeOutput() - Schreibe Kommando-Ausgabe

=head4 Synopsis

    $scm->writeOutput($output);

=cut

# -----------------------------------------------------------------------------

sub writeOutput {
    my ($self,$output) = @_;

    if ($self->verbose) {
        $output =~ s/^/| /mg;
        warn $output;
    }

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.134

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
