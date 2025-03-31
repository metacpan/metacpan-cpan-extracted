# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Zugferd - Generiere/Akzeptiere XML einer ZUGFeRD-Rechnung

=head1 BASE CLASS

L<Quiq::Hash>

=head1 ENVIRONMENT

=over 4

=item $ZUGFERD_DIR

Verzeichnis mit den ZUGFeRD XSD-Dateien und dem ZUGFeRD XML-Template.
Der Wert dar Variable ist priorisiert gegenüber dem klasseninternen Pfad.

=back

=head1 DESCRIPTION

B<Diese Klasse befindet sich in Entwicklung!>

Die Klasse kapselt das ZUGFeRD 2.3(Factur-X Version 1.0.07) XML
Profile BASIC sowie ein XML-Template zu diesem Profile, das alle
ELemente und Attribute umfasst. Das Template kann als XML (Text)
oder als Datenstruktur (Baum) in verschiedenen Varianten
(leer, mit Beispielwerten, mit Platzhaltern) genutzt werden.

=head1 EXAMPLES

Zeige ZUGFeRD XML und Datenstruktur als Zeichenkette:

  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->new->doc' # XML, kommentiert
  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->new->doc("tree")'

(Tipp: XML-Ausgabe in Datei speichern und mit Emacs oder vi
mit "Syntax Highlighting" lesen)

Zeige das ZUGFeRD XML:

  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->new->xml' # ohne Werte
  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->new->xml("placeholders")'
  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->new->xml("values")'

Zeige das ZUGFeRD XML als Baum:

  $ perl -MQuiq::Zugferd -MQuiq::Dumper -E 'say Quiq::Dumper->dump(Quiq::Zugferd->new->tree)'

=cut

# -----------------------------------------------------------------------------

package Quiq::Zugferd;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.225';

use Quiq::PerlModule;
use Quiq::Path;
use XML::Compile::Schema ();
use XML::LibXML ();
use XML::Compile::Util ();
use Quiq::Dumper;
use Quiq::Tree;
use Quiq::AnsiColor;
use Quiq::Zugferd::Tree;
use Quiq::Xml;
use Quiq::FileHandle;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 createTemplate() - Erzeuge Template zu ZUGFeRD-Profil

=head4 Synopsis

  $xml = $class->createTemplate($profile,%opt);

=head4 Arguments

=over 4

=item $profile

Name des ZUGFeRD-Profils. Mögliche Namen: 'minimum', 'basicwl',
'basic', 'en16931', 'extended'.

=back

=head4 Options

=over 4

=item -xsdDir => DIR (Default: $ENV{'ZUGFERD_DIR'} || I<ModuleDir>)

Verzeichnis mit den ZUGFeRD Schema-Dateien

=back

=head4 Returns

(String) XML-Template

=head4 Description

Erzeuge auf Basis der XSD-Dateien des ZUGFeRD-Profils $profile mit
XML::Compile::Schema eine XML Template-Datei ohne Werte und liefere das
Ergebnis zurück.

B<ACHTUNG:> Die Templates sind nicht umfassend, es gibt Elemente, denen
die Unterelemente felen. Suche nach Tags mit dem Muster "/>":

  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->createTemplate("minimum")' | grep '/>'
      <ram:GuidelineSpecifiedDocumentContextParameter/>
        <ram:BuyerTradeParty/>
      <ram:ApplicableHeaderTradeDelivery/>

B<Tipp:> Unterschiede zwischen den Profilen lassen sich mit
diff(1) ermitteln.

=head4 Examples

Profil MINIMUM:

  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->createTemplate("minimum")'

Profil BASICWL:

  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->createTemplate("basicwl")'

Profil BASIC:

  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->createTemplate("basic")'

Profil EN16931:

  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->createTemplate("en16931")'

Profil EXTENDED:

  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->createTemplate("extended")'

=cut

# -----------------------------------------------------------------------------

sub createTemplate {
    my ($class,$profile) = splice @_,0,2;
    # @_: @opt

    my $mod = Quiq::PerlModule->new('Quiq::Zugferd');
    my $modDir = $mod->loadPath;
    $modDir =~ s/\.pm//;

    my $zugferdDir = $ENV{'ZUGFERD_DIR'} || "$modDir/profile/$profile";

    # Optionen

    my $xsdDir = $zugferdDir;

    my $opt = $class->parameters(0,0,\@_,
        -xsdDir => \$xsdDir,
    );

    # Ermittele .xsd-Dateien im aktuellen Verzeichnis
    my @xsdFiles = Quiq::Path->find($xsdDir,-pattern=>'\.xsd$');

    # Instantiiere Schema-Objekt

    my $sch = XML::Compile::Schema->new;
    for my $file (@xsdFiles) {
        $sch->importDefinitions($file);
    }

    my $rootType = '{urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100}'.
        'CrossIndustryInvoice';
    my $xml = $sch->template(XML=>$rootType,
        show_comments => 'NONE',
        skip_header => 1,
        show_all => 1,
        prefixes => [
            rsm => 'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100',
        ],
    );

    $xml =~ s|"token"|""|g;
    $xml =~ s|>\s*token\s*<|><|g;
    $xml =~ s|"example"|""|g;
    $xml =~ s|>\s*example\s*<|><|g;
    $xml =~ s|"example"|""|g;
    $xml =~ s|>\s*example\s*<|><|g;
    $xml =~ s|"3.1415"|""|g;
    $xml =~ s|>\s*3.1415\s*<|><|g;
    $xml =~ s|>\s*decoded bytes\s*<|><|g;
    $xml =~ s|>\s*true\s*<|><|g;

    return $xml;
}

# -----------------------------------------------------------------------------

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $zug = $class->new($profile);

=head4 Returns

Object

=head4 Description

Instantiiere ein ZUGFeRD-Objekt auf Basis von Profil $profile der Klasse
und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$profile) = @_;

    my $mod = Quiq::PerlModule->new('Quiq::Zugferd');
    my $modDir = $mod->loadPath;
    $modDir =~ s/\.pm//;

    my $zugferdDir = $ENV{'ZUGFERD_DIR'} || "$modDir/profile/$profile";

    my $xmlTemplateFile = "$zugferdDir/template.xml";
    my $xsdDir = $zugferdDir;

    my $p = Quiq::Path->new;

    if (!$p->exists($xsdDir)) {
        $class->throw(
            'ZUGFERD-00099: XSD directory does not exist',
            Dir => $xsdDir,
        );
    }
    if (!$p->exists($xmlTemplateFile)) {
        $class->throw(
            'ZUGFERD-00099: XML template does not exist',
            Template => $xmlTemplateFile,
        );
    }

    # Ermittele .xsd-Dateien
    my @xsdFiles = Quiq::Path->find($xsdDir,-pattern=>'\.xsd$');

    # Instantiiere Schema-Objekt

    my $sch = XML::Compile::Schema->new;
    for my $file (@xsdFiles) {
        $sch->importDefinitions($file);
    }

    # Lies Template-Datei
    my $template = $p->read($xmlTemplateFile);

    # Entferne Zeilen mit # am Anfang
    $template =~ s|^\s*#.*\n||gm;

    # Ermittele den Typ des Wurzelelements

    my $doc = XML::LibXML->load_xml(
        string => $template,
        no_blanks => 1,
    );
    my $top = $doc->documentElement;
    my $rootType = XML::Compile::Util::type_of_node($top);

    # Ermittele die [01]..n-Bestandteile im Template. Diese Komponenten
    # extrahieren wir später aus dem Baum.
    
    my @parts;
    while ($template =~ m|<([\w:]+)>.*\.\.n\b|g) {
        (my $tag = $1) =~ s/.*://;
        push @parts,$tag;
    }

    return bless {
        sch => $sch,
        rootType => $rootType,
        template => $template,
        parts => \@parts,
    },$class;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 parts() - Liefere Abschnitte mit mehreren gleichen Unterabschnitten

=head4 Synopsis

  @parts | $partA = $zug->parts;

=head4 Returns

(Array) Liste von Abschnitten. Im Skalarkontext liefere eine Referenz auf
die Liste.

=head4 Description

Liefere die Liste der Namen aller Abschnitte, die mehrere gleiche
Unterabschnitte haben. Die Namen sind Tagnamen ohne Namespace-Präfix.

=cut

# -----------------------------------------------------------------------------

sub parts {
    my $self = shift;
    my $partA = $self->{'parts'};
    return wantarray? @$partA: $partA;
}

# -----------------------------------------------------------------------------

=head3 doc() - Liefere ZUGFeRD Doku

=head4 Synopsis

  $str = $zug->doc;
  $str = $zug->doc($type);

=head4 Arguments

=over 4

=item $type (Default: 'xml')

Art der Dokumentation:

=over 4

=item 'xml'

ZUGFeRD XML mit Beispielwerten und Kommentaren

=item 'tree'

ZUGFeRD Baum mit Beispielwerten

=item 'parts'

Liste der Elemente, mit n-fachen Unterelementen. Wenn keine
Kardinalitäten vorhanden sind, ist die Liste leer.

=item 'paths'

Liste der Zugriffspfade im Baum

=item 'cardinality'

Liste der Elemente und ihrer Kardinalitäten. Wenn keine Kardinalitäten
und/oder Kommentare vorhanden sind, fehlt die Information in der
Ausgabe.

=back

=back

=head4 Returns

(String) Doku

=head4 Example

ZUGFeRD XML mit Beispielwerten und Kommentaren:

  $ perl -MQuiq::Zugferd -E 'print Quiq::Zugferd->new->doc("xml")'

ZUGFeRD Baum mit Beispielwerten:

  $ perl -MQuiq::Zugferd -E 'print Quiq::Zugferd->new->doc("tree")'

Zugriffspfade im ZUGFeRD Baum:

  $ perl -MQuiq::Zugferd -E 'print Quiq::Zugferd->new->doc("paths")'

Elemente mit n-fachen Unterelementen:

  $ perl -MQuiq::Zugferd -E 'print Quiq::Zugferd->new->doc("parts")'

Elemente und ihre Kardinalitäten:

  $ perl -MQuiq::Zugferd -E 'print Quiq::Zugferd->new->doc("cardinality")'

=cut

# -----------------------------------------------------------------------------

sub doc {
    my $self = shift;
    my $type = shift // 'xml';

    if ($type eq 'xml') {
        return $self->get('template');
    }
    elsif ($type eq 'tree') {
        my $h = $self->tree('values');
        return Quiq::Dumper->dump($h)."\n";
    }
    elsif ($type eq 'paths') {
        my $h = $self->tree;
        my @paths = sort Quiq::Tree->leafPaths($h);
        return join("\n",@paths)."\n";
    }
    elsif ($type eq 'parts') {
        return join("\n",$self->parts)."\n";
    }
    elsif ($type eq 'cardinality') {
        my $a = Quiq::AnsiColor->new(1);
        my $str = '';
        my $template = $self->get('template');
        for my $line (split /\n/,$template) {
            my ($tag) = $line =~ /^(\s+<[\w:]+>)/;
            my ($comment) = $line =~ /(\s+<!--.*?-->)/;
            $comment //= '';
            if ($tag) {
                my ($cardinality) = $line =~ /(.\.\..)/;
                $cardinality ||= '    ';
                $str .= sprintf "%s%s%s\n",$cardinality,
                    $a->str('cyan',$tag),
                    $a->str('red',$comment);
            }
        }
        return $str;
    }

    $self->throw(
        'ZUGFERD-00099: Unknown document type',
        Type => $type,
    );
}

# -----------------------------------------------------------------------------

=head3 tree() - Liefere ZUGFeRD XML Template als Baum

=head4 Synopsis

  $h = $zug->tree;
  $h = $zug->tree($variant);

=head4 Arguments

=over 4

=item $variant (Default: 'placeholders')

=over 4

=item 'empty'

Ohne Werte

=item 'placeholders'

Mit Platzhaltern. Identisch zu "empty", wenn keine Platzhalter
definiert sind.

=item 'values'

Mit Beispielwerten. Leerstrings statt undef, wenn keine Werte
gesetzt sind.

=back

=back

=head4 Returns

Baum-Referenz

=head4 Description

Wandele das ZUGFeRD XML Template in einen Baum und liefere eine Referenz
auf den Wurzelknoten zurück.

=cut

# -----------------------------------------------------------------------------

sub tree {
    my $self = shift;
    my $variant = shift // 'empty';

    my ($sch,$rootType) = $self->get(qw/sch rootType/);

    # Instantiiere nicht-validierenden XML-Reader

    my $rdr = $sch->compile(READER=>$rootType,
        sloppy_floats => 1, # Wir wollen keine BigFloat-Elemente
        sloppy_integers => 1, # Wir wollen keine BigInt-Elemente
        validation => 0,
    );

    my $h;
    if ($variant eq 'empty') {
        # Erzeuge Baum mit ohne Werte

        my $xml = $self->xml('empty');
        $h = $rdr->($xml);

        # Setze den Wert aller Blattknoten auf undef

        Quiq::Tree->setLeafValue($h,sub {
            return undef;
        });
    }
    elsif ($variant eq 'placeholders') {
        # Erzeuge Baum mit Platzhaltern

        my $xml = $self->xml('placeholders');
        $h = $rdr->($xml);

        # Setze den Wert aller Blattknoten ohne Platzhalter auf undef

        Quiq::Tree->setLeafValue($h,sub {
            my $val = shift;
            # '1' kann bei Boolean Element auftreten ("Indicator")
            if ($val eq '' || $val eq '1') {
                $val = undef;
            }
            return $val;
        });
    }
    elsif ($variant eq 'values') {
        # Erzeuge Baum mit Werten (hier könnte auch ein validierender
        # XML-Reader zum EInsatz kommen)

        my $xml = $self->xml('values');
        $h = $rdr->($xml);
    }
    else {
        $self->throw(
            'ZUGFERD-00099: Unknown tree variant',
            Variant => $variant,
        );
    }

    return Quiq::Zugferd::Tree->new($h);
}

# -----------------------------------------------------------------------------

=head3 treeToXml() - Wandele (ZUGFeRD) Baum nach XML

=head4 Synopsis

  $xml = $zug->treeToXml($tree,%opt);

=head4 Arguments

=over 4

=item $tree

(Object) Baum, der nach XML gewandelt wird.

=back

=head4 Options

=over 4

=item -validate => $bool (Default: 1)

Erzeuge einen validierenden XML-Writer.

=back

=head4 Returns

(String) XML

=head4 Description

Wandele den Baum nach XML und liefere dieses zurück.

=head4 Example

  $ perl -MQuiq::Zugferd -E '$zug = Quiq::Zugferd->new("en16931"); $tree = $zug->tree; print $zug->treeToXml($tree)'

=cut

# -----------------------------------------------------------------------------

sub treeToXml {
    my ($self,$tree) = splice @_,0,2;
    # @_: %opt

    # Optionen

    my $validate = 1;

    $self->parameters(\@_,
        -validate => \$validate,
    );

    # Operation ausführen

    my ($sch,$rootType) = $self->get(qw/sch rootType/);

    # (Leeren) XML-Baum instantiieren
    my $doc = XML::LibXML::Document->new('1.0','UTF-8');

    # Instantiiere XML-Writer

    my $wrt = $sch->compile(WRITER=>$rootType,
        validation => $validate,
        # Hiermit verhindern wir, dass x0 statt rsm als Präfix gesetzt wird
        prefixes => [rsm =>
            'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100'],
    );

    # Erzeuge aus dem Baum XML
    my $xml = $wrt->($doc,$tree);

    # Liefere das XML formatiert
    return Quiq::Xml->print($xml);
}

# -----------------------------------------------------------------------------

=head3 xml() - Liefere ZUGFeRD XML Template als Zeichenkette

=head4 Synopsis

  $xml = $zug->xml;
  $xml = $zug->xml($variant);

=head4 Arguments

=over 4

=item $variant (Default: 'empty')

Variante des XML:

=over 4

=item 'empty'

Ohne Werte

=item 'placeholders'

Mit Platzhaltern

=item 'values'

Mit Beispielwerten

=back

=back

=head4 Returns

(String) XML

=cut

# -----------------------------------------------------------------------------

sub xml {
    my $self = shift;
    my $variant = shift // 'empty';

    my $xml = $self->get('template');

    if ($variant eq 'empty') {
        $xml =~ s|\s*<!--.*?-->||g; # Kommentare entfernen
        $xml =~ s|>((?!.*:basic).)*</|></|g; # Inhalte entfernen, außer
                                             # Specification Identifier
        $xml =~ s|(?<!xmlns:...)=".*?"|=""|g; # Attributwerte entfernen (bis
                                              # auf Namespace-Vereinbarungen)
    }
    elsif ($variant eq 'placeholders') {
        my $str = '';
        my $fh = Quiq::FileHandle->new('<',\$xml);
        while (<$fh>) {
            # Content-Platzhalter ermitteln
            my $ph = '';
            if (/%([A-Z1-9_]+)%/) {
                $ph = "__${1}__";
            }

            # Attribut-Platzhalter ermitteln
            my %ph;
            while (/(\w+)=%([A-Z1-9_]+)%/g) {
                $ph{$1} = "__${2}__";
            }

            # Kommentar entfernen
            s|\s*<!--.*?-->||g;

            # Content-Platzhalter einsetzen
            s|>.*?</|>$ph</|;

            # Attribut-Platzhalter einsetzen
            my @attr;
            while (/(\S+)=".*?"/g) {
                 # Ignoriere Attribute mit Namespace-Angabe
                 if (index($1,'xmlns:') < 0) {
                     push @attr,$1;
                 }
            }
            for my $attr (@attr) {
                 my $ph = $ph{$attr} // '';
                 s/$attr=".*?"/$attr="$ph"/;
            }
            $str .= $_;
        }
        $fh->close;
        $xml = $str;
    }
    else { # values
        $xml =~ s|\s*<!--.*?-->||g;
    }

    return $xml;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.225

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
