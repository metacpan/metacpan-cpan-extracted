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

our $VERSION = '1.228';

use Quiq::PerlModule;
use Quiq::Path;
use Quiq::Zugferd::Tree;
use Quiq::Dumper;
use XML::Compile::Schema ();
use XML::LibXML ();
use XML::Compile::Util ();
use Quiq::Storable;
use Quiq::AnsiColor;
use Quiq::Xml;
use Quiq::FileHandle;
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

=head3 processSubTree() - Verarbeite einen Subbaum

=head4 Synopsis

  $xmlA = $zug->processSubTree($name,\@arr,sub {
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

Liste der Elemente, aus denen die Platzhalter im Subbaum
ersetzt werden.

=item sub {}

Subroutine, die die Einsetzung in einen Subbaum vornimmt

=back

=head4 Returns

(Object) Subbaum mit ersetzen Platzhaltern

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

  $xml = $zug->resolvePlaceholders(@keyVal,%options);

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

(String) XML nach Platzhalter-Ersetzung

=head4 Description

Ersetze die Platzhalter im Template des ZUGFeRD-Profils und liefere
das resultierende XML zurück.

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

    if ($showPlaceholders) {
        printf "--%s--\n",$a->str('bold red',$label);
        for (my $i = 0; $i < @$argA; $i += 2) {
            my $key = $argA->[$i];
            my $val = $argA->[$i+1];
            my $method = lc substr($key,0,2);
            my $bt = $self->$method($key);
            printf "%s = %s - %s%s\n",$key,defined($val)? "'$val'": 'undef',
                $bt->mandatory? $a->str('bold dark green','*').' ': '',
                $a->str('dark green',$bt->text);
        }
    }

    if ($subTree) {
        $subTree->resolvePlaceholders(
            '--',
            @$argA
        );
        return;
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
        say '-----';
        say Quiq::Dumper->dump($tree);
        say '-----';
    }

    # (Leeren) XML-Baum instantiieren
    my $doc = XML::LibXML::Document->new('1.0','UTF-8');

    # Instantiiere XML-Writer

    my $wrt = $sch->compile(WRITER=>$rootType,
        validation => $validate,
        # Hiermit verhindern wir, dass x0 statt rsm als Präfix gesetzt wird
        prefixes => [rsm =>
            'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100'],
    );

    # Wandele den Baum in XML
    my $xml = $wrt->($doc,$tree);
    

    # Liefere das XML formatiert
    return Quiq::Xml->print($xml);
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

=head3 bt() - Business Term

=head4 Synopsis

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

=item text

Kurzbeschreibung des Business Terms.

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
            my ($name,$mandatory,$text) = split /;/;
            $h{$name} = Quiq::Hash->new(
                name => $name,
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
