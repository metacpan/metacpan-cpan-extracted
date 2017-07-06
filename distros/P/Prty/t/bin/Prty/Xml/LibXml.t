#!/usr/bin/env perl

package Prty::Xml::LibXml::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::Xml::LibXml');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Test(3) {
    my $self = shift;

    # 1. Einlesen

    my $xml1 = Prty::Unindent->string(q|
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

        $xml2 = Prty::Unindent->string(q|
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

        $xml2 = Prty::Unindent->string(q|
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

    # 2. Knoten hinzfügen

    for my $per ($doc->findnodes('//PERSON')) {
        printf "%s\n",$per->localname;

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

        $xml3 = Prty::Unindent->string(q|
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

        $xml3 = Prty::Unindent->string(q|
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

    my $xml4 = Prty::Unindent->string(q|
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
Prty::Xml::LibXml::Test->runTests;

# eof
