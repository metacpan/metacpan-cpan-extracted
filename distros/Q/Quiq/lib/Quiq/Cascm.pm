package Quiq::Cascm;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;
use utf8;

our $VERSION = '1.172';

use Quiq::Database::Row::Array;
use Quiq::AnsiColor;
use Quiq::Shell;
use Quiq::Path;
use Quiq::Converter;
use Quiq::Terminal;
use Quiq::CommandLine;
use Quiq::TempDir;
use Quiq::Array;
use Quiq::Stopwatch;
use Quiq::TempFile;
use Quiq::Unindent;
use Quiq::Database::Connection;
use Quiq::Database::ResultSet::Array;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Cascm - Schnittstelle zu CA Harvest SCM

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse stellt eine Schnittstelle zu einem
CA Harvest SCM Server zur Verfügung.

=head1 SEE ALSO

=over 2

=item *

L<https://docops.ca.com/ca-harvest-scm/13-0/en>

=item *

L<https://search.ca.com/assets/SiteAssets/TEC486141_External/TEC486141.pdf>

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $scm = $class->new(@attVal);

=head4 Attributes

=over 4

=item user => $user

Benutzername (-usr).

=item password => $password

Passwort (-pw).

=item credentialsFile => $file

Datei (Pfad) mit verschlüsseltem Benuternamen und Passwort (-eh).
Diese Authentisierungsmethode ist gegenüber user und password
aus Sicherheitsgründen vorzuziehen.

=item hsqlCredentialsFile => $file

Wie credentialsFile, nur für das hsql-Kommando, falls hierfür
eine andere Authentisierung nötig ist.

=item broker => $broker

Name des Brokers (-b).

=item projectContext => $project

Name des Projektes, auch Environment genannt (-en).

=item viewPath => $viewPath

Pfad im Project (-vp).

=item workspace => $workspace

Pfad zum (lokalen) Workspace-Verzeichnis.

=item states => \@states

Liste der Stufen, bginnend mit der untersten Stufe, auf der
Workspace-Dateien aus- und eingecheckt werden.

=item udl => $udl

Universal Database Locator für die CASCM-Datenbank. Ist dieser
definiert, wird die CASCM-Datenbank direkt zugegriffen, nicht
über das Programm hsql.

=item keepTempFiles => $bool (Default: 0)

Lösche Temporäre Dateien nicht.

=item dryRun => $bool (Default: 0)

Führe keine ändernden Kommandos aus.

=item verbose => $bool (Default: 1)

Schreibe Information über die Kommandoausführung nach STDERR.

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
        user => undef,                # -usr (deprecated)
        password => undef,            # -pw (deprecated)
        credentialsFile => undef,     # -eh
        hsqlCredentialsFile => undef, # -eh - für Datenbankabfragen
        broker => undef,              # -b
        projectContext => undef,      # -en
        viewPath => undef,            # -vp
        workspace => undef,           # -cp
        states => [                   # -st
            'Entwicklung',
            'TTEST',
            'STEST',
            'RTEST',
            'Produktion',
        ],
        udl => undef,                 # für direkten Zugriff auf DB
        keepTempFiles => 0,
        dryRun => 0,
        verbose => 1,
        # Private Attribute
        db => undef,                  # wenn DB-Zugriff über UDL
        sh => undef,
        a => Quiq::AnsiColor->new(-t STDOUT),
        @_,
    );

    my $sh = Quiq::Shell->new(
        dryRun => $self->dryRun,
        log => $self->verbose,
        logDest => *STDERR,
        logRewrite => sub {
            my ($sh,$cmd) = @_;
            if (my $passw = $self->password) {
                $cmd =~ s/\Q$passw/xxxxx/g;
            }
            return $cmd;
        },
        cmdPrefix => '> ',
        cmdAnsiColor => 'bold',
    );
    $self->set(sh=>$sh);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Datei bearbeiten

=head3 abstract() - Übersicht über Inhalt von Packages

=head4 Synopsis

  $abstract = $scm->abstract($regex);

=head4 Arguments

=over 4

=item $regex

Regex, der die Packages matcht, deren Inhalt angezeigt werden soll

=back

=head4 Returns

Übersicht (String)

=head4 Description

Erzeuge eine Übersicht über die Packages, deren Name den Regex $regex
matcht, und ihren Inhalt.

=head4 Example

  $ ruv-dss-repo abstract Seitz_X
  S6800_0_Seitz_X_Deployment TTEST
      tools/post_deployment/deploy_ddl.pl 34
      tools/post_deployment/deploy_udf.pl 28
  
  S6800_0_Seitz_X_Deployment_Test TTEST
      ddl/table/test_table.sql 4
      ddl/udf/lib/test_function.sql 1
  
  S6800_0_Seitz_X_Fahrstuhl_1 Entwicklung
  
  S6800_0_Seitz_X_Fahrstuhl_2 Entwicklung
  
  S6800_0_Seitz_X_MetaData TTEST
      ddl/udf/lib/rv_create_dbobject_ddl.sql 5
      lib/zenmod/DSS/MetaData.pm 14
  
  S6800_0_Seitz_X_Portierte_Programme Entwicklung
      bin/stichtag.pl 1
      bin/verd_prd_zuord_dim.pl 24
      bin/vertr_kms_progn_hist.pl 4
      lib/zenmod/Sparhist.pm 37
      tab_clone.pl 4
      tools/wasMussIchTesten.pl 1
  
  S6800_0_Seitz_X_Portierte_Tabellen TTEST
      ddl/table/q12b067.sql 0
      ddl/table/q98b3s33.sql 0
      ddl/table/sf_ga_liste_online_renta.sql 1
      ddl/table/sf_kredu_meldw_dz_zlms_vol_wkv.sql 6
      ddl/table/sf_vden_agt_liste.sql 1
  
  S6800_0_Seitz_X_Session TTEST
      ddl/udf/lib/rv_stage.sql 2
      lib/zenmod/DSS/Session.pm 2
  
  S6800_0_Seitz_X_ZenMods TTEST
      lib/zenmod/DSSDB/Greenplum.pm 108

=cut

# -----------------------------------------------------------------------------

sub abstract {
    my ($self,$regex) = @_;

    my $a = $self->a;

    # Packages und ihre Stage bestimmen

    my %package;
    for my $row ($self->listPackages->rows) {
        my ($package,$state) = @$row;
        if ($package =~ qr/$regex/) {
            $package{$package} = [$state,{}];
        }
    }

    # Items der Packages

    my %item;
    for my $row ($self->showPackage(keys %package)) {
        my $package = $row->[5];
        my $item = $row->[1];
        my $version = $row->[3];

        my $maxVersion = $package{$package}[1]{$item} //= -1;
        if ($version > $maxVersion) {
            $package{$package}[1]{$item} = $version;
        }
    }    

    my $str = '';
    my $i = 0;
    for my $package (sort keys %package) {
        my ($state,$itemH) = @{$package{$package}};

        if ($i++) {
            $str .= "\n";
        }

        $str .= sprintf "%s %s\n",
            $a->str('red',$package),
            $a->str('green',$state);

        for my $item (sort keys %$itemH) {
            (my $realItem = $item) =~ s|/zenmod/|/|;
            my $version = $itemH->{$item};
            $str .= sprintf "    %s %s\n",$realItem,$a->str('green',$version);
        }
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head2 Datei bearbeiten

=head3 edit() - Bearbeite Repository-Datei

=head4 Synopsis

  $output = $scm->edit($repoFile);
  $output = $scm->edit($repoFile,$package);

=head4 Arguments

=over 4

=item $repoFile

Datei mit Repository-Pfadangabe.

=item $package

Package, dem die ausgecheckte Datei (mit reservierter Version)
beim Einchecken zugeordnet wird. Das Package muss I<nicht> auf der
untersten Stufe stehen. Befindet es sich auf einer höheren Stufe, wird
intern ein Transportpackage erzeugt, das die Dateien zu der Stufe
des Package bewegt.

=back

=head4 Returns

Ausgabe der CASCM-Kommandos (String)

=head4 Description

Checke die Repository-Datei $repoFile aus und öffne sie im Editor.
Nach dem Verlassen des Editors wird geprüft, ob die Datei (eine Kopie
im lokalen Verzeichnis) verändert wurde. Der Benutzer wird gefragt,
ob er seine Änderungen ins Repository übertragen möchte oder nicht.
Anschließend wird die Repository-Datei wieder eingecheckt. Dies
geschieht, gleichgültig, ob sie geändert wurde oder nicht. CASCM
vergibt nur dann eine neue Versionsnummer, wenn die Datei sich
geändert hat.

=cut

# -----------------------------------------------------------------------------

sub edit {
    my ($self,$repoFile,$package) = @_;

    my $output = '';

    my $p = Quiq::Path->new;

    # Vollständigen Pfad der Repository-Datei ermitteln
    my $file = $self->repoFileToFile($repoFile);

    if (!$package) {
        $package = $self->package($repoFile);
    }

    # Ermittele die Stufe des Package
    my $state = $self->packageState($package);

    # Erzeuge ein Transportpackage, falls sich das Zielpackage
    # nicht auf der untersten Stufe befindet

    my $transportPackage;
    if ($state ne $self->states->[0]) {
        my $name = Quiq::Converter->intToWord(time);
        $transportPackage = "S6800_0_Seitz_Lift_$name";
        $output .= $self->createPackage($transportPackage);
    }

    # Lokale Kopie der Datei erstellen

    my $localFile = '~/tmp/'.$p->filename($file);
    my $which = 'r';
    if (-e $localFile) {
        # Repo-Datei muss nicht kopiert werden, wenn sie schon
        # vorhanden ist, falls sie nicht differiert
        $which = 'l';
        if ($p->compare($file,$localFile)) {
            $which = Quiq::Terminal->askUser(
                'Local file exists and differs from repository file.'.
                    ' Which file: l=local, r=repository, q=quit?',
                -values => 'l/r/q',
                -default => 'r',
            );
            if ($which eq 'q') {
                return $output;
            }
            # Datei differiert und wird kopiert, wenn r gewählt wurde
        }
    }
    if ($which eq 'r') {
        $p->copyToDir($file,'~/tmp');
    }

    # Original-Datei mit dem Stand vor der ersten Änderung sichern

    my $origFile = "$localFile.orig";
    if (!$p->exists($origFile)) {
        $p->copy($localFile,$origFile);
    }

    # Backup-Datei erstellen für den Vergleich nach
    # dem Verlassen des Editors

    my $backupFile = "$localFile.bak";
    $p->copy($localFile,$backupFile);

    # Checke Datei aus
    $output .= $self->checkout($transportPackage || $package,$repoFile);

    my $fileChanged = 0;
    my $editor = $ENV{'EDITOR'} || 'vi';
    while (1) {
        Quiq::Shell->exec("$editor $localFile");
        if ($p->compare($localFile,$backupFile)) {
            # Im Falle von Perl-Code diesen auf Syntaxfehler hin überprüfen

            my $sytaxError = 0;
            my $ext = $p->extension($localFile);
            if ($ext eq 'pm' || $ext eq 'pl') {
                my $out = $self->sh->exec("perl -c $localFile",
                    -capture => 'stdout+stderr',
                    -sloppy => 1,
                );
                print $self->a->str('red',$out);
                if ($out !~ /syntax OK/) {
                    $sytaxError = 1;
                }
            }

            # Rückfrage an Benutzer

            my $answ = Quiq::Terminal->askUser(
                "Save changes to repository (y=yes, n=no, e=edit)?",
                -values => 'y/n/e',
                -default => $sytaxError? 'e': 'y',
            );
            if ($answ eq 'y') {
                my $workspace = $self->workspace;
                $p->copy($localFile,"$workspace/$repoFile",
                    -overwrite => 1,
                    -preserve => 1,
                );
                $fileChanged = 1;
            }
            elsif ($answ eq 'e') {
                redo;
            }
        }
        elsif (!$p->compare($localFile,$origFile)) {
            # Wir löschen die Lokale Datei und Original-Datei, wenn sie
            # nach dem Verlassen des Editors identisch sind
            $p->delete($origFile);
            $p->delete($localFile);
        }
        last;
    }

    if (!$fileChanged) {
        say $self->a->str('green','NO CHANGE');
    }

    # Checke Datei ein. Wenn sie nicht geändert wurde (d.h. kein Copy
    # oben), wird keine neue Version erzeugt.
    $output .= $self->checkin($transportPackage || $package,$repoFile);
    
    if ($transportPackage) {
        if ($fileChanged) {
            $output .= $self->movePackage($state,$transportPackage,
                -askUser => 1,
            );
            $output .= $self->switchPackage($transportPackage,
                $package,$repoFile);
        }
        $output .= $self->deletePackages($transportPackage);
    }

    # Die Backup-Datei löschen wir immer
    $p->delete($backupFile);

    return $output;
}

# -----------------------------------------------------------------------------

=head3 view() - Repository-Datei ansehen

=head4 Synopsis

  $scm->view($repoFile);

=head4 Arguments

=over 4

=item $repoFile

Datei mit Repository-Pfadangabe.

=back

=head4 Returns

nichts

=head4 Description

Öffne die Repository-Datei $repoFile im Pager.

=cut

# -----------------------------------------------------------------------------

sub view {
    my ($self,$repoFile,$package) = @_;

    my $file = $self->repoFileToFile($repoFile);
    Quiq::Shell->exec("emacs $file --eval '(setq buffer-read-only t)'");

    return;
}

# -----------------------------------------------------------------------------

=head2 Externe Dateien

=head3 putFiles() - Füge Dateien zum Repository hinzu

=head4 Synopsis

  $output = $scm->putFiles($package,$repoDir,@files);

=head4 Arguments

=over 4

=item $package

Package, dem die Dateien innerhalb von CASCM zugeordnet werden. Das
Package muss I<nicht> auf der untersten Stufe stehen. Befindet es sich
auf einer höheren Stufe, wird intern ein Transportpackage erzeugt,
das die Dateien zu der Stufe des Package bewegt.

=item $repoDir

Zielverzeichnis I<innerhalb> des Workspace, in das die Dateien
kopiert werden. Dies ist ein I<relativer> Pfad.

=item @files

Liste von Dateien I<außerhalb> des Workspace.

=back

=head4 Returns

Konkatenierte Ausgabe der der checkout- und checkin-Kommandos (String)

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

    my $output = '';

    # Ermittele die Stufe des Package

    my $state = $self->packageState($package);
    #if (!$state) {
    #    $self->throw(
    #        'CASCM-00099: Package does not exist',
    #        Package => $package,
    #    );
    #}

    # Erzeuge ein Transportpackage, falls sich das Zielpackage
    # nicht auf der untersten Stufe befindet

    my $transportPackage;
    if ($state ne $self->states->[0]) {
        my $name = Quiq::Converter->intToWord(time);
        $transportPackage = "S6800_0_Seitz_Lift_$name";
        $output .= $self->createPackage($transportPackage);
    }

    my @items;
    for my $srcFile (@files) {
        my (undef,$file) = $p->split($srcFile);
        my $repoFile = sprintf '%s/%s',$repoDir,$file;

        if (-e "$workspace/$repoFile") {
            # Die Workspace-Datei existiert bereits. Prüfe, ob Quelldatei
            # und die Workspace-Datei sich unterscheiden. Wenn nein, ist
            # nichts zu tun.

            if (!$p->compare($srcFile,"$workspace/$repoFile")) {
                # Bei fehlender Differenz tun wir nichts
                next;
            }

            # Checke Repository-Datei aus

            $output .= $self->checkout($transportPackage ||
                $package,$repoFile);
        }

        # Kopiere externe Datei in den Workspace. Entweder ist
        # sie neu oder sie wurde zuvor ausgecheckt.

        $p->copy($srcFile,"$workspace/$repoFile",
            -overwrite => 1,
            -preserve => 1,
        );

        # Checke Workspace-Datei ins Repository ein
        $output .= $self->checkin($transportPackage || $package,$repoFile);  

        # Liste der Items im Packate (nur relevant
        # im Falle eines Transportpackage)
        push @items,$file;
    }

    if ($transportPackage) {
        $output .= $self->movePackage($state,$transportPackage,
            -askUser => 1,
        );
        $output .= $self->switchPackage($transportPackage,
            $package,@items);
        $output .= $self->deletePackages($transportPackage);
    }

    return $output;
}

# -----------------------------------------------------------------------------

=head3 putDir() - Füge Dateien eines Verzeichnisbaums zum Repository hinzu

=head4 Synopsis

  $output = $scm->putDir($package,$dir);

=head4 Arguments

=over 4

=item $package

Package, dem die Dateien innerhalb von CASCM zugeordnet werden.
Das Package sollte sich auf der untersten Stufe befinden.

=item $dir

Quellverzeichnis, dem die Dateien entnommen werden. Die Pfade
I<innerhalb> von $dir werden als Repository-Pfade verwendet.
Die Repository-Pfade müssen vorab existieren, sonst wird eine
Exception geworfen.

=back

=head4 Returns

Konkatenierte Ausgabe der der checkout- und checkin-Kommandos (String)

=head4 Description

Füge alle Dateien in Verzeichnis $dir via Methode put()
zum Repository hinzu bzw. aktualisiere sie.

=cut

# -----------------------------------------------------------------------------

sub putDir {
    my ($self,$package,$dir) = @_;

    my $workspace = $self->workspace;
    my $p = Quiq::Path->new;

    my @files = sort $p->find($dir,-type=>'f');

    my $output;

    for my $srcFile (@files) {
        my ($repoDir,$repoFile) = $p->split($srcFile);
        $repoDir =~ s|^\Q$dir/||; # Pfadanfang entfernen
        my $workspaceDir = "$workspace/$repoDir";
        if (!$p->exists($workspaceDir)) {
            $self->throw(
                'CASCM-00099: Workspace directory does not exist',
                WorkspaceDir => $workspaceDir,
            );
        }
        $output .= $self->putFiles($package,$repoDir,$srcFile);
    }

    return $output;
}

# -----------------------------------------------------------------------------

=head2 Workspace-Dateien

=head3 checkout() - Checke Repository-Dateien aus

=head4 Synopsis

  $output = $scm->checkout($package,@repoFiles);

=head4 Arguments

=over 4

=item $package

Package, dem die ausgecheckte Datei (mit reservierter Version)
zugeordnet wird.

=item @repoFiles

Liste von Workspace-Dateien, die ausgecheckt werden.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Checke die Workspace-Dateien @repoFiles aus und liefere die
Ausgabe des Kommandos zurück.

=cut

# -----------------------------------------------------------------------------

sub checkout {
    my ($self,$package,@repoFiles) = @_;

    my $c = Quiq::CommandLine->new;
    for my $repoFile (@repoFiles) {
        $c->addArgument($repoFile);
    }
    $c->addOption(
        $self->credentialsOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -st => $self->states->[0],
        -vp => $self->viewPath,
        -cp => $self->workspace,
        -p => $package,
    );
    $c->addBoolOption(
        -up => 1,
        -r => 1,
    );

    return $self->runCmd('hco',$c);
}

# -----------------------------------------------------------------------------

=head3 checkin() - Checke Workspace-Datei ein

=head4 Synopsis

  $output = $scm->checkin($package,$repoFile);

=head4 Arguments

=over 4

=item $package

Package, dem die neue Version der Datei zugeordnet wird.

=item $repoFile

Datei I<innerhalb> des Workspace. Der Dateipfad ist ein I<relativer> Pfad.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Checke die Workspace-Datei $repoFile ein, d.h. übertrage ihren Stand
als neue Version ins Repository, ordne diese dem Package $package zu
und liefere die Ausgabe des Kommandos zurück.

=cut

# -----------------------------------------------------------------------------

sub checkin {
    my ($self,$package,$repoFile) = @_;

    my $c = Quiq::CommandLine->new;
    $c->addArgument($repoFile);
    $c->addOption(
        $self->credentialsOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -st => $self->states->[0],
        -vp => $self->viewPath,
        -cp => $self->workspace,
        -p => $package,
    );

    return $self->runCmd('hci',$c);
}

# -----------------------------------------------------------------------------

=head3 versionNumber() - Versionsnummer Repository-Datei

=head4 Synopsis

  $version = $scm->versionNumber($repoFile);

=head4 Arguments

=over 4

=item $repoFile

Repository-Datei

=back

=head4 Returns

Versionsnummer (Integer)

=cut

# -----------------------------------------------------------------------------

sub versionNumber {
    my ($self,$repoFile) = @_;

    my $output = $self->versionInfo($repoFile);
    my ($version) = $output =~ /;(\d+)$/m;
    if (!defined $version) {
        $self->throw("Can't find version number in output");
    }

    return $version;
}

# -----------------------------------------------------------------------------

=head3 versionInfo() - Versionsinformation zu Repository-Datei

=head4 Synopsis

  $info = $scm->versionInfo($repoFile);

=head4 Arguments

=over 4

=item $repoFile

Der Pfad der Repository-Datei.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Ermittele die Versionsinformation über Datei $repoFile und liefere
diese zurück.

=cut

# -----------------------------------------------------------------------------

sub versionInfo {
    my ($self,$repoFile) = @_;

    my ($dir,$file) = Quiq::Path->split($repoFile);
    my $viewPath = $self->viewPath;

    my $c = Quiq::CommandLine->new;
    $c->addArgument($file);
    $c->addOption(
        $self->credentialsOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -vp => $dir? "$viewPath/$dir": $viewPath,
        -st => $self->states->[0],
    );

    return $self->runCmd('hlv',$c);
}

# -----------------------------------------------------------------------------

=head3 getVersion() - Speichere Version einer Datei

=head4 Synopsis

  $file = $scm->getVersion($repoFile,$version,$destDir,@opt);

=head4 Arguments

=over 4

=item $repoFile

Repository-Datei, die gespeichert werden soll.

=item $version

Version der Repository-Datei.

=item $destDir

Zielverzeichnis, in dem die Repository-Datei gespeichert wird.

=back

=head4 Options

=over 4

=item -sloppy => $bool (Default: 0)

Prüfe nicht, ob die angegebene Version existiert. Dies spart
einen CASCM Aufruf und ist sinnvoll, wenn die Richtigkeit der
Versionsnummer gesichert ist, siehe deleteToVersion().

=item -versionSuffix => $bool (Default: 1)

Hänge die Version an den Dateinamen an.

=back

=head4 Returns

Pfad der Datei (String)

=head4 Description

Speichere die Repository-Datei $repoFile der Version $version in
Verzeichnis $destDir und liefere den Pfad der Datei zurück.

=cut

# -----------------------------------------------------------------------------

sub getVersion {
    my $self = shift;

    # Optionen und Argumente

    my $sloppy = 0;
    my $versionSuffix = 1;

    my $argA = $self->parameters(3,3,\@_,
        -sloppy => \$sloppy,
        -versionSuffix => \$versionSuffix,
    );
    my ($repoFile,$version,$destDir) = @$argA;

    # Operation ausführen

    if (!$sloppy) {
        my $repoVersion = $self->versionNumber($repoFile);
        if ($version > $repoVersion) {
            $self->throw(
                'CASCM-00099: Version does not exist',
                Version => $version,
                RepoFile => $repoFile,
            );
        }
    }

    my $p = Quiq::Path->new;
    my $tempDir = $p->tempDir;

    my $c = Quiq::CommandLine->new;
    $c->addArgument($repoFile);
    $c->addOption(
        $self->credentialsOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -st => $self->states->[0],
        -vp => $self->viewPath,
        -cp => $tempDir,
        -vn => $version,
    );
    $c->addBoolOption(
        -br => 1,
        -r => 1,
    );
    my $output = $self->runCmd('hco',$c);

    my $srcFile = "$tempDir/$repoFile";
    my $destFile = sprintf '%s/%s',$destDir,$p->filename($repoFile);
    if ($versionSuffix) {
        $destFile .= ".$version";
    }
    $p->copy($srcFile,$destFile);

    return $destFile;
}

# -----------------------------------------------------------------------------

=head3 diff() - Differenz zwischen zwei Versionen

=head4 Synopsis

  $diff = $scm->diff($repoFile,$version1,$version2);

=head4 Arguments

=over 4

=item $repoFile

Repository-Datei, deren Versionen verglichen werden.

=item $version1

Erste zu vergleichende Version der Repository-Datei.

=item $version2

Zweite zu vergleichende Version der Repository-Datei.

=back

=head4 Returns

Differenz (String)

=head4 Description

Ermittele die Differenz zwischen den beiden Versionen $version1 und
$version2 der Repository-Datei $repoFile und liefere das Ergebnis
zurück.

=cut

# -----------------------------------------------------------------------------

sub diff {
    my ($self,$repoFile,$version1,$version2) = @_;

    my $tempDir = Quiq::TempDir->new;

    my $file1 = $self->getVersion($repoFile,$version1,$tempDir);
    my $file2 = $self->getVersion($repoFile,$version2,$tempDir);

    return Quiq::Shell->exec("diff $file1 $file2",
        -capture => 'stdout',
        -sloppy => 1,
    );
}

# -----------------------------------------------------------------------------

=head3 deleteVersion() - Lösche höchste Version von Repository-Datei

=head4 Synopsis

  $output = $scm->deleteVersion($repoFile);
  $output = $scm->deleteVersion($repoFile,$version);

=head4 Arguments

=over 4

=item $repoFile

Der Pfad der zu löschenden Repository-Datei.

=item $version (Default: I<höchste Versionsnummer>)

Version der Datei, die gelöscht werden soll.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Lösche die höchste Version oder bis zur Version $version die
Repository-Datei $repoFile. Befinden sich davon eine oder mehrere
Versionen nicht auf der untersten Stufe, wird ein temporäres
Transport-Package erzeugt und die Versionen darüber vor dem Löschen
auf die unterste Ebene bewegt.

=head4 Examples

Höchste Version der Datei C<lib/MetaData.pm> löschen:

  $scm->deleteVersion('lib/MetaData.pm');

Alle Versionen der Datei C<lib/MetaData.pm> löschen:

  $scm->deleteVersion('lib/MetaData.pm',0);

Die Versionen bis 110 der Datei C<lib/MetaData.pm> löschen:

  $scm->deleteVersion('lib/MetaData.pm',110);

=cut

# -----------------------------------------------------------------------------

sub deleteVersion {
    my ($self,$repoFile,$version) = @_;

    my $output;

    if (!defined $version) {
        $version = $self->versionNumber($repoFile);
    }

    # Versionen selektieren

    my $tab = $self->findItem($repoFile,$version);
    my $count = $tab->count;

    if (!$count) {
        $self->throw(
            'CASCM-00099: Version does not exist',
            Version => $version,
            RepoFile => $repoFile,
        );
    }

    # Benutzer fragen, ob die Versionen wirklich gelöscht werden sollen

    print $tab->asTable(-info=>0);

    my $answ = Quiq::Terminal->askUser(
        $count == 1? 'Delete this version?': 'Delete these versions?',
        -values => 'y/n',
        -default => 'n',
    );
    if ($answ ne 'y') {
        return undef; # Abbruch
    }

    # Transportpaket erzeugen, falls nötig

    my $transportPackage;
    my @rows = reverse $tab->rows;
    for my $row (@rows) {
        if ($row->[6] ne $self->states->[0]) {
            my $name = Quiq::Converter->intToWord(time);
            $transportPackage = "S6800_0_Seitz_Lift_$name";
            $output .= $self->createPackage($transportPackage);
            last;
        }
    }

    # Versionen von höheren Stufen in Transportpackage zusammensammeln
    # und das Transportpackage auf die unterste Stufe bewegen

    if ($transportPackage) {
        my $transportPackageCount = 0;
        for my $row (@rows) {
            my $state = $row->[6];
            if ($state ne $self->states->[0]) {
                my $out = $self->movePackage($state,$transportPackage,
                    -askUser => $transportPackageCount,
                );
                if ($out) {
                    # Ab der 2. Bewegung fragen wir zurück
                    $transportPackageCount++;
                    $output .= $out;
                }

                # Version in Transportpackage bewegen
                # say sprintf '%s[%s] => %s',$state,$row->[3],$transportPackage;

                my $repoFile = $row->[1];
                my $package = $row->[5];
                my $version = $row->[3];

                $self->switchPackage($package,$transportPackage,
                    "$repoFile:$version");
            }
        }
        $self->movePackage($self->states->[0],$transportPackage);
    }

    # Alle zu löschenden Versionen befinden sich auf der untersten Stufe.
    # Wir löschen die Dateien.

    for my $row (@rows) {
        my $repoFile = $row->[1];

        my ($dir,$file) = Quiq::Path->split($repoFile);
        my $viewPath = $self->viewPath;

        my $c = Quiq::CommandLine->new;
        $c->addArgument($file);
        $c->addOption(
            $self->credentialsOptions,
            -b => $self->broker,
            -en => $self->projectContext,
            -vp => $dir? "$viewPath/$dir": $viewPath,
            # Löschen ist nur auf unterster Stufe möglích
            -st => $self->states->[0],
        );
        $output .= $self->runCmd('hdv',$c);
    }

    # Transportpaket löschen

    if ($transportPackage) {
        $output .= $self->deletePackages($transportPackage);
    }

    return $output;
}

# -----------------------------------------------------------------------------

=head3 passVersion() - Überhole die aktuelle mit der vorigen Version

=head4 Synopsis

  $output = $scm->passVersion($repoFile);

=head4 Arguments

=over 4

=item $repoFile

Der Pfad der zu löschenden Repository-Datei.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Erzeuge eine neue Version von $repoFile mit dem Stand I<vor> der aktuellen
Version. Dies ist nützlich, wenn an einem vorherigen Stand "vorbeigezogen"
werden soll.

=cut

# -----------------------------------------------------------------------------

sub passVersion {
    my ($self,$repoFile) = @_;

    my $output;

    my $p = Quiq::Path->new;

    # Aktuelle Version ermitteln

    my $version = $self->versionNumber($repoFile);
    if ($version == 0) {
        $self->throw(
            'CASCM-00099: Previous version does not exist',
            Version => $version,
            RepoFile => $repoFile,
        );
    }
    my $prevVersion = $version-1;

    # Vormaligen Stand holen

    my $tmpDir = $p->tempDir;
    my $file = $self->getVersion($repoFile,$version-1,$tmpDir,
        -sloppy => 1,
        -versionSuffix => 0,
    );
    my $prevPackage = $self->package($repoFile,$prevVersion);

    my ($repoDir) = $p->split($repoFile);
    return $self->putFiles($prevPackage,$repoDir,$file);
}

# -----------------------------------------------------------------------------

=head3 package() - Package einer Version

=head4 Synopsis

  $package = $scm->package($repoFile);
  $package = $scm->package($repoFile,$version);

=head4 Arguments

=over 4

=item $repoFile

Pfad der Repository-Datei (String).

=item $version

Version der Repository-Datei (Integer).

=back

=head4 Returns

=over 4

=item $package

Package-Name (String).

=back

=cut

# -----------------------------------------------------------------------------

sub package {
    my ($self,$repoFile,$version) = @_;

    my $projectContext = $self->projectContext;
    my $viewPath = $self->viewPath;

    if (!defined $version) {
        $version = $self->versionNumber($repoFile);
    }

    $repoFile =~ s|/dssweb/|/Dssweb/|; # Im Pfad auf der Db steht Dssweb

    my $tab = $self->runSql("
        SELECT
            package
        FROM (
            SELECT DISTINCT -- Warum ist hier DISTINCT nötig?
                itm.itemobjid AS id
                -- Warum ist /zenmod manchmal im Pfad?
                , REPLACE(SYS_CONNECT_BY_PATH(itm.itemname,'/'),'/zenmod','')
                    AS item_path
                , itm.itemtype AS item_type
                , ver.mappedversion AS version
                , ver.versiondataobjid
                , pkg.packagename AS package
                , sta.statename AS state
            FROM
                haritems itm
                JOIN harversions ver
                    ON ver.itemobjid = itm.itemobjid
                JOIN harpackage pkg
                    ON pkg.packageobjid = ver.packageobjid
                JOIN harenvironment env
                    ON env.envobjid = pkg.envobjid
                JOIN harstate sta
                    ON sta.stateobjid = pkg.stateobjid
                JOIN haritems par
                    ON par.itemobjid = itm.parentobjid
                JOIN harrepository rep
                    ON rep.repositobjid = itm.repositobjid
            WHERE
                env.environmentname = '$projectContext'
            START WITH
                itm.itemname = '$viewPath'
                AND itm.repositobjid = rep.repositobjid
            CONNECT BY
                PRIOR itm.itemobjid = itm.parentobjid
            ORDER BY
                item_path
                , TO_NUMBER(ver.mappedversion)
         )
         WHERE
             item_path LIKE '%$repoFile%'
             AND version = $version
    ");
    if ($tab->count == 0) {
        $self->throw(
            'CASCM-00099: Repository file or version does not exist',
            RepoFile => $repoFile,
            Version => $version,
        );
    }
    elsif ($tab->count > 1) {
        $self->throw(
            'CASCM-00099: Repository file plus version is not unique',
            RepoFile => $repoFile,
            Version => $version,
        );
    }

    return $tab->rows->[0][0];
}

# -----------------------------------------------------------------------------

=head3 findItem() - Zeige Information über Item an

=head4 Synopsis

  $tab = $scm->findItem($namePattern);
  $tab = $scm->findItem($namePattern,$minVersion);

=head4 Arguments

=over 4

=item $namePattern

Name des Item (File oder Directory), SQL-Wildcards sind erlaubt.
Der Name ist nicht verankert, wird intern also als '%$namePattern%'
abgesetzt.

=item $minVersion (Default: 0)

Die Item-Version muss mindestens $minVersion sein.

=back

=head4 Returns

=over 4

=item $tab

Ergebnismengen-Objekt.

=back

=cut

# -----------------------------------------------------------------------------

sub findItem {
    my $self = shift;
    my $namePattern = shift;
    my $minVersion = shift // 0;

    my $projectContext = $self->projectContext;
    my $viewPath = $self->viewPath;

    my $tab = $self->runSql("
        SELECT
            *
        FROM (
            SELECT DISTINCT -- Warum ist hier DISTINCT nötig?
                itm.itemobjid AS id
                -- Warum ist /zenmod manchmal im Pfad?
                , REPLACE(SYS_CONNECT_BY_PATH(itm.itemname,'/'),'/zenmod','')
                    AS item_path
                , itm.itemtype AS item_type
                , ver.mappedversion AS version
                , ver.versiondataobjid
                , pkg.packagename AS package
                , sta.statename AS state
            FROM
                haritems itm
                JOIN harversions ver
                    ON ver.itemobjid = itm.itemobjid
                JOIN harpackage pkg
                    ON pkg.packageobjid = ver.packageobjid
                JOIN harenvironment env
                    ON env.envobjid = pkg.envobjid
                JOIN harstate sta
                    ON sta.stateobjid = pkg.stateobjid
                JOIN haritems par
                    ON par.itemobjid = itm.parentobjid
                JOIN harrepository rep
                    ON rep.repositobjid = itm.repositobjid
            WHERE
                env.environmentname = '$projectContext'
            START WITH
                itm.itemname = '$viewPath'
                AND itm.repositobjid = rep.repositobjid
            CONNECT BY
                PRIOR itm.itemobjid = itm.parentobjid
            ORDER BY
                item_path
                , TO_NUMBER(ver.mappedversion)
         )
         WHERE
             item_path LIKE '%$namePattern%'
             AND version >= $minVersion
    ");

    # Wir entfernen den Anfang des View-Path,
    # da er für alle Pfade gleich ist

    for my $row ($tab->rows) {
        $row->[1] =~ s|^/\Q$viewPath\E/||;
    }

    return $tab;
}

# -----------------------------------------------------------------------------

=head3 removeItems() - Lösche Items

=head4 Synopsis

  $output = $scm->removeItems($package,@repoFile);

=head4 Arguments

=over 4

=item @repoFiles

Die Pfade der zu löschenden Repository-Dateien.

=item $package

Package, in das die Löschung eingetragen wird.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Erzeuge neue Versionen der Items @repoFiles, welche die Items als zu
Löschen kennzeichnen und trage diese in das Package $package ein.
Wird das Package promotet, werden die Items auf der betreffenden
Stufe gelöscht.

=cut

# -----------------------------------------------------------------------------

sub removeItems {
    my ($self,$package,@repoFiles) = @_;

    # FIXME: Dateien mit dem gleichen ViewPath mit
    # einem Aufruf behandeln (Optimierung).

    my $output;
    for my $repoFile (@repoFiles) {
        my ($dir,$file) = Quiq::Path->split($repoFile);
        my $viewPath = $self->viewPath;

        my $c = Quiq::CommandLine->new;
        $c->addArgument($file);
        $c->addOption(
            $self->credentialsOptions,
            -b => $self->broker,
            -en => $self->projectContext,
            -vp => $dir? "$viewPath/$dir": $viewPath,
            -st => $self->states->[0],
            -p => $package,
        );

        $output .= $self->runCmd('hri',$c);
    }

    return $output;
}

# -----------------------------------------------------------------------------

=head3 repoFileToFile() - Expandiere Repo-Pfad zu absolutem Pfad

=head4 Synopsis

  $file = $scm->repoFileToFile($repoFile);

=head4 Arguments

=over 4

=item $repoFile

Datei mit Repository-Pfadangabe.

=back

=head4 Returns

Pfad (String)

=head4 Description

Expandiere den Reository-Dateipfad zu einem absoluten Dateipfad
und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub repoFileToFile {
    my $self = shift;

    # Optionen und Argumente

    my $sloppy = 0;

    my $argA = $self->parameters(1,1,\@_,
        -sloppy => \$sloppy,
    );
    my $repoFile = shift @$argA;

    # Operation ausführen

    my $p = Quiq::Path->new;
    my $file = sprintf '%s/%s',$self->workspace,$repoFile;
    if (!$sloppy && !$p->exists($file)) {
        $self->throw(
            'CASCM-00099: Repository file does not exist',
            File => $file,
        );
    }

    return $file;
}

# -----------------------------------------------------------------------------

=head2 Packages

=head3 createPackage() - Erzeuge Package

=head4 Synopsis

  $output = $scm->createPackage($package);
  $output = $scm->createPackage($package,$state);

=head4 Arguments

=over 4

=item $package

Name des Package, das erzeugt werden soll.

=item $state (Default: I<unterste Stufe>)

State, auf dem das Package erzeugt werden soll.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Erzeuge Package $package auf Stufe $state und liefere die Ausgabe
des Kommandos zurück.

=cut

# -----------------------------------------------------------------------------

sub createPackage {
    my $self = shift;
    my $package = shift;
    my $state = shift // $self->states->[0];

    my $c = Quiq::CommandLine->new;
    $c->addArgument($package);
    $c->addOption(
        $self->credentialsOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -st => $self->states->[0],
    );
    my $output = $self->runCmd('hcp',$c);

    if ($state ne $self->states->[0]) {
        $output .= $self->movePackage($state,$package);
    }

    return $output;
}

# -----------------------------------------------------------------------------

=head3 deletePackages() - Lösche Package

=head4 Synopsis

  $output = $scm->deletePackages(@packages);

=head4 Arguments

=over 4

=item @package

Namen der Packages, die gelöscht werden sollwn.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Lösche die Packages @packages und liefere die Ausgabe der
Kommandos zurück.

=cut

# -----------------------------------------------------------------------------

sub deletePackages {
    my ($self,@packages) = @_;

    my $output = '';
    for my $package (@packages) {
        # Anmerkung: Das Kommando hdlp kann auch mehrere Packages auf
        # einmal löschen. Es ist jedoch nicht gut, es so zu
        # nutzen, da dann nicht-existente Packages nicht bemängelt
        # werden, wenn mindestens ein Package existiert. Daher löschen
        # wir hier jedes Paket einzeln.

        my $c = Quiq::CommandLine->new;
        $c->addOption(
            $self->credentialsOptions,
            -b => $self->broker,
            -en => $self->projectContext,
            -pkgs => $package,
        );

        $output .= $self->runCmd('hdlp',$c);
    }

    return $output;
}

# -----------------------------------------------------------------------------

=head3 renamePackage() - Benenne Package um

=head4 Synopsis

  $output = $scm->renamePackage($oldName,$newName);

=head4 Arguments

=over 4

=item $oldName

Bisheriger Name des Package.

=item $newName

Zukünftiger Name des Package.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Benenne Package $oldName in $newName um und liefere die Ausgabe
des Kommandos zurück.

=cut

# -----------------------------------------------------------------------------

sub renamePackage {
    my ($self,$oldName,$newName) = @_;

    my $c = Quiq::CommandLine->new;
    $c->addOption(
        $self->credentialsOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -p => $oldName,
        -npn => $newName,
    );

    return $self->runCmd('hup',$c);
}

# -----------------------------------------------------------------------------

=head3 showPackage() - Inhalt eines Package

=head4 Synopsis

  @rows | $tab = $scm->showPackage(@packages,@opt);

=head4 Returns

Datensätze oder Ergebnismengen-Objekt
(Quiq::Database::ResultSet::Array)

=head4 Description

Ermittele die in Package $package enthaltenen Items und ihrer Versions
und liefere diese Ergebnismenge zurück.

=head4 Example

  $scm->showPackage('S6800_0_Seitz_IMS_Obsolete_Files');
  =>
  1 id
  2 item_path
  3 item_type
  4 version
  5 versiondataobjid
  
  1         2                                         3   4    5
  | 4002520 | CPM_META/q07i101.cols.xml               | 1 |  1 | 5965056 |
  | 3992044 | CPM_META/q07i102.cols.xml               | 1 |  9 | 6017511 |
  | 4114775 | CPM_META/q07i105.cols.xml               | 1 |  2 | 6146470 |
  | 3992045 | CPM_META/q07i109.cols.xml               | 1 |  6 | 5968199 |
  | 3992046 | CPM_META/q07i113.cols.xml               | 1 |  6 | 5968200 |
  | 4233433 | CPM_META/q24i200shw.cpmload.xml         | 1 | 13 | 6327078 |
  | 4233434 | CPM_META/q24i200shw.flm.cpmload.xml     | 1 |  4 | 6318106 |
  | 4233435 | CPM_META/q24i210kumul.cpmload.xml       | 1 | 11 | 6327079 |
  | 4233436 | CPM_META/q24i210kumul.flm.cpmload.xml   | 1 |  4 | 6318108 |
  | 4233437 | CPM_META/q24i210risiko.cpmload.xml      | 1 | 13 | 6336633 |
  | 4233438 | CPM_META/q24i210risiko.flm.cpmload.xml  | 1 |  4 | 6318110 |
  | 4233439 | CPM_META/q24i210schaden.cpmload.xml     | 1 | 13 | 6327081 |
  | 4233440 | CPM_META/q24i210schaden.flm.cpmload.xml | 1 |  4 | 6318112 |
  | 4003062 | CPM_META/q33i001.cols.xml               | 1 |  3 | 5981911 |
  | 4003063 | CPM_META/q33i003.cols.xml               | 1 |  4 | 5981912 |
  | 4003064 | CPM_META/q33i005.cols.xml               | 1 |  3 | 5981913 |
  | 4003065 | CPM_META/q33i206.cols.xml               | 1 |  3 | 5981914 |
  | 4115111 | CPM_META/q44i912.cols.xml               | 1 |  2 | 6157279 |
  | 4144529 | CPM_META/q44i912.cpmload.xml            | 1 |  2 | 6318380 |
  | 4144530 | CPM_META/q44i912.flm.cpmload.xml        | 1 |  2 | 6318381 |
  | 4115112 | CPM_META/q44i913.cols.xml               | 1 |  3 | 6237929 |
  | 4115113 | CPM_META/q44i914.cols.xml               | 1 |  4 | 6249865 |
  | 4144531 | CPM_META/q44i914.cpmload.xml            | 1 |  7 | 6318382 |
  | 4144532 | CPM_META/q44i914.flm.cpmload.xml        | 1 |  2 | 6318383 |
  | 4095239 | CPM_META/q46i080.cpmload.xml            | 1 |  3 | 6327923 |
  | 4095240 | CPM_META/q46i080.flm.cpmload.xml        | 1 |  2 | 6318576 |
  | 4095550 | CPM_META/q46i081.cpmload.xml            | 1 |  3 | 6327924 |
  | 4095551 | CPM_META/q46i081.flm.cpmload.xml        | 1 |  2 | 6318578 |
  | 4095548 | CPM_META/q46i084.cpmload.xml            | 1 |  3 | 6327925 |
  | 4095549 | CPM_META/q46i084.flm.cpmload.xml        | 1 |  2 | 6318580 |
  | 4003101 | CPM_META/q80i102.cols.xml               | 1 |  4 | 5974529 |
  | 3936189 | ddl/table/q31i001.sql                   | 1 |  1 | 5885525 |
  | 3936190 | ddl/table/q31i002.sql                   | 1 |  1 | 5885526 |
  | 3936191 | ddl/table/q31i003.sql                   | 1 |  1 | 5885527 |
  | 3936192 | ddl/table/q31i004.sql                   | 1 |  1 | 5885528 |
  | 3936193 | ddl/table/q31i007.sql                   | 1 |  1 | 5885529 |
  | 3936194 | ddl/table/q31i014.sql                   | 1 |  1 | 5885530 |
  | 3936195 | ddl/table/q31i017.sql                   | 1 |  1 | 5885531 |
  | 4144537 | ddl/table/q44i912_cpm.sql               | 1 |  1 | 6163139 |
  | 4144538 | ddl/table/q44i914_cpm.sql               | 1 |  1 | 6163140 |
  | 3936311 | ddl/table/q65i001.sql                   | 1 |  1 | 5885647 |
  | 3936312 | ddl/table/q65i002.sql                   | 1 |  1 | 5885648 |
  | 3936313 | ddl/table/q65i003.sql                   | 1 |  1 | 5885649 |
  | 3936314 | ddl/table/q65i030.sql                   | 1 |  1 | 5885650 |
  | 4060343 | ddl/udf/rv_cpm_load_ims.sql             | 1 |  1 | 6038412 |
  | 4060442 | ddl/udf/rv_cpm_load_imsh.sql            | 1 |  2 | 6039389 |
  | 4060883 | ddl/udf/rv_cpm_load_imshr.sql           | 1 |  1 | 6039379 |

=cut

# -----------------------------------------------------------------------------

sub showPackage {
    my $self = shift;
    # @packages,@opt

    # Optionen und Argumente

    my $minVersion = 0;

    my $argA = $self->parameters(1,undef,\@_,
        -minVersion => \$minVersion,
    );
    my @packages = @$argA;

    my $projectContext = $self->projectContext;
    my $viewPath = $self->viewPath;
    my $packages = join ', ',map {"'$_'"} @packages;

    my $tab = $self->runSql("
        SELECT DISTINCT -- Warum ist hier DISTINCT nötig?
            itm.itemobjid AS id
            , SYS_CONNECT_BY_PATH(itm.itemname,'/') AS item_path
            , itm.itemtype AS item_type
            , ver.mappedversion AS version
            , ver.versiondataobjid
            , pkg.packagename
        FROM
            haritems itm
            JOIN harversions ver
                ON ver.itemobjid = itm.itemobjid
            JOIN harpackage pkg
                ON pkg.packageobjid = ver.packageobjid
            JOIN harenvironment env
                ON env.envobjid = pkg.envobjid
            /* JOIN harstate sta
                ON sta.stateobjid = pkg.stateobjid */
            JOIN haritems par
                ON par.itemobjid = itm.parentobjid
            JOIN harrepository rep
                ON rep.repositobjid = itm.repositobjid
        WHERE
            env.environmentname = '$projectContext'
            AND pkg.packagename IN ($packages)
            AND ver.mappedversion >= $minVersion
        START WITH
            itm.itemname = '$viewPath'
            AND itm.repositobjid = rep.repositobjid
        CONNECT BY
            PRIOR itm.itemobjid = itm.parentobjid
        ORDER BY
            item_path
            , TO_NUMBER(ver.mappedversion)
    ");

    # Wir entfernen den Anfang des View-Path,
    # da er für alle Pfade gleich ist

    for my $row ($tab->rows) {
        $row->[1] =~ s|^/\Q$viewPath\E/||;
    }

    return wantarray? $tab->rows: $tab;
}

# -----------------------------------------------------------------------------

=head3 switchPackage() - Übertrage Item in anderes Paket

=head4 Synopsis

  $output = $scm->switchPackage($fromPackage,$toPackage,@files);

=head4 Arguments

=over 4

=item $fromPackage

Name des Quellpakets (from package).

=item $toPackage

Name des Zielpakets (to package).

=item @files

Dateien (versions), die übertragen werden sollen.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Übertrage die Dateien @files von Paket $fromPackage in Paket $toPackage.

=cut

# -----------------------------------------------------------------------------

sub switchPackage {
    my ($self,$fromPackage,$toPackage,@files) = @_;

    my $output;

    # Ermittele die Stufen der Packages

    my $fromState = $self->packageState($fromPackage);
    my $toState = $self->packageState($toPackage);

    # Wenn die Stufen verschieden sind, bewegen wir die Items über
    # ein Transportpackage auf die Zielstufe

    my $transportPackage;
    if ($fromState ne $toState) {
        my $name = Quiq::Converter->intToWord(time);
        $transportPackage = "S6800_0_Seitz_Lift_$name";
        $output .= $self->createPackage($transportPackage,$fromState);
        $output .= $self->switchPackage($fromPackage,$transportPackage,@files);
        $output .= $self->movePackage($toState,$transportPackage,
            -askUser => 1,
        );
    }

    # Pfade müssen wir auf den Dateinamen reduzieren

    my $p = Quiq::Path->new;
    @files = map {$p->filename($_)} @files;

    # CASCM-Operation ausführen

    my $c = Quiq::CommandLine->new;
    $c->addOption(
        $self->credentialsOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -st => $toState,
        -fp => $transportPackage // $fromPackage,
        -tp => $toPackage,
    );
    $c->addBoolOption(
        -s => 1,
    );
    $c->addArgument(@files);

    $output .= $self->runCmd('hspp',$c);

    if ($transportPackage) {
        $output .= $self->deletePackages($transportPackage);
    }

    return $output;
}

# -----------------------------------------------------------------------------

=head3 promote() - Promote Packages

=head4 Synopsis

  $scm->promote($state,@packages);

=head4 Arguments

=over 4

=item $state

Stufe, auf dem sich die Packages befinden.

=item @packges

Packages, die promotet werden sollen.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Promote die Package @packages von der Stufe $state auf die
darüberliegende Stufe und liefere die Ausgabe des Kommandos zurück.

=cut

# -----------------------------------------------------------------------------

sub promote {
    my ($self,$state,@packages) = @_;

    my $c = Quiq::CommandLine->new;
    for my $package (@packages) {
        $c->addArgument($package);
    }
    $c->addOption(
        $self->credentialsOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -st => $state,
    );

    return $self->runCmd('hpp',$c);
}

# -----------------------------------------------------------------------------

=head3 demote() - Demote Packages

=head4 Synopsis

  $scm->demote($state,@packages);

=head4 Arguments

=over 4

=item $state

Stufe, auf dem sich das Package befindet.

=item @packages

Packages, die demotet werden sollen.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Demote die Packages @packages der Stufe $state auf die darunterliegende
Stufe, und liefere die Ausgabe des Kommandos zurück.

=cut

# -----------------------------------------------------------------------------

sub demote {
    my ($self,$state,@packages) = @_;

    my $c = Quiq::CommandLine->new;
    for my $package (@packages) {
        $c->addArgument($package);
    }
    $c->addOption(
        $self->credentialsOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -st => $state,
    );

    return $self->runCmd('hdp',$c);
}

# -----------------------------------------------------------------------------

=head3 movePackage() - Bringe Package auf Zielstufe

=head4 Synopsis

  $output = $scm->movePackage($state,$package,@opt);

=head4 Arguments

=over 4

=item $state

Stufe, auf die das Package gebracht werden soll.

=item $packge

Package, das bewegt werden soll.

=back

=head4 Options

=over 4

=item -askUser => $bool (Default: 0)

Frage den Benutzer, ob er die Post-Deployment-Bestätigung erhalten hat.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Bringe das Package $package von der aktuellen Stufe auf die Zielstufe
$state und liefere die Ausgabe des Kommandos zurück. Liegt die Zielstufe
über der aktuellen Stufe, wird das Package promotet, andernfalls demotet.

=cut

# -----------------------------------------------------------------------------

sub movePackage {
    my ($self,$state,$package) = splice @_,0,3;

    my $output = '';

    # Optionen

    my $askUser = 0;

    $self->parameters(\@_,
        -askUser => \$askUser,
    );

    my @states = $self->states;
    my $i = Quiq::Array->index(\@states,$state);
    if ($i < 0) {
        $self->throw(
            'CASCM-00099: State does not exist',
            State => $state,
        );
    }

    my $currState = $self->packageState($package);
    my $j = Quiq::Array->index(\@states,$currState);    

    my $op;
    if ($i > $j) {
        $op = 'promote';
        for (my $k = $j; $k < $i; $k++) {
            $output .= $self->promote($states[$k],$package);
        }
    } 
    elsif ($i < $j) {
        $op = 'demote';
        for (my $k = $j; $k > $i; $k--) {
            $output .= $self->demote($states[$k],$package);
        }
    } 
    else {
        # Kein Promote/Demote nötig
        return $output;
    }

    if ($askUser) {
        my $answ = Quiq::Terminal->askUser(
            sprintf("Package %s %sd?",$package,$op),
            -values => 'y',
            -default => 'y',
        );
        if ($answ ne 'y') {
            return undef; # Abbruch
        }
    }

    return $output;
}

# -----------------------------------------------------------------------------

=head3 packageState() - Stufe des Pakets

=head4 Synopsis

  $state = $scm->packageState($package);

=head4 Arguments

=over 4

=item $package

Package.

=back

=head4 Returns

=over 4

=item $state

Stufe.

=back

=head4 Description

Liefere die Stufe $state, auf der sich Package $package befindet.
Existiert das Package nicht, liefere einen Leerstring ('').

=cut

# -----------------------------------------------------------------------------

sub packageState {
    my ($self,$package) = @_;

    my $projectContext = $self->projectContext;

    my $tab = $self->runSql("
        SELECT
            sta.statename
        FROM
            harPackage pkg
            JOIN harEnvironment env
                ON env.envobjid = pkg.envobjid
            JOIN harState sta
                ON sta.stateobjid = pkg.stateobjid
        WHERE
            env.environmentname = '$projectContext'
            AND pkg.packagename = '$package'
    ");

    if ($tab->count == 0) {
        $self->throw(
            'CASCM-00099: Package does not exist',
            Package => $package,
        );
    }

    # return $tab->count? $tab->rows->[0]->[0]: '';
    return $tab->rows->[0]->[0];
}

# -----------------------------------------------------------------------------

=head3 listPackages() - Liste aller Pakete

=head4 Synopsis

  $tab = $scm->listPackages;

=head4 Returns

=over 4

=item @packages | $packageA

Liste aller Packages (Array of Arrays). Im Skalarkontext eine Referenz
auf die Liste.

=back

=head4 Description

Liefere die Liste aller Packages.

=cut

# -----------------------------------------------------------------------------

sub listPackages {
    my $self = shift;

    my $projectContext = $self->projectContext;

    return $self->runSql("
        SELECT
            pkg.packagename
            , sta.statename
        FROM
            harPackage pkg
            JOIN harEnvironment env
                ON pkg.envobjid = env.envobjid
            JOIN harState sta
                ON pkg.stateobjid = sta.stateobjid
        WHERE
            env.environmentname = '$projectContext'
        ORDER BY
            1
    ");
}

# -----------------------------------------------------------------------------

=head2 Workspace

=head3 sync() - Synchronisiere Workspace mit Repository

=head4 Synopsis

  $scm->sync;

=head4 Description

Bringe den Workspace auf den Stand des Repository und liefere
die Ausgabe des Kommandos zurück.

=cut

# -----------------------------------------------------------------------------

sub sync {
    my $self = shift;

    my $c = Quiq::CommandLine->new;
    $c->addOption(
        $self->credentialsOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -vp => $self->viewPath,
        -cp => $self->workspace,
        -st => $self->states->[0],
    );

    return $self->runCmd('hsync',$c);
}

# -----------------------------------------------------------------------------

=head2 States

=head3 states() - Liste der Stufen

=head4 Synopsis

  @states | $stateA = $scm->states;

=cut

# -----------------------------------------------------------------------------

sub states {
    my $self = shift;

    my $stateA = $self->{'states'};
    return wantarray? @$stateA: $stateA;
}

# -----------------------------------------------------------------------------

=head2 Database

=head3 sql() - Führe SQL aus

=head4 Synopsis

  $tab = $scm->sql($sql);
  $tab = $scm->sql($file);

=head4 Arguments

=over 4

=item $sql

SELECT-Statement.

=item $file

Datei mit SELECT-Statement.

=back

=head4 Returns

Ergebnismengen-Objekt (Quiq::Database::ResultSet::Array)

=head4 Description

Führe ein SELECT-Statement gegen die CASCM-Datenbank aus und liefere
ein Ergebnismengen-Objekt zurück. Das SELECT-Statement kann als
String $sql übergeben werden oder sich in einer Datei $file befinden.

=cut

# -----------------------------------------------------------------------------

sub sql {
    my $self = shift;
    my $sql = $_[0] =~ /\s/? $_[0]: Quiq::Path->read($_[0]);

    return $self->runSql($sql);
}

# -----------------------------------------------------------------------------

=head2 Private Methoden

=head3 credentialsOptions() - Credential-Optionen

=head4 Synopsis

  @arr = $scm->credentialsOptions;

=head4 Description

CASCM kennt mehrere Authentisierungsmöglichkeiten, die sich durch
Aufrufoptionen unterscheiden. Diese Methode liefert die passenden Optionen
zu den beim Konstruktor-Aufruf angegebenen Authentisierungs-Informationen.
unterschieden werden:

=over 4

=item 1.

Authentisierung durch Datei mit verschlüsselten Credentials (-eh)

=item 2.

Authentisiertung durch Benutzername/Passwor (-usr, -pw)

=back

Bevorzugt ist Methode 1, da sie sicherer ist als Methode 2.

=cut

# -----------------------------------------------------------------------------

sub credentialsOptions {
    my $self = shift;
    my $cmd = shift // '';

    my $credentialsFile;
    if ($cmd eq 'hsql' && (my $file = $self->get("${cmd}CredentialsFile"))) {
        $credentialsFile = $file;
    }
    $credentialsFile ||= $self->credentialsFile;
    if ($credentialsFile) {
        return (-eh=>$credentialsFile);
    }

    return $credentialsFile?
        (-eh=>Quiq::Path->expandTilde($credentialsFile)):
        (-usr=>$self->user,-pw=>$self->password);
}

# -----------------------------------------------------------------------------

=head3 runCmd() - Führe Kommando aus

=head4 Synopsis

  $output = $scm->runCmd($cmd,$c);

=head4 Arguments

=over 4

=item $cmd

Name des CASCM-Kommandos

=item $c

Kommandozeilenobjekt mit den Optionen.

=back

=head4 Returns

=over 4

=item $output

Inhalt der Ausgabedatei, die das Kommando geschrieben hat.

=back

=head4 Description

Führe das CA Harvest SCM Kommando $cmd mit den Optionen des
Kommandozeilenobjekts $c aus und liefere den Inhalt der Ausgabedatei
zurück.

=cut

# -----------------------------------------------------------------------------

sub runCmd {
    my ($self,$cmd,$c) = @_;

    my $stw = Quiq::Stopwatch->new;

    # Output-Datei zu den Optionen hinzufügen

    my $outputFile = Quiq::TempFile->new(-unlink=>!$self->keepTempFiles);
    $c->addOption(-o=>$outputFile);

    # Kommando ausführen. Das Kommando schreibt Fehlermeldungen nach
    # stdout (!), daher leiten wir stdout in die Output-Datei um.
    # MEMO: Erstmal abgeschaltet, um es auf das spezifische Kommando
    # einzuschränken

    # my $cmdLine = sprintf '%s %s >>%s',$cmd,$c->command,$outputFile;
    my $cmdLine = sprintf '%s %s',$cmd,$c->command;
    my $r = $self->sh->exec($cmdLine,-sloppy=>1);
    my $output = Quiq::Path->read($outputFile);
    if ($r) {
        if ($cmd eq 'hlv' && $output =~ /Invalid Version List/) {
            my ($file) = $cmdLine =~ m|^hlv (.*?) |;
            my ($dir) = $cmdLine =~ m|-vp .*?/(.*?) |;
            if ($dir) {
                $file = "$dir/$file";
            }            
            $self->throw(
                'CASCM-00001: Repository file not found',
                File => $file,
            );
        }

        $self->throw(
            'CASCM-00001: Command failed',
            Command => $cmdLine,
            Output => $output,
        );
    }

    # Wir liefern den Inhalt der Output-Datei zurück

    if ($cmd ne 'hsql') {
        $output .= sprintf "---\n%.2fs\n",$stw->elapsed;
    }

    return $output;
}

# -----------------------------------------------------------------------------

=head3 runSql() - Führe SQL-Statement aus

=head4 Synopsis

  $tab = $scm->runSql($sql);

=head4 Arguments

=over 4

=item $sql

SELECT-Statement, das gegen die CASCM-Datenbank abgesetzt wird.

=back

=head4 Returns

Ergebnismengen-Objekt (Quiq::Database::ResultSet::Array)

=head4 Description

Führe SELECT-Statement $sql auf der CASCM-Datenbank aus und liefere
die Ergebnismenge zurück. Ist ein UDL definiert (s. Konstruktoraufruf)
wird die Selektion direkt auf der Datenbank ausgeführt, andernfalls
über das CASCM-Kommando hsql.

=cut

# -----------------------------------------------------------------------------

sub runSql {
    my ($self,$sql) = @_;

    my $stw = Quiq::Stopwatch->new;

    my $udl = $self->udl;

    $sql = Quiq::Unindent->trimNl($sql);
    if ($self->verbose > 1) {
        my $a = $self->a;
        (my $sql = $sql) =~ s/^(.*)/'> '.$a->str('bold',$1)/meg;
        if (!$udl) {
            $sql .= "\n";
        }
        warn $sql;
    }    

    if ($udl) {
        # Wenn ein UDL definiert ist, selektieren wir direkt
        # von der Datenbank. Beim ersten Zugriff bauen wir
        # die Verbindung auf.


        my $db = $self->db;
        if (!$db) {
            $db = Quiq::Database::Connection->new($udl,-utf8=>1);
            $self->set(db=>$db);
        }
        return scalar $db->select($sql,-raw=>1);
    }

    # Wir haben keine direkte Verbindung zur Datenbank,
    # sondern nutzen hsql

    my $sqlFile = Quiq::TempFile->new(-unlink=>!$self->keepTempFiles);
    Quiq::Path->write($sqlFile,$sql);

    my $c = Quiq::CommandLine->new;
    $c->addOption(
        $self->credentialsOptions('hsql'),
        -b => $self->broker,
        -f => $sqlFile,
    );
    $c->addBoolOption(
        -t => 1,  # tabellarische Ausgabe
    );

    my $output = $self->runCmd('hsql',$c);

    # Wir liefern ein Objekt mit Titel und Zeilenobjekten zurück
    # <NL> und <TAB> ersetzen wir in den Daten durch \n bzw. \t.

    my @rows = map {s/<NL>/\n/g; $_} split /\n/,$output;
    my @titles = map {lc} split /\t/,shift @rows;

    my $rowClass = 'Quiq::Database::Row::Array';
    my $width = @titles;

    for my $row (@rows) {
        $row = $rowClass->new(
            [map {s/<TAB>/\t/g; $_} split /\t/,$row,$width]);
    }

    return Quiq::Database::ResultSet::Array->new($rowClass,\@titles,\@rows,
        execTime => $stw->elapsed,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.172

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2020 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
