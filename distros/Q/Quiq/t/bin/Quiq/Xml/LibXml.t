#!/usr/bin/env perl

package Quiq::Xml::LibXml::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;
use utf8;

use Quiq::Unindent;
use XML::LibXML ();

# -----------------------------------------------------------------------------

sub test_unitTest : Test(4) {
    my $self = shift;

    # Klasse laden

    if ($] < 5.018) {
        # Fix: CPAN Testers
        $self->skipTest('XML::LibXML - problematisch bei dieser Perl-Version');
        return;
    }
    $self->useOk('Quiq::Xml::LibXml');

    # 1. Einlesen

    my $xml1 = Quiq::Unindent->string(q|
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <DATEI>
      <FORDERUNG>
        <VERPFLICHTUNG>
          <PERSON>
          </PERSON>
        </VERPFLICHTUNG>
      </FORDERUNG>
    </DATEI>
    |);

    my $doc = XML::LibXML->load_xml(
        string => $xml1,
        no_blanks => 1,
    );

    my $xml2;
    if ($XML::LibXML::VERSION == 1.70) {
        # EOS-Version (alt)

        $xml2 = Quiq::Unindent->string(q|
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <DATEI>
          <FORDERUNG>
            <VERPFLICHTUNG>
              <PERSON>
              </PERSON>
            </VERPFLICHTUNG>
          </FORDERUNG>
        </DATEI>
        |);
    }
    else {
        # neuere Versionen > 2 (?)

        $xml2 = Quiq::Unindent->string(q|
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <DATEI>
          <FORDERUNG>
            <VERPFLICHTUNG>
              <PERSON/>
            </VERPFLICHTUNG>
          </FORDERUNG>
        </DATEI>
        |);
    }
    $self->is($doc->toFormattedString,$xml2);

    # 2. Knoten hinzufügen

    for my $per ($doc->findnodes('//PERSON')) {
        my $nam = $doc->createElement('NACHNAME');
        $nam->appendText('Müller');
        $per->appendChild($nam);

        $per->appendWellBalancedChunk(
            '<VORNAME>Lieschen</VORNAME>',
        );
    }

    my $xml3;
    if ($XML::LibXML::VERSION == 1.70) {
        # EOS-Version (alt) - Formatierung kaputt

        $xml3 = Quiq::Unindent->string(q|
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <DATEI>
          <FORDERUNG>
            <VERPFLICHTUNG>
              <PERSON>
              <NACHNAME>Müller</NACHNAME><VORNAME>Lieschen</VORNAME></PERSON>
            </VERPFLICHTUNG>
          </FORDERUNG>
        </DATEI>
        |);
    }
    else {
        # neuere Versionen > 2 (?)

        $xml3 = Quiq::Unindent->string(q|
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <DATEI>
          <FORDERUNG>
            <VERPFLICHTUNG>
              <PERSON>
                <NACHNAME>Müller</NACHNAME>
                <VORNAME>Lieschen</VORNAME>
              </PERSON>
            </VERPFLICHTUNG>
          </FORDERUNG>
        </DATEI>
        |);
    }
    $self->is($doc->toFormattedString,$xml3);

    # 3. Knoten löschen

    my ($per) = $doc->findnodes('//PERSON');
    $per->removeNode;

    my $xml4 = Quiq::Unindent->string(q|
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <DATEI>
      <FORDERUNG>
        <VERPFLICHTUNG/>
      </FORDERUNG>
    </DATEI>
    |);
    $self->is($doc->toFormattedString,$xml4);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Xml::LibXml::Test->runTests;

# eof
