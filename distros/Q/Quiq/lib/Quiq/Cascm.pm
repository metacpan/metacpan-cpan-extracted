package Quiq::Cascm;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.131;

use Quiq::Path;
use Quiq::CommandLine;
use Quiq::Shell;
use File::Temp ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Cascm - Schnittstelle zu CA Harvest SCM

=head1 BASE CLASS

L<Quiq::Hash>

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
        user => undef,           # -usr
        password => undef,       # -pw
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

=head3 listVersion() - Liefere Versionsinformation

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

    my $viewPath = $self->viewPath;
    my ($dir,$file) = Quiq::Path->split($repoFile);

    my $c = Quiq::CommandLine->new;
    $c->addArgument($file);
    $c->addOption(
        -usr => $self->user,
        -pw => $self->password,
        -b => $self->broker,
        -en => $self->projectContext,
        -vp => $dir? "$viewPath/$dir": $viewPath,
        -st => $self->defaultState,
    );

    return $self->run('hlv',$c);
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
        -usr => $self->user,
        -pw => $self->password,
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
        my $password = $self->password;
        (my $cmd = $cmd) =~ s/\Q$password/****/g;
        warn "> $cmd\n";
    }

    # Kommando ausführen, aus Sicherheitsgründen (Benutzername, Passwort)
    # mit den Optionen aus der oben geschriebenen Parameterdatei.
    # Das Kommando schreibt Fehlermeldungen nach stdout (!), daher leiten
    # wir stdout in die Output-Datei um.

    my $r = Quiq::Shell->exec("$cmd >>$outputFile",-sloppy=>1);
    my $output = Quiq::Path->read($outputFile);
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

1.131

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
