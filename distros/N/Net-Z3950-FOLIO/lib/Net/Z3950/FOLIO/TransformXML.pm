package Net::Z3950::FOLIO::TransformXML;

use strict;
use warnings;

use XML::XSLT;


sub transformXMLRecord {
    my($cfg, $rec, $comp) = @_;

    return undef if !$cfg->{xmlElementSets};
    my $xsltText = $cfg->{xmlElementSets}->{$comp};
    #warn "*** xsltText = ", $xsltText;
    return undef if !$xsltText;

    #warn "*** comp=$comp, rec=$rec ==", $rec;
    my $xslt = XML::XSLT->new(Source => \$xsltText, warnings => 1);
    #warn "xslt = $xslt";
    my $raw = $rec->prettyXML();
    #warn "raw = $raw";
    my $dom = $xslt->transform(\$raw);
    #warn "dom = $dom";
    my $transformed = $dom->toString;
    #warn "transformed = $transformed";
    $xslt->dispose();

    return $transformed;
}


use Exporter qw(import);
our @EXPORT_OK = qw(transformXMLRecord);


1;
