package Net::Z3950::FOLIO::OPACXMLRecord;

use strict;
use warnings;

use Net::Z3950::FOLIO::HoldingsRecords qw(makeHoldingsRecords);


sub makeOPACXMLRecord {
    my($ihi, $marc) = @_;
    my $marcXML = $marc->as_xml_record();

    # The first line of $marcXML is an XML declaration, and there
    # seems to be no way to have MARC::File::XML omit this, so we just
    # snip it off.
    $marcXML =~ s/.*?\n//m;

    # Indent to fit into the record nicely
    $marcXML =~ s/^/    /gm;

    my $holdingsObjects = makeHoldingsRecords($ihi->{holdingsRecords2}, $marc);
    my $holdingsRecords = _resolveHoldingsToXML($holdingsObjects);

    return _makeXMLElement(0, 'opacRecord', (
        [ 'bibliographicRecord', $marcXML, undef, 1 ],
        [ 'holdings', $holdingsRecords, undef, 1 ],
    ));
}


sub _resolveHoldingsToXML {
    my($holdingsObjects) = @_;

    foreach my $holding (@$holdingsObjects) {
	for (my $i = 0; $i < @$holding; $i++) {
	    my $elem = $holding->[$i];
	    my($name, $value) = @$elem;
	    if ($name eq 'circulations') {
		my @acc;
		for (my $j = 0; $j < @$value; $j++) {
		    my $circulation = $value->[$j];
		    push @acc, _makeXMLElement(8, 'circulation', @$circulation);
		}
		# XXX I am not ecstatic about overwriting this in place
		$elem->[1] = join('', @acc);
	    }
	}
    }

    my @holdingsXML = map { _makeXMLElement(4, 'holding', @$_) } @$holdingsObjects;
    return join('\n', @holdingsXML);
}


sub _makeXMLElement {
    my($indentLevel, $elementName, @elements) = @_;

    my $indent = ' ' x $indentLevel;
    my $xml = "$indent<$elementName>\n";
    foreach my $element (@elements) {
	my($name, $value, $attr, $isPreAssembledXML) = @$element;
	next if $name =~ /^_/ || !defined $value;

	my $added;
	if ($attr) {
	    my $quotedValue = _quoteXML($value);
	    $added = qq[<$name $attr="$quotedValue" />\n];
	} elsif (!$isPreAssembledXML) {
	    my $quotedValue = _quoteXML($value);
	    $added = qq[<$name>$quotedValue</$name>\n];
	} else {
	    $added = qq[<$name>\n$value$indent  </$name>\n];
	}
	# warn "name=$name, value=$value, attr=$attr, added=$added";
	$xml .= "$indent  $added";
    }
    $xml .= "$indent</$elementName>\n";
}


sub _quoteXML {
    my($s) = @_;

    return '' if !defined $s;
    $s =~ s/&/&amp;/sg;
    $s =~ s/</&lt;/sg;
    $s =~ s/>/&gt;/sg;
    $s =~ s/"/&quot;/sg;

    return $s
}


use Exporter qw(import);
our @EXPORT_OK = qw(makeOPACXMLRecord);


1;
