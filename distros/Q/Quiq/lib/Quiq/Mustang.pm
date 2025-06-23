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

our $VERSION = '1.228';

use Quiq::Path;
use Quiq::PerlModule;
use Quiq::Shell;
use Quiq::Assert;
use Quiq::Html::Producer;
use Quiq::Html::List;
use Quiq::Html::Page;
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

    my $mustangDir;
    if ($0 =~ /\.cotedo/) {
        $mustangDir = $ENV{'HOME'}.'/dvl/jaz/Blob/mustang';
    }
    else {
        my $mod = Quiq::PerlModule->new('Quiq::Mustang');
        $mustangDir = $mod->moduleDir;
    }

    return $class->SUPER::new(
        mustangDir => $mustangDir,
        jarFile => $jarFile,
        brH => undef, # wird bei Bedarf geladen
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

=item 'html'

=back

=back

=head4 Description

Liefere das Ergebnis der ZUGFeRD-Validierung.

=cut

# -----------------------------------------------------------------------------

sub getResult {
    my $self = shift;

    # Optionen und Argumente

    my $language = 'de';

    my $argA = $self->parameters(2,2,\@_,
        -language => \$language,
    );
    my ($pattern,$as) = @$argA;

    Quiq::Assert->isEnumValue($as,['text','hash','html']);

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
            my $br;
            my ($msg) = $error =~ m|>(.*)</|;
            if ($msg =~ /^\[(.*?)\]/) {
                $br = $1;
                if ($rule{$br}++) {
                    # Wir melden jede BR-Verletzung nur ein Mal
                    next;
                }
            }
            if ($language eq 'de') {
                my $text = $self->br($br);
                if ($text) {
                    $msg = "[$br] $text";
                }
            }
            $text .= "ERROR: $path\n$msg\n-----\n";

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
    elsif ($as eq 'html') {
        my @arr = split /^-+\n/m,$text;
        for (@arr) {
            s|(ERROR:)|<span class="red">$1</span>|g;
            s|(.*)\[|<span class="bold">$1</span>[|s;
            s|(B[TGR]-[-\w]+)|<span class="red">$1</span>|g;
        }
        my $h = Quiq::Html::Producer->new;
        my $body;
        if ($status) {
            $body = Quiq::Html::List->html($h,
                items => \@arr,
            );
        }
        else {
            $body = $h->tag('span',
                class => 'bold green',
                'E-Rechnung: Das XML ist valide'
            );
        }
        my $html = Quiq::Html::Page->html($h,
            styleSheet => q~
                body {
                    font-family: sans-serif;
                    font-size: 10pt;
                }
                li {
                    padding-bottom: 0.5em;
                }
                .bold {
                    font-weight: bold;
                }
                .red {
                    color: red;
                }
                .green {
                    color: green;
                }
            ~,
            body => $body,
        );
        return ($status,$html);
    }
}

# -----------------------------------------------------------------------------

=head3 visualize() - Visualisiere ZUGFeRD-Datei

=head4 Synopsis

  $mus->visualize($xmlFile,$outFile,%options);

=head4 Arguments

=over 4

=item $xmlFile

ZUGFeRD XML-Datei

=item $outFile

Erzeugte Visualisierungsdatei. Hat der Dateiname die Endung .pdf,
wird eine PDF-Datei erzeugt, sonst eine HTML-Datei.

=back

=head4 Options

=over 4

=item -addBusinessTerms => $bool (Default: 0)

Füge im Falle von HTML als Zielformat die Kürzel der Business-Terms
("BT-NNN") zu den Feldinhelten hinzu.

=back

=head4 Description

Visualisiere die ZUGFeRD-Datei $xmlFile als PDF- oder HTML-Datei $pdfFile.

=head4 Example

Erzeuge PDF-Visualisierung:

  perl -MQuiq::Mustang -E '$mus = Quiq::Mustang->new("~/sys/opt/mustang/Mustang-CLI-2.17.0.jar"); $mus->visualize("174284711604.xml","174284711604.pdf")'

Erzeuge HTML-Visualisierung:

  perl -MQuiq::Mustang -E '$mus = Quiq::Mustang->new("~/sys/opt/mustang/Mustang-CLI-2.17.0.jar"); $mus->visualize("174284711604.xml","174284711604.html")'

=cut

# -----------------------------------------------------------------------------

sub visualize {
    my $self = shift;

    # Optionen und Argumente

    my $addBusinessTerms = 0;

    my $argA = $self->parameters(2,2,\@_,
        -addBusinessTerms => \$addBusinessTerms,
    );
    my ($xmlFile,$outFile) = @$argA;

    # Operation ausführen

    my $sh = Quiq::Shell->new(log=>1);

    my $cmd;
    if ($outFile =~ /\.pdf$/) {
        $cmd = "java -Xmx1G -Dfile.encoding=UTF-8 -jar $self->{'jarFile'}".
            " --action pdf --source $xmlFile --out $outFile".
            " >/dev/null 2>&1";
    }
    else {
        $cmd = "java -Xmx1G -Dfile.encoding=UTF-8 -jar $self->{'jarFile'}".
            " --action visualize --language de --source $xmlFile --out $outFile".
            " >/dev/null 2>&1";
    }
    $sh->exec($cmd);

    if ($outFile =~ /\.html$/) {
        my $p = Quiq::Path->new;
        my $h = Quiq::Html::Producer->new;

        (my $resultFile = $outFile) =~ s/muster\.html/result.txt/;
        my $text = $p->read($resultFile,-decode=>'UTF-8');

        my %key;
        while ($text =~ /(B[GT]-[-\w]+)/g) {
            $key{$1} = 1;
        }

        if ($addBusinessTerms) {
            my $sub = sub {
                my ($keyH,$key) = @_;
                
                my $color = $keyH->{$key}? 'red':
                    substr($key,0,2) eq 'BT'? 'green': '#bbbbbb';

                # <span style="color: $color">$key</span>)</div>|;

                return $h->tag('span',
                    style => "color: $color",
                    $key
                );
            };

            my $html = $p->read($outFile,-decode=>'UTF-8');
            $html =~ s{<div class="haftungausschluss">.*?</div>\n}{}g;

            # $html =~ s{(title="(BT-.*?)".*?)</div>}
            #     {$1 (<span style="color: green">$2</span>)</div>}sg;
            # $html =~ s{(title="(BG-.*?)".*?)</div>}
            #     {$1 (<span style="color: #bbbbbb">$2</span>)</div>}sg;

            $html =~ s{(title="(B[GT]-.*?)".*?)</div>}
                {"$1 (".$sub->(\%key,$2).')</div>'}sge;

            $p->write($outFile,$html,-encode=>'UTF-8');
        }

        # Eine CSS- und JS-Datei werden erzeugt, die wir jedoch nicht
        # brauchen, da der Code ist in der erzeugten HTML-Datei enthalten ist
        $sh->exec('rm -f xrechnung-viewer.*');
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Information

=head3 br() - Text Geschäftsregel (Business Rule)

=head4 Synopsis

  $text = $zug->br($br);

=head4 Arguments

=over 4

=item $br

Bezeichner der Geschäftsregel. Beispiel: C<BR-CO-17>
(Umsatzsteueraufschlüsselung)

=back

=head4 Returns

(String) Text der Geschäftsregel

=head4 Description

Liefere den Text der Geschäftsregel $br. Ist die Geschäftsregel nicht
definiert, wird ein Leerstring ('') geliefert.

=head4 Example

  $ perl -MQuiq::Mustang -E 'say Quiq::Mustang->new($jarFile)->br("BR-CO-17")'
  (Umsatzsteueraufschlüsselung) Der Inhalt des Elementes „VAT category tax
  amount“ (BT-117) entspricht dem Inhalt des Elementes „VAT category taxable
  amount“ (BT-116), multipliziert mit dem Inhalt des Elementes „VAT category
  rate“ (BT-119) geteilt durch 100, gerundet auf zwei Dezimalstellen.

=cut

# -----------------------------------------------------------------------------

sub br {
    my ($self,$name) = @_;

    my $brH = $self->memoize('brH',sub {
        my ($self,$key) = @_;

        my %h;
        my $text = Quiq::Path->read($self->mustangDir('business-rule.txt'),
            -decode => 'UTF-8',
        );
        my @rules = split /^\n^/m,$text;
        for (@rules) {
            s/\s+/ /g;
            my ($br,$text) = $_ =~ /^(\S+)\s+(.*)/;
            $h{$br} = $text;
        }

        return \%h;
    });

    return $brH->{$name} // '';
}

# -----------------------------------------------------------------------------

=head3 mustangDir() - Pfad des Mustang-Verzeichnisses

=head4 Synopsis

  $path = $zug->mustangDir;
  $path = $zug->mustangDir($subPath);

=head4 Arguments

=over 4

=item $subPath

Subpfad ins Verzeichnis

=back

=head4 Returns

(String) Dateipfad

=head4 Description

Liefere den Dateipfad des Mustang-Verzeichnisses, optional ergänzt um
Subpfad $subPath.

=cut

# -----------------------------------------------------------------------------

sub mustangDir {
    my $self = shift;

    my $path = $self->{'mustangDir'};
    if (@_) {
        $path .= "/$_[0]";
    }

    return $path;
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
