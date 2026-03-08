# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::KositValidator - Validator für XRechnungen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Der Validator ist eine Zusammenstellung aus Java-Code und
Schematron-Dateien zur Validierung von XRechnungs-XML.

Der Validator ist im jeweils aktuellen "XRechnung Bundle" enhalten,
welcher von L<XRechnung Versionen und Bundles|https://xeinkauf.de/xrechnung/versionen-und-bundles/>
heruntergeladen werden kann.

=over 4

=item 1.

Bundle herunterladen und entpacken

  $ mkdir xrechnung-3.0.2-bundle-2025-07-10
  $ cd xrechnung-3.0.2-bundle-2025-07-10
  $ unzip ../xrechnung-3.0.2-bundle-2025-07-10.zip

=item 2.

KoSIT-Validator aus dem Bundle heraus entpacken und installieren

Beispiel-Verzeichnis ist C<~/sys/opt/kosit-validator>, dieses kann
aber frei gewählt werden.

  $ mkdir ~/sys/opt/kosit-validator
  $ cd ~/sys/opt/kosit-validator
  $ unzip .../validator-1.5.0-distribution.zip
  $ unzip .../validator-configuration-xrechnung_3.0.2_2025-07-10.zip

=item 3.

KoSIT-Validator testen

Eine Beispiel-Datei C<ubl.xml> wird zum Herunterladen in
C<kosit-validator/docs/usage.md> erwähnt.

  $ perl -MQuiq::KositValidator -E '$kvl = Quiq::KositValidator->new("~/sys/opt/kosit-validator");say $kvl->validate("ubl.xml")'

Es kann z.B. auch eine EN16931 ZUGFeRD XML-Datei validiert werden.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::KositValidator;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.236';

use Quiq::Path;
use Quiq::Shell;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $kvl = $class->new($validatorDir,%options);

=head4 Arguments

=over 4

=item $validatorDir

Verzeichnis mit den zum Validator gehörenden Dateien

=back

=head4 Options

=over 4

=item -javaDir => $javaDir (Default: undef)

Verzeichns mit dem Programm C<java>. Beispiel: C</opt/jdk/bin>

=back

=head4 Returns

Validator-Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;

    # Optionen und Argumente

    my $javaDir = undef;

    my $argA = $class->parameters(1,1,\@_,
        -javaDir => \$javaDir,
    );
    my $validatorDir = shift @$argA;

    # Führe Operation aus

    if (!Quiq::Path->exists($validatorDir)) {
        $class->throw(
            'MUSTANG-00099: Directory does not exists',
            ValidatorDir => $validatorDir,
        );
    }

    my $javaExe = 'java';
    if ($javaDir) {
        $javaExe = "$javaDir/$javaExe";
    }

    return $class->SUPER::new(
        validatorDir => $validatorDir,
        javaExe => $javaExe,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 validate() - Validiere XRechnungs-XML

=head4 Synopsis

  $status = $kvl->validate($xmlFile,%options);

=head4 Arguments

=over 4

=item $xmlFile

Datei mit XRechnungs-XML

=back

=head4 Options

=over 4

=item -verbose => $bool (Default: 0)

Gib Laufzeitinformation über die Verarbeitung auf STDOUT aus.

=back

=head4 Returns

(Integer) Status der Validierung: 0 = ok, 1 = fehlgeschlagen.

=head4 Description

Validiere XRechnungs-XML-Datei $xmlFile und liefere den Status der
Validierung zurück.

=cut

# -----------------------------------------------------------------------------

sub validate {
    my $self = shift;

    my $p = Quiq::Path->new;

    # Optionen und Argumente

    my $log = undef;
    my $verbose = 0;

    my $argA = $self->parameters(1,1,\@_,
        -logger => \$log,
        -verbose => \$verbose,
    );
    my $xmlFile = $p->expandTilde(shift @$argA);

    # Führe Operation aus

    my $sh = Quiq::Shell->new(log=>0);

    if (!Quiq::Path->exists($xmlFile)) {
        $self->throw(
            'MUSTANG-00099: File does not exists',
            XmlFile => $xmlFile,
        );
    }

    my ($javaExe,$validatorDir) = $self->get(qw/javaExe validatorDir/);
    my $jar = "$validatorDir/validationtool-1.5.0-standalone.jar";
    my $scenariosFile = "$validatorDir/scenarios.xml";
    my $xmlFileDir = $p->dir($xmlFile);

    my $cmd = "$javaExe -jar $jar -r $validatorDir -s $scenariosFile".
        qq| -o "$xmlFileDir" "$xmlFile"|;
    if ($verbose) {
        say $cmd;
    }
    elsif ($log) {
        $log->info("Validiere XRechnungs-XML: $cmd");
    }
    my $stdout = $sh->exec($cmd,-sloppy=>1,-capture=>'stdout');
    my $status = $stdout =~ /Validation successful/i? 0: 1;

    return $status;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.236

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2026 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
