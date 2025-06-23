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

=cut

# -----------------------------------------------------------------------------

package Quiq::Cascm;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;
use utf8;

our $VERSION = '1.228';

use Quiq::Database::Row::Array;
use Quiq::AnsiColor;
use Quiq::Shell;
use Quiq::Terminal;
use Quiq::Path;
use Quiq::Converter;
use Quiq::CommandLine;
use Quiq::TempDir;
use Quiq::Array;
use Quiq::Stopwatch;
use Quiq::TempFile;
use Quiq::Unindent;
use Quiq::Database::Connection;
use Quiq::Database::ResultSet::Array;

# -----------------------------------------------------------------------------

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

=item color => $bool (Default: 1)

Schreibe Ausgabe mit ANSI Colorcodes.

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
        color => 1,
        dryRun => 0,
        verbose => 1,
        # Private Attribute
        db => undef,                  # wenn DB-Zugriff über UDL
        sh => undef,
        a => undef,
        @_,
    );
    $self->set(a=>Quiq::AnsiColor->new(-t STDOUT && $self->color? 1: 0));

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
        !$self->color? (): (cmdAnsiColor => 'bold'),
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
        my $package = $row->[2];
        my $item = $row->[0];
        my $version = $row->[1];

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

  $output = $scm->edit($repoFile,$package);
  $output = $scm->edit($repoFile,$package,$version);

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

=item $version (Default: I<aktuelle Version>)

=back

=head4 Returns

Ausgabe der CASCM-Kommandos (String)

=head4 Description

Checke die Repository-Datei $repoFile aus und lade Version $version
in den Editor. Wird die Datei bearbeitet, d.h. nach dem Verlassen
des Editors ist ihr Inhalt ein anderer als vorher, wird dieser Stand
(nach Rückfage) als neue Version eingecheckt. Andernfalls wird
ohne Änderung eingecheckt, wobei die Vergabe einer neuen Versionsnummer
unterbleibt.

Das Editieren einer älteren Version kann genutzt werden,
um eine in Arbeit befindliche Version zu übergehen. Ein weiteres Mal
auf die zuvor aktuelle Version angewandt, kann die aktuelle Version
wieder reaktiviert werden.

=head4 Example

Bearbeite eine ältere Version, so dass diese vor der unfertigen
aktuellen Version promotet werden kann.

Aktueller Stand:

  $ $ dss-repo find-item DATEI
  1 item_path
  2 version
  3 package
  4 state
  5 creationtime
  6 username
  
  1            2   3                           4             5                     6
  | DATEI | 0 | PACKAGE1 | Produktion  | 2020-02-27 14:05:30 | xv882js |
  | DATEI | 1 | PACKAGE2 | TTEST       | 2020-02-27 14:06:16 | xv882js |

Alte Version editieren und zur neusten Version machen:

  $ dss-repo create PACKAGE3
  $ dss-repo edit DATEI PACKAGE3 0

Nächster Stand:

  $ $ dss-repo find-item DATEI
  1 item_path
  2 version
  3 package
  4 state
  5 creationtime
  6 username
  
  1            2   3                           4             5
  | DATEI | 0 | PACKAGE1 | Produktion  | 2020-02-27 14:05:30 | xv882js |
  | DATEI | 1 | PACKAGE2 | TTEST       | 2020-02-27 14:06:16 | xv882js |
  | DATEI | 2 | PACKAGE3 | Entwicklung | 2020-02-27 14:08:45 | xv882js |

Die in PACKAGE3 befindliche bearbeitete Version 2, die aus Version 0
hervorgegangen ist, kann nach Produktion promotet werden ohne den
unfertigen Code aus Version 1.

Unfertigen Stand wieder zum aktuellen Stand machen, u.U. mit den
gleichen vormaligen Änderungen:

  $ dss-repo edit DATEI PACKAGE2 1

Nächster Stand:

  $ dss-repo find-item DATEI
  1 item_path
  2 version
  3 package
  4 state
  5 creationtime
  6 username
  
  1            2   3                           4             5
  | DATEI | 0 | PACKAGE1 | Produktion  | 2020-02-27 14:05:30 | xv882js |
  | DATEI | 1 | PACKAGE2 | TTEST       | 2020-02-27 14:06:16 | xv882js |
  | DATEI | 2 | PACKAGE3 | Entwicklung | 2020-02-27 14:08:45 | xv882js |
  | DATEI | 2 | PACKAGE2 | TTEST       | 2020-02-27 14:10:45 | xv882js |

=cut

# -----------------------------------------------------------------------------

sub edit {
    my ($self,$repoFile,$package) = splice @_,0,3;

    # Optionen und Argumente

    my $show = undef;
    my $version = undef;

    $self->parameters(\@_,
        -show => \$show,
        -version => \$version,
    );

    my $output = '';

    # Information über die Versionen der Datei ausgeben
    print $self->findItem($repoFile)->asTable(-info=>2);

    my $answ = Quiq::Terminal->askUser('Continue?',
        -values => 'y/n',
        -default => 'y',
    );
    if ($answ ne 'y') {
        return $output;
    }

    my $p = Quiq::Path->new;

    # Vollständigen Pfad der Repository-Datei ermitteln
    my $file = $self->repoFileToFile($repoFile);

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

    my $tmpDir = '~/tmp/cascm/';

    # Checke Datei aus
    $output .= $self->checkout($transportPackage || $package,$repoFile);

    # Lokale Kopie der Datei erstellen

    my $localFile;
    if (defined($version)) {
        $localFile = $self->getVersion($repoFile,$version,$tmpDir);
    }
    else {
        $localFile = $tmpDir.'/'.$p->filename($file);
        $p->copy($file,$localFile,-createDir=>1);
    }

    # Backup-Datei erstellen für den Vergleich nach
    # dem Verlassen des Editors

    my $backupFile = "$localFile.bak";
    $p->copy($localFile,$backupFile);

    my $fileChanged = 0;
    my $editCmd = "emacs -nw $localFile";
    if ($show) {
        # $editCmd .= " -f split-window-horizontally $show -f other-window";
        $editCmd .= " -f split-window-vertically $show -f other-window";
    }
    my $sh = Quiq::Shell->new(
        log =>1 ,
        cmdPrefix => '> ',
        cmdAnsiColor => 'bold',
    );
    while (1) {
        $sh->exec($editCmd);
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
        else {
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

=head4 Options

=over 4

=item -force => $bool (Default: 0)

Prüfe nicht, ob hinzugefügte Datei und Repository-Datei identisch sind.

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
    my $self = shift;

    # Optionen und Argumente

    my $force = 0;

    my $argA = $self->parameters(3,undef,\@_,
        -force => \$force,
    );
    my ($package,$repoDir,@files) = @$argA;

    # Operation ausführen

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

            if (!$force && !$p->compare($srcFile,"$workspace/$repoFile")) {
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
        $output .= $self->movePackage($state,$transportPackage,-askUser=>1);
        $output .= $self->switchPackage($transportPackage,$package,@items);
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

  $bool = $scm->deleteVersion($repoFile);
  $bool = $scm->deleteVersion($repoFile,$version);

=head4 Arguments

=over 4

=item $repoFile

Der Pfad der zu löschenden Repository-Datei.

=item $version (Default: I<höchste Versionsnummer>)

Version der Datei, die gelöscht werden soll.

=back

=head4 Returns

Wahrheitswert: 1, wenn Löschung ausgeführt wurde, andernfalls 0.

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
        -default => 'y',
    );
    if ($answ ne 'y') {
        return 0; # Abbruch
    }

    # Transportpaket erzeugen, falls nötig

    my $transportPackage;
    my @rows = reverse $tab->rows;
    for my $row (@rows) {
        if ($row->[3] ne $self->states->[0]) {
            my $name = Quiq::Converter->intToWord(time);
            $transportPackage = "S6800_0_Seitz_Lift_$name";
            $self->createPackage($transportPackage);
            last;
        }
    }

    # Versionen von höheren Stufen in Transportpackage zusammensammeln
    # und das Transportpackage auf die unterste Stufe bewegen

    if ($transportPackage) {
        my $transportPackageCount = 0;
        for my $row (@rows) {
            my $state = $row->[3];
            if ($state ne $self->states->[0]) {
                my $out = $self->movePackage($state,$transportPackage,
                    -askUser => $transportPackageCount,
                );
                if ($out) {
                    # Ab der 2. Bewegung fragen wir zurück
                    $transportPackageCount++;
                }

                # Version in Transportpackage bewegen
                # say sprintf '%s[%s] => %s',$state,$row->[3],$transportPackage;

                my $repoFile = $row->[0];
                my $package = $row->[2];
                my $version = $row->[1];

                $self->switchPackage($package,$transportPackage,
                    "$repoFile:$version");
            }
        }
        $self->movePackage($self->states->[0],$transportPackage);
    }

    # Alle zu löschenden Versionen befinden sich auf der untersten Stufe.
    # Wir löschen die Dateien.

    for my $row (@rows) {
        my $repoFile = $row->[0];

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
        $self->runCmd('hdv',$c);
    }

    # Transportpaket löschen

    if ($transportPackage) {
        $self->deletePackages($transportPackage);
    }

    return 1;
}

# -----------------------------------------------------------------------------

=head3 passVersion() - Überhole die aktuelle mit älterer Version

=head4 Synopsis

  $output = $scm->passVersion($repoFile,$version,$package);

=head4 Arguments

=over 4

=item $repoFile

Der Pfad der zu löschenden Repository-Datei.

=item $version

Ältere Version, die die neuere Version überholen soll.

=item $package

Package, dem die neue ältere Version hinzugefügt wird.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Erzeuge eine neue Version von $repoFile mit der älteren Version $version
und füge diese zu Package $package hinzu. Dies ist nützlich, wenn an der
aktuellen Version vorbeigezogen werden soll.

=cut

# -----------------------------------------------------------------------------

sub passVersion {
    my ($self,$repoFile,$version,$package) = @_;

    my $p = Quiq::Path->new;

    # Alten Stand holen und in temporärer Datei speichern

    my $tmpDir = $p->tempDir;
    my $file = $self->getVersion($repoFile,$version,$tmpDir,
        -sloppy => 1,
        -versionSuffix => 0,
    );

    my ($repoDir) = $p->split($repoFile);
    return $self->putFiles($package,$repoDir,$file);
}

# -----------------------------------------------------------------------------

=head3 reduceVersion() - Mache die neueste Version zu früherer Version

=head4 Synopsis

  $output = $scm->reduceVersion($repoFile,$version);

=head4 Arguments

=over 4

=item $repoFile

Der Pfad der Repository-Datei.

=item $version

Versionsnummer, auf die die neuste Version zurückgeführt werden soll.

=back

=head4 Returns

Boolean. 1, wenn Operation ausgeführt wurde, sonst 0. 0 wird geliefert,
wenn der Nutzer die Rückfrage nach der Löschung der Dateien mit
"nein" beantwortet.

=head4 Description

Sichere den Quelltext der neusten Version, lösche alle Versionen bis
und einschließlich Version $version und checke den gesicherten Quelltext
ein. Der Ergebnis ist, dass die neuste Version zu Version $version wird.

=cut

# -----------------------------------------------------------------------------

sub reduceVersion {
    my ($self,$repoFile,$version) = @_;

    my $p = Quiq::Path->new;

    # Höchste Versionsnummer der Datei ermitteln

    my $repoVersion = $self->versionNumber($repoFile);
    if ($version >= $repoVersion) {
        # Es ist nichts zu tun
        return 0;
    }

    # Package der neusten Version ermitteln. In diesem Package
    # wird auch die neuerzeugte frühere Version abgelegt.

    my $package = $self->package($repoFile,$repoVersion);

    # Datei der neusten Version sichern

    my $tmpDir = '~/tmp/cascm';
    my $file = $self->getVersion($repoFile,$repoVersion,$tmpDir,
        -sloppy => 1,
        -versionSuffix => 0,
    );

    # Alle Versionen bis $version löschen

    my $bool = $self->deleteVersion($repoFile,$version);
    if ($bool) {
        # Repository-Verzeichnis der Datei
        my ($repoDir) = $p->split($repoFile);

        # Gesicherte Datei zum Repository hinzufügen
        $self->putFiles(-force=>1,$package,$repoDir,$file);
    }

    # Gesicherte Datei löschen
    $p->delete($file);

    return 1;
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
                -- itm.itemobjid AS id
                -- Warum ist /zenmod manchmal im Pfad?
                REPLACE(SYS_CONNECT_BY_PATH(itm.itemname,'/'),'/zenmod','')
                    AS item_path
                -- , itm.itemtype AS item_type
                , ver.mappedversion AS version
                -- , ver.versiondataobjid
                , pkg.packagename AS package
                , sta.statename AS state
                , ver.creationtime
                , usr.username
                , ver.versionstatus
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
                JOIN harallusers usr
                    ON usr.usrobjid = ver.creatorid
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
        $row->[0] =~ s|^/\Q$viewPath\E/||;
    }

    return $tab;
}

# -----------------------------------------------------------------------------

=head3 moveItem() - Verschiebe Repository-Datei in ein anderes Verzeichnis

=head4 Synopsis

  $output = $scm->moveItem($repoFile,$repoDir,$removePackage,$putPackage);

=head4 Arguments

=over 4

=item $repoFile

Repository-Pfad der Datei, die verschoben werden soll.

=item $repoDir

Repository-Pfad des Ziel-Verzeichnisses. Dieses Verzeichnis muss
bereits existieren.

=item $removePackage

Package, das die per removeItem() entfernte Datei aufnimmt.

=item $removePackage

Package, das die per putFiles() hinzugefügte Datei aufnimmt.

=back

=head4 Returns

Ausgabe der Kommandos (String)

=head4 Description

Entferne Datei $repoFile aus dem Repository und füge sie unter
dem neuen Repository-Pfad $repoDir wieder zum Repository hinzu.
Verschiebe sie also innerhalb der Repository-Verzeichnisstruktur. Die
entfernte Datei wird zu Package $removePackage hinzugefügt und die
neue Datei zu Package $putPackage.

=cut

# -----------------------------------------------------------------------------

sub moveItem {
    my ($self,$repoFile,$repoDir,$removePackage,$putPackage) = @_;

    my $p = Quiq::Path->new;

    # Repository-Information
    my $workspace = $self->workspace;

    # Prüfe, ob Zielverzeichnis exisitert

    my $destDir = "$workspace/$repoDir";
    if (!$p->exists($destDir)) {
            $self->throw(
                'CASCM-00099: Destination directory does not exist',
                Dir => $destDir,
            );
    }

    # Prüfe, ob Put-Package existiert
    $self->packageState($putPackage);

    my $output;

    # Entferne Datei unter altem Pfad aus Repository
    $output = $self->removeItems($removePackage,$repoFile);

    # Füge Datei unter neuem Pfad zum repository hinzu

    my $srcFile = "$workspace/$repoFile";
    $output .= $self->putFiles($putPackage,$repoDir,$srcFile);

    # Ursprüngliche Repository-Datei entfernen
    $p->delete($srcFile);

    return $output;
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

    my $output;

    # FIXME: Dateien mit dem gleichen ViewPath mit
    # einem Aufruf behandeln (Optimierung).

    my $state = $self->packageState($package);

    # Erzeuge ein Transportpackage, falls sich das Zielpackage
    # nicht auf der untersten Stufe befindet

    my $transportPackage;
    if ($state ne $self->states->[0]) {
        my $name = Quiq::Converter->intToWord(time);
        $transportPackage = "S6800_0_Seitz_Lift_$name";
        $output .= $self->createPackage($transportPackage);
    }

    my @items;
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
            -p => $transportPackage || $package,
        );

        $output .= $self->runCmd('hri',$c);

        # Liste der Items im Packate (nur relevant
        # im Falle eines Transportpackage)
        push @items,$file;
    }

    if ($transportPackage) {
        $output .= $self->movePackage($state,$transportPackage,-askUser=>1);
        $output .= $self->switchPackage($transportPackage,$package,@items);
        $output .= $self->deletePackages($transportPackage);
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

=head3 showPackage() - Inhalt von Packages

=head4 Synopsis

  @rows | $tab = $scm->showPackage(@packages,@opt);

=head4 Returns

Datensätze oder Ergebnismengen-Objekt
(Quiq::Database::ResultSet::Array)

=head4 Description

Ermittele die in den Packages @packages enthaltenen Items und
ihrer Versions und liefere diese Ergebnismenge zurück.

=head4 Example

  $scm->showPackage('S6800_0_Seitz_IMS_Obsolete_Files');
  =>
  1 item_path
  2 version
  3 package_name
  4 creation_time
  5 username
  6 versionstatus

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
            -- itm.itemobjid AS id
            SYS_CONNECT_BY_PATH(itm.itemname,'/') AS item_path
            -- , itm.itemtype AS item_type
            , ver.mappedversion AS version
            -- , ver.versiondataobjid
            , pkg.packagename
            , ver.creationtime
            , usr.username
            , ver.versionstatus
        FROM
            haritems itm
            JOIN harversions ver
                ON ver.itemobjid = itm.itemobjid
            JOIN harallusers usr
                ON usr.usrobjid = ver.creatorid
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
        $row->[0] =~ s|^/\Q$viewPath\E/||;
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

=item @files (Default: I<alle Dateien>)

Dateien (versions), die übertragen werden sollen.

=back

=head4 Returns

Ausgabe des Kommandos (String)

=head4 Description

Übertrage die Dateien @files von Paket $fromPackage in Paket $toPackage.
Sind keine Dateien angegeben, übertrage alle Dateien aus $fromPackage.

Per Default werden I<alle> Versionen einer Datei übertragen. Soll eine
bestimmte Version übertragen werden, wird der Suffix :VERSION an
den Dateinamen angehängt.

=cut

# -----------------------------------------------------------------------------

sub switchPackage {
    my ($self,$fromPackage,$toPackage,@files) = @_;

    my $output;

    # Sind keine Dateien angegeben, beziehen wir
    # die Liste der Dateien aus dem Quellpaket. Wir transferieren
    # dann also alle Dateien.

    if (!@files) {
        for my $row ($self->showPackage($fromPackage)) {
            push @files,$row->[0];
        }
    }

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

  $tab = $scm->listPackages(@opt);
  $tab = $scm->listPackages($likePattern,@opt);

=head4 Arguments

=over 4

=item $likePattern

Schränke die Liste auf Packages ein, deren Name $likePattern matchen.

=back

=head4 Options

=over 4

=item -order => 'package'|'username'|'time' (Default: 'time')

Sortierkriterium.

=back

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
    # @_: $likePattern,@opt

    # Optionen

    my $order = 'time';

    my $argA = $self->parameters(0,1,\@_,
        -order => \$order,
    );
    my $likePattern = shift(@$argA) // '';

    # Operation ausführen

    my $projectContext = $self->projectContext;

    return $self->runSql("
        SELECT
            pkg.packagename AS package
            , sta.statename AS stage
            , pkg.creationtime AS time
            , usr.username AS username
        FROM
            harPackage pkg
            JOIN harEnvironment env
                ON pkg.envobjid = env.envobjid
            JOIN harState sta
                ON pkg.stateobjid = sta.stateobjid
            JOIN harallusers usr
                ON usr.usrobjid = pkg.creatorid
        WHERE
            env.environmentname = '$projectContext'
            AND pkg.packagename LIKE '%$likePattern%'
        ORDER BY
            $order
    ");
}

# -----------------------------------------------------------------------------

=head2 Workspace

=head3 sync() - Synchronisiere Workspace-Verzeichnis mit Repository

=head4 Synopsis

  $scm->sync;
  $scm->sync($repoDir);

=head4 Arguments

=over 4

=item $repoDir (Default: I<Wurzelverzeichns des Workspace>)

Zu synchronisierendes Workspace-Verzeichnis.

=back

=head4 Description

Bringe das Workspace-Verzeichnis $repoDir auf den Stand des Repository
und liefere die Ausgabe des Kommandos zurück. Ist kein Verzeichnis
angegeben, aktualisiere den gesamten Workspace.

=cut

# -----------------------------------------------------------------------------

sub sync {
    my ($self,$repoDir) = @_;

    my $viewPath = $self->viewPath;
    my $clientPath = $self->workspace;
    if ($repoDir) {
        $viewPath .= "/$repoDir";
        $clientPath .= "/$repoDir";
    }

    my $c = Quiq::CommandLine->new;
    $c->addOption(
        $self->credentialsOptions,
        -b => $self->broker,
        -en => $self->projectContext,
        -vp => $viewPath,
        -cp => $clientPath,
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
