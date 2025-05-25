# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Mustang - Frontend für Mustang Kommendozeilen-Werkzeug

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

B<Mustang> ist eine Java-Biblithek sowie ein Kommandzeilen-Werkzeug für den
Umgang mit ZUGFeRD-Rechnungen. Die Klasse Quiq::Mustang stellt ein
Perl-Frontend für die Nutzung des Kommandozeilen-Werkzeugs bereit.

=head2 Links

=over 2

=item *

L<Homepage Mustang-Projekt|https://www.mustangproject.org/>

=item *

L<Kommandozeilen-Werkzeug|https://www.mustangproject.org/commandline/>

=item *

L<Mustang-Projekt auf GitHub|https://github.com/ZUGFeRD/mustangproject>

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Mustang;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.226';

use Quiq::Path;
use Quiq::Shell;
use Quiq::Assert;
use JSON ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $mus = $class->new($jarFile);

=head4 Arguments

=over 4

=item $jarFile

Pfad zur JAR-Datei C<Mustang-CLI-X.Y.Z.jar>, z.B.
C<~/Mustang-CLI-2.16.2.jar>

=back

=head4 Returns

Mustang-Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$jarFile) = @_;

    if (!Quiq::Path->exists($jarFile)) {
        $class->throw(
            'MUSTANG-00099: Jarfile does not exists',
            JarFile => $jarFile,
        );
    }

    return $class->SUPER::new(
        jarFile => $jarFile,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 validate() - Validiere ZUGFeRD-Datei

=head4 Synopsis

  $status = $mus->validate($file);

=head4 Arguments

=over 4

=item $file

ZUGFeRD-Datei, wie B<Mustang> sie erwartet (als XML oder PDF).

=back

=head4 Options

=over 4

=item -force => $bool (Default: 0)

Forciere die Validierung, auch wenn sie schon einmal erfolgt ist.

=item -notice => $bool (Default: 0)

Protokolliere nicht nur Validierungsfehler, sondern gib darüber
hinaus Empfehlungen zu Verbesserungen am ZUGFeRD XML aus.

=item -verbose => $bool (Default: 0)

Gib Laufzeitinformation über die Verarbeitung auf STDOUT aus.

=back

=head4 Returns

(Integer) Status der Validierung: 0 = ok, 1 = fehlgeschlagen,
-1 = Datei wurde übergangen, da bereits validiert.

=head4 Description

Validiere die ZUGFeRD-Datei $file und liefere den Status der
Validierung zurück.

=cut

# -----------------------------------------------------------------------------

sub validate {
    my $self = shift;

    # Optionen und Argumente

    my $force = 0;
    my $notice = 0;
    my $verbose = 0;

    my $argA = $self->parameters(1,1,\@_,
        -force => \$force,
        -notice => \$notice,
        -verbose => \$verbose,
    );
    my $file = shift @$argA;
    my $noticeOpt = $notice? '': ' --no-notice';

    my $p = Quiq::Path->new;
    my $sh = Quiq::Shell->new(sloppy=>1);

    (my $dir,$file,my $basename) = $p->split($file);
    # $dir ||= '.';
    $sh->cd($dir);

    my $resultFile = sprintf '%s_result.xml',$basename;
    my $logFile = sprintf '%s_result.log',$basename;

    my $status;
    if ($p->exists($resultFile) && !$force) {
        $status = -1;
    }    
    else {
        my $cmd = "java -Xmx1G -Dfile.encoding=UTF-8".
            " -jar $self->{'jarFile'} --action validate".
            " --source $file --log-as-pdf$noticeOpt >$resultFile 2>$logFile";
        my $exitCode = $sh->exec($cmd,-log=>$verbose);
        if ($exitCode == 130) {
            for my $file ($p->glob("*_result.*")) {
                say "DELETING $file";
                $p->delete($file);
            }
            exit 130;
        }
        $status = $exitCode? 1: 0;
    }
    $sh->back;

    return $status;
}

# -----------------------------------------------------------------------------

=head3 getResult() - Liefere Validierungsresultat

=head4 Synopsis

  ($status,$val) = $mus->getResult($pattern,$as);
  
  ($status,$text) = $mus->getResult($pattern,'text');
  ($status,$ruleH) = $mus->getResult($pattern,'hash');

=head4 Arguments

=over 4

=item $pattern

Glob()-Pattern der Resultat-Datei des Mustang Validators.

=item $as

Typ des Returnwerts:

=over 4

=item 'text'

=item 'hash'

=back

=back

=head4 Description

Liefere das Ergebnis der ZUGFeRD-Validierung.

=cut

# -----------------------------------------------------------------------------

sub getResult {
    my $self = shift;

    # Optionen und Argumente

    my $argA = $self->parameters(2,2,\@_);
    my ($pattern,$as) = @$argA;

    Quiq::Assert->isEnumValue($as,['text','hash']);

    # Operation ausführen

    my $p = Quiq::Path->new;

    my $status = 0;
    my $text = '';
    my %rule;

    my ($resultFile) = $p->glob($pattern);
    if (!$resultFile) {
        # Es liegt kein Mustang Validierungsergebnis vor

        (my $jsonPattern = $pattern) =~ s/_result\.xml/json/;
        my ($jsonFile) = $p->glob($jsonPattern);
        if ($jsonFile) {
            my $json = $p->read($jsonFile);
            my $h = eval {JSON::decode_json($json)};
            if ($@) {
                $status = 1;
                $text = "JSON is invalid\n";
                $rule{'JSON_INV'}++;
            }
        }        
    }
    else {
        # Es liegt ein Mustang Validierungsergebnis vor

        my $xml = Quiq::Path->read($resultFile,-decode=>'UTF-8');

        my ($failed) = $xml =~ m|<failed>(.+?)</failed>|;
        # Wenn <failed> auf 0 gefaked ist
        if (!$failed && $xml =~ m|<summary status="invalid"/>|) {
            $failed = 1;
        }
           
        $status = $failed? 1: 0;
        while ($xml =~ m|(<error.*?</error>)|g) {
            my $error = $1;
            my $path = '';
            while ($error =~ m|/\*:(.*?)\[|g) {
                if ($path) {
                    $path .= '/';
                }
                $path .= $1;
            }
            my ($msg) = $error =~ m|>(.*)</|;
            $text .= "ERROR: $path\n$msg\n-----\n";
            if ($msg =~ /^\[(.*?)\]/) {
                $rule{$1}++;
            }
            # else {
            #     $rule{'XML_INV'}++;
            # }
        }
    }

    if ($as eq 'text') {
        return ($status,$text);
    }
    elsif ($as eq 'hash') {
        return ($status,\%rule);
    }
}

# -----------------------------------------------------------------------------

=head3 visualize() - Visualisiere ZUGFeRD-Datei

=head4 Synopsis

  $mus->visualize($xmlFile,$pdfFile);

=head4 Arguments

=over 4

=item $xmlFile

ZUGFeRD XML-Datei

=item $pdfFile

Erzeugte Visualisierungsdatei (als PDF)

=back

=head4 Description

Visualisiere die ZUGFeRD-Datei $xmlFile als PDF-Datei $pdfFile.

=cut

# -----------------------------------------------------------------------------

sub visualize {
    my ($self,$xmlFile,$pdfFile) = @_;

    my $sh = Quiq::Shell->new(log=>1);

    my $cmd = "java -Xmx1G -Dfile.encoding=UTF-8 -jar $self->{'jarFile'}".
        " --action pdf --source $xmlFile --out $pdfFile >/dev/null 2>&1";
    $sh->exec($cmd);

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.226

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
