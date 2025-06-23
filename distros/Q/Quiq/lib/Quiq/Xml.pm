# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Xml - Allgemeine XML-Operationen

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::Xml;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use XML::Twig ();
use Quiq::Path;
use XML::Compile::Schema ();
use XML::LibXML ();
use XML::Compile::Util ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 print() - Formatiere XML

=head4 Synopsis

  $xmlFormatted = $this->print($xml);

=head4 Returns

XML als formatierte Zeichenkette

=head4 Description

Liefere XML-Code $xml als formtierte Zeichenkette mit Einrückung.

=head4 Example

  say Quiq::Xml->print($xml);

=cut

# -----------------------------------------------------------------------------

sub print {
    my ($this,$xml) = @_;

    my $twg = XML::Twig->new(pretty_print=>'indented');
    $twg->parsestring($xml);

    return $twg->sprint;
}

# -----------------------------------------------------------------------------

=head3 xmlToTree() - Wandele XML in Baum

=head4 Synopsis

  $tree = $this->xmlToTree($xml,%opt);
  $tree = $this->xmlToTree($file,%opt);

=head4 Arguments

=over 4

=item $xml

XML Code als Zeichenkette

=item $file

Datei mit XML Code

=back

=head4 Options

=over 4

=item -xsdDir => $xsdDir (Default: $ENV{'XSD_DIR'} // '.')

]:
Verzeichnis mit XML Schema Definitionsdateien (.xsd).

=back

=head4 Returns

(Perl Datenstruktur) Baum

=head4 Description

Wandele den XML Code $xml in eine hierarchische Perl-Datenstruktur
(Baum) und liefere eine Referenz auf diese Struktur zurück.

=head4 Example

  $ perl -MQuiq::Xml -E 'Quiq::Xml->xmlToTree("02-taxifahrt-orig.xml",-xsdDir=>"~/dat/zugferd")'

=cut

# -----------------------------------------------------------------------------

sub xmlToTree {
    my ($class,$xml) = splice @_,0,2;
    # @_: %opt

    # Optionen

    my $xsdDir = $ENV{'XSD_DIR'} // '.';

    $class->parameters(\@_,
        -xsdDir => \$xsdDir,
    );

    # Operation ausführen

    if ($xml !~ /</) {
        $xml = Quiq::Path->read($xml,-decode=>'utf-8');
    }

    # #-Kommentarzeilen entfernen
    $xml =~ s/^\s*#.*$//gm;

    # Ermittele die .xsd-Dateien
    my @xsdFiles = Quiq::Path->find($xsdDir,-pattern=>'\.xsd$');

    # Instantiiere das Schema-Objekt

    my $sch = XML::Compile::Schema->new;
    for my $file (@xsdFiles) {
        $sch->importDefinitions($file);
    }

    my $doc = XML::LibXML->load_xml(
        string => $xml,
        no_blanks => 1,
    );
    my $top = $doc->documentElement;
    my $rootType = XML::Compile::Util::type_of_node($top);

    # Instantiiere XML-Reader
    my $rdr = $sch->compile(READER=>$rootType,
        sloppy_floats => 1, # Wir wollen keine BigFloat-Elemente
        sloppy_integers => 1, # Wir wollen keine BigInt-Elemente
    );

    # Erzeuge Baum
    my $tree = $rdr->($doc);

    return $tree;
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
