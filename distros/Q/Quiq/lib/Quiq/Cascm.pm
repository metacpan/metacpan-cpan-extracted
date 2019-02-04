package Quiq::Cascm;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.132;

use Quiq::Path;
use Quiq::CommandLine;
use Quiq::Shell;
use Quiq::Stopwatch;
use File::Temp ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Cascm - Schnittstelle zu CA Harvest SCM

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

=head2 Begriffe

=over 4

=item Workspace-Verzeichnis

Verzeichnis mit den ausgecheckten Dateien. Im CASCM Jargon auch
"Clientpath" genannt, Option -cp.

=item Repository-Datei

Datei im lokalen Workspace-Verzeichnis. Der Pfad einer
Repository-Datei ist relativ zum Repository-Verzeichnis, beginnt
also innerhalb des Workspace-Verzeichnisses.

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

=head2 Kommandos

=head3 addFiles() - Füge Dateien zu Repository hinzu

=head4 Synopsis

    $scm->addFiles($package,$repoDir,@files);

=head4 Arguments

=over 4

=item $packge

Package, zu dem die Dateien hinzugefügt werden.

=item $repoDir

Verzeichnis I<innerhalb> des Workspace, in das die Dateien
kopiert werden.

=item @files

Liste von Dateien I<außerhalb> des Workspace.

=back

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub addFiles {
    my ($self,$package,$repoDir,@files) = @_;

    my $workspace = $self->workspace;

    for my $srcFile (@files) {
        my (undef,$file) = Quiq::Path->split($srcFile);
        my $repoFile = sprintf '%s/%s',$repoDir,$file;

        # Kopiere Datei ins Repository

        Quiq::Path->copy($srcFile,"$workspace/$repoFile",
            -overwrite => 0,
            -preserve => 1,
        );

        # Checke Datei ein
        $self->checkin($package,$repoFile);
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 checkin() - Checke Repository-Dateien ein

=head4 Synopsis

    $scm->checkin($package,@repoFiles);

=head4 Arguments

=over 4

=item $packge

Package.

=item @repoFiles

Liste von Repository-Dateien.

=back

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub checkin {
    my ($self,$package,@repoFiles) = @_;

    # Checke Repository-Dateien ein

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

    $self->run('hci',$c);

    return;
}

# -----------------------------------------------------------------------------

=head3 checkout() - Checke Repository-Dateien aus

=head4 Synopsis

    $scm->checkout($package,@repoFiles);

=head4 Arguments

=over 4

=item $packge

Package.

=item @repoFiles

Liste von Repository-Dateien.

=back

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub checkout {
    my ($self,$package,@repoFiles) = @_;

    # Checke aus

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

=head3 demote() - Demote Package

=head4 Synopsis

    $scm->demote($package,$state);

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

sub demote {
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

=head3 promote() - Promote Package

=head4 Synopsis

    $scm->promote($package,$state);

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

sub promote {
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

=head3 version() - Versionsnummer Repository-Datei

=head4 Synopsis

    $versiion = $scm->version($repoFile);

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

=head3 putFiles() - Füge Datei zu Repository hinzu oder aktualisiere sie

=head4 Synopsis

    $scm->putFiles($package,$repoDir,@files);

=head4 Arguments

=over 4

=item $packge

Package, zu dem die Dateien gehören bzw. zu dem sie
hinzugefügt werden.

=item $repoDir

Verzeichnis I<innerhalb> des Workspace, in das die Dateien
kopiert werden.

=item @files

Liste von Dateien I<außerhalb> des Workspace.

=back

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub putFiles {
    my ($self,$package,$repoDir,@files) = @_;

    my $workspace = $self->workspace;
    my $sh = Quiq::Shell->new;

    for my $srcFile (@files) {
        my (undef,$file) = Quiq::Path->split($srcFile);
        my $repoFile = sprintf '%s/%s',$repoDir,$file;

        if (-e "$workspace/$repoFile") {
            # Die Repository-Datei existiert. Prüfe, ob Quelldatei und
            # Repository-Datei sich unterscheiden. Wenn nein, ist
            # nichts zu tun.

            if (!Quiq::Path->compare($srcFile,"$workspace/$repoFile")) {
                # Bei fehlender Differenz tun wir nichts
                next;
            }

            # Checke Repository-Datei aus
            $self->checkout($package,$repoFile);

            # Kopiere Datei ins Repository

            Quiq::Path->copy($srcFile,"$workspace/$repoFile",
                -overwrite => 1,
                -preserve => 1,
            );

            # Checke Repository-Datei ein
            $self->checkin($package,$repoFile);
        }
        else {
            # Die Repository-Datei existiert nocht nicht. Füge sie hinzu.
            $self->addFiles($package,$repoDir,$srcFile);
        }
    }

    return;
}

# -----------------------------------------------------------------------------

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

    my $fh2 = File::Temp->new(UNLINK=>!$keepTempFiles); 
    my $outputFile = $fh2->filename;
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

        my $fh1 = File::Temp->new(UNLINK=>0);
        my $parameterFile = $fh1->filename;
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

1.132

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
