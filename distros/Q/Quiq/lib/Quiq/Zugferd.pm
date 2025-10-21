# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Zugferd - Generiere das XML von ZUGFeRD-Rechnungen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Diese Klasse dient der Generung des XMLs von E-Rechnungen nach dem
ZUGFeRD/Factur-X-Standard. Sie kapselt die Profile des Standards,
sowohl die XSD-Dateien (XML-Schemadefinition) als auch fertige
Templates.

Die Generierung eines Rechnungs-XMLs erfolgt durch Einsetzung der
Rechnungswerte in das Template des jeweiligen Profils.

=head1 EXAMPLES

Zeige das Template des Profils EN16931:

  $ perl -MQuiq::Zugferd -E 'print Quiq::Zugferd->new("en16931")->template'

Zeige den Template-Baum des Profils EN16931:

  $ perl -MQuiq::Zugferd -MQuiq::Dumper -E '$t = Quiq::Zugferd->new("en16931")->tree; say Quiq::Dumper->dump($t)'

=cut

# -----------------------------------------------------------------------------

package Quiq::Zugferd;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;
use utf8;

our $VERSION = '1.232';

use Quiq::PerlModule;
use Quiq::Path;
use Quiq::Zugferd::Tree;
use Quiq::Dumper;
use XML::Compile::Schema ();
use XML::LibXML ();
use XML::Compile::Util ();
use Quiq::Shell;
use Quiq::Storable;
use Quiq::AnsiColor;
use Quiq::FileHandle;
use Quiq::Xml;
use Quiq::Hash;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $zug = $class->new($profile,%options);

=head4 Arguments

=over 4

=item $profile

Name des ZUGFeRD-Profils. Es existieren die ZUGFeRD-Profile: C<minimum>,
C<basicwl>, C<basic>, C<en16931>, C<extended>.

=back

=head4 Options

=over 4

=item -version => $version (Default: '2.3.2')

Die ZUGFeRD-Version.

=back

=head4 Returns

Object

=head4 Description

Instantiiere ein ZUGFeRD-Objekt des Profils $profile und der
ZUGFeRD-Version $version und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;

    # Optionen und Argumente

    my $version = '2.3.2';

    my $argA = $class->parameters(1,1,\@_,
        -version => \$version,
    );
    my $profile = shift @$argA;

    my $mod = Quiq::PerlModule->new('Quiq::Zugferd');
    my $modDir = $mod->moduleDir;

    my $zugferdDir = "$modDir/$version";
    my $xsdDir = "$zugferdDir/profile/$profile";
    my $xmlTemplateFile = "$xsdDir/template.xml";

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

    # Erzeuge Template-Baum

    my $rdr = $sch->compile(READER=>$rootType,
        sloppy_floats => 1, # Wir wollen keine BigFloat-Elemente
        sloppy_integers => 1, # Wir wollen keine BigInt-Elemente
        validation => 0,
    );

    my $h = $rdr->($template);
    my $tree = Quiq::Zugferd::Tree->new($h);

    # direkte Zuweisung, da XML::Compile diese Platzhalter überschreibt
    $tree->setDeep('SupplyChainTradeTransaction.'.
         'ApplicableHeaderTradeSettlement.SpecifiedTradeAllowanceCharge.[0].'.
         'ChargeIndicator.Indicator','BG-21-1');

    # say Quiq::Dumper->dump($tree);

    return bless {
        zugferdDir => $zugferdDir,
        sch => $sch,
        rootType => $rootType,
        template => $template,
        tree => $tree,
        version => $version,
        bgH => undef, # wird bei Bedarf geladen
    },$class;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 checkAttributes() - Prüfe die Attribute des Rechnungsobjekts

=head4 Synopsis

  $msg = $zug->checkAttributes($rch);

=head4 Arguments

=over 4

=item $rch

(Object) Das Rechnungsobjekt

=back

=head4 Returns

(String) Prüfungsbericht

=head4 Description

Prüfe die Felder des Rechnungsobjekts auf mögliche Fehler und liefere
einen Bericht über das Ergebnis. Falls keine Fehler festgestellt wurden,
lieferet die Methode einen Leerstring ('').

=cut

# -----------------------------------------------------------------------------

sub checkAttributes {
    my ($self,$rch) = @_;

    my $text = '';

    # Skalare Attribute

    my $btH = $self->bt;
    for my $bt (values %$btH) {
        if (!$bt->mandatory) {
            next;
        }
        my $key = $bt->attribute;
        if ($key) {
            my $val = $rch->getDeep($key);
            if (!$val) {
                $text .= sprintf q|ERROR: Rechnungsattribut "%s" (%s)|.
                    " hat keinen Wert\n",$key,$bt->name;
            }
        }
    }

    # Listen

    my $arr = $rch->positionen;
    if (!@$arr) {
        $text .= sprintf "ERROR: Rechnung hat keine Positionen\n";
    }

    $arr = $rch->umsatzsteuern;
    if (!@$arr) {
        $text .= sprintf "ERROR: Umsatzsteueraufschlüsselung fehlt\n";
    }

    return $text;
}

# -----------------------------------------------------------------------------

=head3 combine() - Erzeuge ZUGFeRD PDF

=head4 Synopsis

  $zug->combine($pdfFile,$xmlFile,$zugferdFile);

=head4 Arguments

=over 4

=item $pdfFile

(String) Der Pfad zum PDF der Rechnung

=item $xmlFile

(String) Der Pfad zum ZUGFeRD XML der Rechnung

=item $zugferdFile

(String) Der Pfad zur resultierenden ZUGFeRD Rechnung

=back

=head4 Description

Füge das Rechnungs-PDF $pdfFile und das ZUGFeRD XML $xmlFile
zusammen und schreibe das Ergebnis nach $zugferdFile.

=cut

# -----------------------------------------------------------------------------

sub combine {
    my ($self,$pdfFile,$xmlFile,$zugferdFile) = @_;

    my $p = Quiq::Path->new;

    my $symlink = sprintf '%s/factur-x.xml',$p->dir($xmlFile);
    $p->duplicate('symlink',$xmlFile,$symlink);

    my $sh = Quiq::Shell->new;
    $sh->exec("pdftk $pdfFile attach_files $symlink output $zugferdFile");

    $p->delete($symlink);

    return;
}

# -----------------------------------------------------------------------------

=head3 createInvoice() - Erzeuge das XML einer ZUGFeRD-Rechnung (abstrakt)

=head4 Synopsis

  $xml = $zug->createInvoice(@args);

=head4 Arguments

=over 4

=item @args

Beliebige Argumente, die für das Ausfüllen des ZUGFeRD XML-Templates
benötigt werden.

=back

=head4 Returns

(String) XML

=cut

# -----------------------------------------------------------------------------

sub createInvoice {
    my $self = shift;

    # Dies ist eine abstrakte Methode, die in einer abgeleiteten
    # Klasse überschrieben werden muss
    $self->throw;

    # Spezifikationskennung
    my $bt24 = 'urn:cen.eu:en16931:2017';

    return $self->resolvePlaceholders(
        -validate => 1,
        -showPlaceholders => 1,
        -showTree => 1,
        '--',
        'BT-24' => $bt24,
    );
}

# -----------------------------------------------------------------------------

=head3 processSubTree() - Verarbeite Subbaum

=head4 Synopsis

  $treeA = $zug->processSubTree($name,\@arr,sub {
      my ($zug,$t,$h,$i) = @_;
      ...
      $t->resolvePlaceholders(
          ...
      );
  
      return $t;
  });

=head4 Arguments

=over 4

=item $zug

ZUGFeRD-Objekt

=item $name

Name des Subbaums

=item @arr

Liste der Elemente, über die iteriert wird, um Teilbäume (mit
ersetzten Platzhaltern) zu erzeugen.

=item sub {}

Subroutine, die die Einsetzung in jeweils einen Subbaum vornimmt

=back

=head4 Returns

(Object) (Sub-)Baum mit ersetzen Platzhaltern

=head4 Description

Ersetze im Subbaum $name die Platzhalter aus den Elementen von @arr.

=cut

# -----------------------------------------------------------------------------

sub processSubTree {
    my ($self,$name,$arr,$sub) = @_;

    my $path = $self->bg($name)->path;
    my $t0 = $self->tree->getSubTree($path,$name);

    my $i = 0;
    my @arr;
    for my $e (@$arr) {
        my $t = Quiq::Storable->clone($t0);
        push @arr,$sub->($self,$t,$e,$i++);
    }

    return \@arr;
}

# -----------------------------------------------------------------------------

=head3 resolvePlaceholders() - Ersetze Platzhalter im Template

=head4 Synopsis

  ($xml,$status,$debugText) = $zug->resolvePlaceholders(@keyVal,%options);

=head4 Arguments

=over 4

=item @keyVal

Liste der Platzhalter/Wert-Paare

=back

=head4 Options

=over 4

=item -label => $text (Default: '')

Versieh den Abschnitt der Platzhalter (bei -showPlaceHolders=>1) mit
der Beschriftung $label.

=item -showPlaceholders => $bool (Default: 0)

Gibt die Liste der Platzhalter auf STDOUT aus

=item -showTree => $bool (Default: 0)

Gib den resultierenden ZUGFeRD-Baum auf STDOUT aus.

=item -subTree => $tree (Default: undef)

Führe die Ersetzung auf dem Teilbaum $tree aus.

=item -validate => $bool (Default: 0)

Aktiviere die Validierung durch XML::Compile

=back

=head4 Returns

(Boolean,String,String) XML nach Platzhalter-Ersetzung und Debug-Text

=head4 Description

Ersetze die Platzhalter im Template des ZUGFeRD-Profils und liefere
das resultierende XML sowie etwaigen Debug-Text zurück.

=cut

# -----------------------------------------------------------------------------

my $a = Quiq::AnsiColor->new(1);

sub resolvePlaceholders {
    my $self = shift;
    # @_: @keyVal,%options

    # Optionen und Argumente

    my $label = '';
    my $showPlaceholders = 0;
    my $showTree = 0;
    my $subTree => undef;
    my $validate = 0;

    my $argA = $self->parameters(0,undef,\@_,
       -label => \$label,
       -showPlaceholders => \$showPlaceholders,
       -showTree => \$showTree,
       -subTree => \$subTree,
       -validate => \$validate,
    );
    # @$argA;

    my $text = '';
    if ($showPlaceholders) {
        $text .= sprintf "--%s--\n",$a->str('bold red',$label);
        for (my $i = 0; $i < @$argA; $i += 2) {
            my $key = $argA->[$i];
            my $val = $argA->[$i+1];
            my $method = lc substr($key,0,2);
            my $bt = $self->$method($key);
            $text .= sprintf "%s = %s - %s%s\n",$key,
                defined($val)? "'$val'": 'undef',
                $bt->mandatory? $a->str('bold dark green','*').' ': '',
                $a->str('dark green',$bt->text);
        }
    }

    if ($subTree) {
        $subTree->resolvePlaceholders(
            '--',
            @$argA
        );
        return (0,'','');;
    }

    my ($sch,$rootType,$tree) = $self->get(qw/sch rootType tree/);

    # Wir operieren auf einer Kopie des Baums
    $tree = Quiq::Storable->clone($tree);

    $tree->resolvePlaceholders(
        '--',
        @$argA
    );
    $tree->reduceTree;

    if ($showTree) {
        $text .= "-----\n";
        $text .= Quiq::Dumper->dump($tree)."\n";
        $text .= "-----\n";
    }

    # (Leeren) XML-Baum instantiieren
    my $doc = XML::LibXML::Document->new('1.0','UTF-8');

    # Erzeuge XML-Writer

    my $wrt = $sch->compile(WRITER=>$rootType,
        validation => $validate,
        # Hiermit verhindern wir, dass x0 statt rsm als Präfix gesetzt wird
        prefixes => [rsm =>
            'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100'],
    );

    # Wandele den Baum nach XML. Auch wenn eine Validierung abgeschaltet
    # ist (s.o.), kann es passieren, dass der Writer eine Exception wirft.
    # Er schreibt dann auch eine Meldung nach STDERR, was störend ist.
    # Wir fangen beides mit folgendem Code ab.

    my $error = '';
    my $xml = do {
        local *STDERR;
        Quiq::FileHandle->captureStderr(\$error);
        eval {$wrt->($doc,$tree)};
    };
    $text .= $error;

    if ($@) {
        return (1,'',$text);
    }
    
    # Liefere das XML formatiert

    $xml =~ s/\x2//g; # CTRL-B herausfiltern => Quiq Fix
    return (0,Quiq::Xml->print($xml),$text);
}

# -----------------------------------------------------------------------------

=head3 template() - Liefere das ZUGFeRD-Template

=head4 Synopsis

  $xml = $zug->template;

=head4 Returns

(String) XML

=cut

# -----------------------------------------------------------------------------

# Accessor-Methode

# -----------------------------------------------------------------------------

=head3 toXml() - Liefere das Zugferd-XML einer Rechnung

=head4 Synopsis

  $xml = $zug->toXml($rch,%options);

=head4 Arguments

=over 4

=item $rch

(object) Rechnung

=back

=head4 Options

=over 4

=item -debug => $bool (Default: 0)

Gib Detailinformation auf STDOUT aus.

=back

=head4 Returns

(String) XML

=head4 Description

Erzeuge eine ZUGFeRD XML Repräsentation des Rechnungs-Objekts $rch
und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub toXml {
    my $self = shift;
    # @_: $rch,%options

    # Argumente und Optionen

    my $debug = 0;

    my $argA = $self->parameters(1,1,\@_,
        -debug => \$debug,
    );
    my $rch = shift @$argA;

    # Operation ausführen

    my $debugText = '';
    if ($debug) {
        my $a = Quiq::AnsiColor->new(1);
        $debugText .= sprintf "---%s---\n",$a->str('bold red','Objects');
        $debugText .= Quiq::Dumper->dump($rch);
        $debugText .= "---";
    }

    # Freitexte

    my $bg1 =  $self->processSubTree('BG-1',$rch->freitexte,sub {
        my ($zug,$t,$frt,$i) = @_;

        $zug->resolvePlaceholders(
            -subTree => $t,
            -showPlaceholders => $debug,
            -label => 'Freitext',
            '--',
            'BT-21' => $frt->code,
            'BT-22' => $frt->text,
        );

        return $t;
    });

    # Positionen

    my $bg25 = $self->processSubTree('BG-25',$rch->positionen,sub {
        my ($zug,$t,$pos,$i) = @_;

        # Artikelattribute

        my $path = 'SpecifiedTradeProduct.ApplicableProductCharacteristic';
        my $bg32 = $t->processSubTree($path,'BG-32',$pos->attribute,sub {
            my ($ztr,$t,$atr,$i) = @_;

            $t->resolvePlaceholders(
                -showPlaceholders => 0,
                '--',
                'BT-160' => $atr->name,
                'BT-161' => $atr->wert,
            );

            return $t;
        });

        my $proz = $pos->umsatzsteuersatz // '';

        $zug->resolvePlaceholders(
            -subTree => $t,
            -showPlaceholders => $debug,
            -label => 'Position',
            '--',
            'BT-126' => $pos->positionsnummer,
            'BT-153' => $pos->artikelname,
            'BT-154' => $pos->artikelbeschreibung,
            $pos->transferDate('abrechnungszeitraumVon','BT-134'),
            $pos->transferDate('abrechnungszeitraumBis','BT-135'),
            'BT-129' => $pos->menge,
            'BT-130' => $pos->einheit,
            'BT-146' => $pos->preisProEinheitNetto,
            'BT-131' => $pos->gesamtpreisNetto,
            'BT-152' => $proz,
            'BT-151' => $proz eq '0.00'? 'E': 'S',
            'BT-151-0' => 'VAT',
            # Artikelattribute
            'BG-32' => $bg32,
        );

        return $t;
    });

    # Umsatzsteuern

    my $bg23 = $self->processSubTree('BG-23',$rch->umsatzsteuern,sub {
        my ($zug,$t,$ums,$i) = @_;
 
        $zug->resolvePlaceholders(
           -subTree => $t,
           -showPlaceholders => $debug,
           -label => 'Umstzsteueraufschlüsselung',
           '--',
           'BT-117' => $ums->umsatzsteuerbetrag,
           'BT-118-0' => 'VAT',
           'BT-118' => $ums->umsatzsteuerkategorie,
           'BT-116' => $ums->summeBetraege,
           'BT-119' => $ums->prozentsatz,
           'BT-120' => $ums->befreiungsgrund,
       );

       return $t;
    });

    my ($status,$xml,$text) = $self->resolvePlaceholders(
        -label => 'Rechnung',
        -validate => !$debug,
        -showPlaceholders => $debug,
        -showTree => $debug,
        '--',
        # Rechnung (allgemeine Angaben)
        'BT-24' => $rch->profilKennung,
        'BT-3' => $rch->rechnungsart,
        'BT-1' => $rch->rechnungsnummer,
        $rch->transferDate('rechnungsdatum','BT-2'),
        'BT-5' => $rch->waehrung,
        'BT-10' => $rch->leitwegId,
        'BT-12' => $rch->vertragsnummer,
        'BT-20' => $rch->zahlungsbedingungen,
        $rch->transferDate('faelligkeitsdatum','BT-9'),
        'BT-82' => $rch->zahlungsmittel,
        'BT-83' => $rch->verwendungszweck,
        'BT-81' => $rch->zahlungsart,
        'BT-84' => $rch->iban,
        'BT-86' => $rch->bic,
        # Verkäufer
        'BT-27' => $rch->verkaeufer->name,
        'BT-38' => $rch->verkaeufer->plz,
        'BT-35' => $rch->verkaeufer->strasse,
        'BT-37' => $rch->verkaeufer->ort,
        'BT-40' => $rch->verkaeufer->land,
        'BT-14' => $rch->verkaeufer->auftragsreferenz,
        'BT-31' => $rch->verkaeufer->umsatzsteuerId,
        'BT-31-0' => 'VA',
        # Käufer (Zahler)
        'BT-44' => $rch->kaeufer->name,
        'BT-56' => $rch->kaeufer->kontakt,
        'BT-46' => $rch->kaeufer->kundennummer,
        'BT-50' => $rch->kaeufer->strasse,
        'BT-53' => $rch->kaeufer->plz,
        'BT-52' => $rch->kaeufer->ort,
        'BT-55' => $rch->kaeufer->land,
        'BT-13' => $rch->kaeufer->auftragsreferenz,
        'BT-48' => $rch->kaeufer->umsatzsteuerId,
        'BT-48-0' => $rch->kaeufer->umsatzsteuerId? 'VA': undef,
        # Empfänger
        'BT-70' => $rch->empfaenger->name,
        'BT-76' => $rch->empfaenger->kontakt,
        'BT-75' => $rch->empfaenger->strasse,
        'BT-78' => $rch->empfaenger->plz,
        'BT-77' => $rch->empfaenger->ort,
        'BT-80' => $rch->empfaenger->land,
        $rch->empfaenger->transferDate('lieferdatum','BT-72'),
        # Beträge
        'BT-106' => $rch->summePositionenNetto,
        'BT-109' => $rch->gesamtsummeNetto,
        'BT-110' => $rch->summeUmsatzsteuer,
        'BT-110-0' => $rch->waehrung,
        'BT-112' => $rch->gesamtsummeBrutto,
        'BT-115' => $rch->faelligerBetrag,
        # Freitexte
        'BG-1' => $bg1,
        # Positionen
        'BG-25' => $bg25,
        # Umsatzsteuern
        'BG-23' => $bg23,
    );
    $debugText .= $text;
    $debugText .= $self->checkAttributes($rch);

    # Allgemeine Regeln, nach denen Rechnungen aussortiert werden

    if ($rch->faelligerBetrag eq '0.00') {
        # FIXME: temporär inaktiviert
        # $status = 2;
        # $debugText .= "AUSSORTIERT: faelligerBetrag = '0.00'\nXS";
    }

    return ($status,$xml,$debugText);
}

# -----------------------------------------------------------------------------

=head3 tree() - Liefere den ZUGFeRD-Baum

=head4 Synopsis

  $tree = $zug->tree;

=head4 Returns

(Object) Baum

=head4 Example

  $ perl -MQuiq::Zugferd -MQuiq::Dumper -E '$t = Quiq::Zugferd->new("en16931")->tree; say Quiq::Dumper->dump($t)'

=cut

# -----------------------------------------------------------------------------

# Accessor-Methode

# -----------------------------------------------------------------------------

=head2 Information

=head3 bg() - Business Group

=head4 Synopsis

  $bg = $zug->bg($name);

=head4 Arguments

=over 4

=item $name

Name der Business Group. Beispiel: C<BG-25> (Rechnungsposition)

=back

=head4 Returns

(Object) Business Group

=head4 Description

Liefere die Business Group $name. Ist die Business Group nicht definiert,
wirf eine Exception.

Das Objekt hat die Attribute:

=over 4

=item name

Name der Business Group.

=item text

Kurzbeschreibung der Business Group.

=item path

Pfad zum Knoten im ZUGFeRD-Baum.

=back

=head4 Example

  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->new("en16931")->bg("BG-25")->path'
  SupplyChainTradeTransaction.IncludedSupplyChainTradeLineItem

=cut

# -----------------------------------------------------------------------------

sub bg {
    my ($self,$name) = @_;

    my $bgH = $self->memoize('bgH',sub {
        my ($self,$key) = @_;

        my %h;
        my $file = $self->zugferdDir('business-group.csv');
        my $fh = Quiq::FileHandle->new('<',$file);
        $fh->setEncoding('UTF-8');
        while (<$fh>) {
            if (/^\s*#/) {
                next;
            }
            chomp;
            my ($name,$mandatory,$text,$path) = split /;/;
            $h{$name} = Quiq::Hash->new(
                name => $name,
                mandatory => $mandatory,
                path => $path,
                text => $text,
            );
        }
        $fh->close;

        return \%h;
    });

    my $bg = $bgH->{$name} // $self->throw(
        'ZUGFERD-00099: Business group does not exist',
        BusinessGroup => $name,
    );

    return $bg;
}

# -----------------------------------------------------------------------------

=head3 bt() - Business Term(s)

=head4 Synopsis

  %bt | $btH = $zug->bt;
  $bt = $zug->bt($name);

=head4 Arguments

=over 4

=item $name

Name des Business Terms. Beispiel: C<BT-1> (Rechnungsnummer)

=back

=head4 Returns

(Object) Business Term

=head4 Description

Liefere den Business Term $name. Ist der Business Term nicht definiert,
wirf eine Exception.

Das Objekt hat die Attribute:

=over 4

=item name

Name des Business Terms.

=item mandatory

Pflichtfeldstatus. 0=optional, 1=XSD-Pflicht, 2=Mustang-Pflicht

=item text

Kurzbeschreibung des Business Terms.

=item attribute

Name des Objektattributs

=item path

Pfad zum Blattknoten im ZUGFeRD-Baum.

=back

=head4 Example

  $ perl -MQuiq::Zugferd -E 'say Quiq::Zugferd->new("en16931")->bt("BT-1")->text'
  Rechnungsnummer

=cut

# -----------------------------------------------------------------------------

sub bt {
    my ($self,$name) = @_;

    my $btH = $self->memoize('btH',sub {
        my ($self,$key) = @_;

        my %h;
        my $file = $self->zugferdDir('business-term.csv');
        my $fh = Quiq::FileHandle->new('<',$file);
        $fh->setEncoding('UTF-8');
        while (<$fh>) {
            if (/^\s*#/) {
                next;
            }
            chomp;
            my ($name,$mandatory,$attribute,$text) = split /;/;
            $h{$name} = Quiq::Hash->new(
                name => $name,
                attribute => $attribute,
                mandatory => $mandatory,
                text => $text,
                path => undef,
            );
        }
        $fh->close;

        $file = $self->zugferdDir('business-term-path.csv');
        $fh = Quiq::FileHandle->new('<',$file);
        $fh->setEncoding('UTF-8');
        while (<$fh>) {
            if (/^\s*#/) {
                next;
            }
            chomp;
            my ($name,$path) = split /;/;
            $h{$name}{'path'} = $path;
        }
        $fh->close;

        return \%h;
    });

    if (!$name) {
        my $h = $self->btH;
        return wantarray? %$h: $h;
    }

    my $bt = $btH->{$name} // $self->throw(
        'ZUGFERD-00099: Business term does not exist',
        BusinessGroup => $name,
    );

    return $bt;
}

# -----------------------------------------------------------------------------

=head3 zugferdDir() - Pfad des ZUGFeRD-Verzeichnisses

=head4 Synopsis

  $path = $zug->zugferdDir;
  $path = $zug->zugferdDir($subPath);

=head4 Arguments

=over 4

=item $subPath

Subpfad ins Verzeichnis

=back

=head4 Returns

(String) Dateipfad

=head4 Description

Liefere den Dateipfad des ZUGFeRD-Verzeichnisses, optional ergänzt um
Subpfad $subPath.

=cut

# -----------------------------------------------------------------------------

sub zugferdDir {
    my $self = shift;

    my $path = $self->{'zugferdDir'};
    if (@_) {
        $path .= "/$_[0]";
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head1 DETAILS

=head2 Vorgehen bei der Generierung einer ZUGFeRD E-Rechnung

Der Inhalt einer Rechnung setzt sich aus verschiedenen Bestandteilen
zusammen:

=over 2

=item *

Rechnungsdaten

=over 2

=item *

Allgemeine Rechnungsdaten

=item *

Rechnungsreferenzen

=back

=item *

Verkäufer

=over 2

=item *

Informationen zum Verkäufer

=item *

Steuervertreter des Verkäufers

=item *

Postanschrift des Verkäufers

=item *

Kontaktdaten des Verkäufers

=item *

Vom Verkäufer abweichender Zahlungsempfänger

=back

=item *

Käufer

=over 2

=item *

Informationen zum Käufer

=item *

Postanschrift des Käufers

=item *

Kontaktdaten des Käufers

=item *

Lieferinformation

=back

=item *

Rechnungspositionen

=over 2

=item *

Rechnungsposition

=item *

Weitere Daten zur Position

=item *

Nachlässe auf Ebene der Rechnungsposition

=item *

Zuschläge auf Ebene der Rechnungsposition

=back

=item *

Rechnungsbeträge

=over 2

=item *

Nachlässe auf Ebene der Rechnung

=item *

Zuschläge auf Ebene der Rechnung

=item *

Aufschlüsselung der Umsatzsteuer auf Ebene der Rechnung

=item *

Rechnungsbeträge

=back

=item *

Zahlungsdaten

=over 2

=item *

Zahlungsdaten

=item *

Zahlungsmittel: Überweisung

=item *

Zahlungsmittel: Lastschrift

=back

=item *

Anhänge

=item *

Verweise

=item *

Empfänger

=item *

Texte auf Rechnungs- und Positionsebene

=back

=head1 VERSION

1.232

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
