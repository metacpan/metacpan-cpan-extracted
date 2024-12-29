# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Zugferd - Generiere/Akzeptiere XML einer ZUGFeRD-Rechnung

=head1 BASE CLASS

L<Quiq::Hash>

=head1 ENVIRONMENT

=over 4

=item $ZUGFERD_DIR

(Default-)Verzeichnis mit den ZUGFeRD XSD-Dateien und dem
ZUGFeRD XML-Template.

=back

=head1 DESCRIPTION

B<WORK IN PROGRESS>

Die Klasse kapselt das ZUGFeRD 2.3(Factur-X Version 1.0.07) XML
Schema BASIC sowie ein XML-Template zu diesem Schema, das alle
ELemente und Attribute umfasst. Das Template kann als XML (Text)
oder als Datenstruktur (Hash) in verschiedenen Varianten
(leer, mit Beispielwerten, mit Platzhaltern) genutzt werden.

=head1 EXAMPLES

Zeige ZUGFeRD XML und Datenstruktur als Zeichenkette:

  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->new->doc' # XML, kommentiert
  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->new->doc("hash")'

(Tipp: XML-Ausgabe in Datei speichern und mit Emacs oder vi
mit "Syntax Highlighting" lesen)

Zeige das ZUGFeRD XML:

  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->new->xml' # ohne Werte
  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->new->xml("placeholders")'
  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->new->xml("values")'

Zeige das ZUGFeRD XML als Hash:

  $ perl -MQuiq::Zugferd -MQuiq::Dumper -E 'say Quiq::Dumper->dump(Quiq::Zugferd->new->hash)'
  
  $ perl -MQuiq::Zugferd -MQuiq::Dumper -E 'say Quiq::Dumper->dump(Quiq::Zugferd->new->hash)'

=cut

# -----------------------------------------------------------------------------

package Quiq::Zugferd;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.223';

use Quiq::PerlModule;
use Quiq::Path;
use XML::Compile::Schema ();
use XML::LibXML ();
use XML::Compile::Util ();
use Quiq::Dumper;
use Quiq::Tree;
use Quiq::Xml;
use Quiq::FileHandle;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $zug = $class->new(@opt);

=head4 Options

=over 4

=item --xsdDir=DIR (Default: $ENV{'ZUGFERD_DIR'} || I<ModuleDir>)

Verzeichnis mit den ZUGFeRD Schema-Dateien

=item --xmlTemplateFile=FILE.xml (Default: "$ENV{'ZUGFERD_DIR'}\

/zugferd_basic.xml")
ZUGFeRD-Template

=back

=head4 Returns

Object

=head4 Description

Instantiiere ein Objekt der Klasse und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @opt

    my $mod = Quiq::PerlModule->new('Quiq::Zugferd');
    my $modDir = $mod->loadPath;
    $modDir =~ s/\.pm//;

    my $zugferdDir = $ENV{'ZUGFERD_DIR'} || $modDir;

    my $xmlTemplateFile = "$zugferdDir/zugferd_basic.xml";
    my $xsdDir = $zugferdDir;

    my $opt = $class->parameters(0,0,\@_,
        -xmlTemplateFile => \$xmlTemplateFile,
        -xsdDir => \$xsdDir,
    );

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

    # Erzeuge Lib::XML-Baum und ermittele den Typ des Wurzelelements

    my $doc = XML::LibXML->load_xml(
        string => $template,
        no_blanks => 1,
    );
    my $top = $doc->documentElement;
    my $rootType = XML::Compile::Util::type_of_node($top);

    return bless {
        sch => $sch,
        rootType => $rootType,
        template => $template,
    },$class;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

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

=item 'hash'

ZUGFeRD Hash mit Beispielwerten

=item 'paths'

Liste der Zugriffspfade im Hash.

=back

=back

=head4 Returns

(String) Doku

=head4 Example

ZUGFeRD XML mit Beispielwerten und Kommentaren:

  $ perl -MQuiq::Zugferd -E 'print Quiq::Zugferd->new->doc('xml')'

ZUGFeRD Hash mit Beispielwerten:

  $ perl -MQuiq::Zugferd -E 'print Quiq::Zugferd->new->doc('hash')'

Zugriffspfade im ZUGFeRD Hash:

  $ perl -MQuiq::Zugferd -E 'print Quiq::Zugferd->new->doc('paths')'

=cut

# -----------------------------------------------------------------------------

sub doc {
    my $self = shift;
    my $type = shift // 'xml';

    if ($type eq 'xml') {
        return $self->get('template');
    }
    elsif ($type eq 'hash') {
        my $h = $self->hash('values');
        return Quiq::Dumper->dump($h)."\n";
    }
    elsif ($type eq 'paths') {
        my $h = $self->hash;
        my @paths = sort Quiq::Tree->paths($h);
        return join("\n",@paths),"\n";
    }

    $self->throw(
        'ZUGFERD-00099: Unknown document type',
        Type => $type,
    );
}

# -----------------------------------------------------------------------------

=head3 hash() - Liefere ZUGFeRD XML Template als Hash

=head4 Synopsis

  $h = $zug->hash;
  $h = $zug->hash($variant);

=head4 Arguments

=over 4

=item $variant (Default: 'placeholders')

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

Hash-Referenz

=head4 Description

Wandele das ZUGFeRD XML Template in einen Hash und liefere eine Referenz
auf diesen Hash zurück.

=cut

# -----------------------------------------------------------------------------

sub hash {
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
        # Erzeuge Hash mit ohne Werte

        my $xml = $self->xml('empty');
        $h = $rdr->($xml);

        # Setze den Wert aller Blattknoten auf undef

        Quiq::Tree->setLeafValue($h,sub {
            return undef;
        });
    }
    elsif ($variant eq 'placeholders') {
        # Erzeuge Hash mit Platzhaltern

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
        # Erzeuge Hash mit Werten (hier könnte auch ein validierender
        # XML-Reader zum EInsatz kommen)

        my $xml = $self->xml('values');
        $h = $rdr->($xml);
    }
    else {
        $self->throw(
            'ZUGFERD-00099: Unknown hash variant',
            Variant => $variant,
        );
    }

    return $h;
}

# -----------------------------------------------------------------------------

=head3 hashToXml() - Wandele (ZUGFeRD) Hash nach XML

=head4 Synopsis

  $xml = $zug->hashToXml($h);

=head4 Returns

(String) XML

=head4 Description

Wandele den Hash nach XML und liefere dieses zurück.

=head4 Example

  $ perl -MQuiq::Zugferd -E '$zug = Quiq::Zugferd->new; $h = $zug->asHash; print $zug->hashToXml($h)'

=cut

# -----------------------------------------------------------------------------

sub hashToXml {
    my ($self,$h) = @_;

    my ($sch,$rootType) = $self->get(qw/sch rootType/);

    # (Leeren) XML-Baum instantiieren
    my $doc = XML::LibXML::Document->new('1.0','UTF-8');

    # Instantiiere XML-Writer

    my $wrt = $sch->compile(WRITER=>$rootType,
        # Hiermit verhindern wir, dass x0 statt rsm als Präfix gesetzt wird
        prefixes => [rsm =>
            'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100'],
    );

    # Erzeuge aus dem Hash XML
    my $xml = $wrt->($doc,$h);

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

Variante des Hashs:

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
            # Content-Platzhalter einsetzen (außer Specification Identifier)
            if (!/:basic/) {
                s|>.*?</|>$ph</|;
            }
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

1.223

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2024 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
