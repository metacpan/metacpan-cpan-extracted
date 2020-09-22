package Net::Z3950::FOLIO::OPACXMLRecord;

use strict;
use warnings;

sub makeOPACXMLRecord {
    my($ihi, $marc) = @_;
    my $marcXML = $marc->as_xml_record();

    # The first line of $marcXML is an XML declaration, and there
    # seems to be no way to have MARC::File::XML omit this, so we just
    # snip it off.
    $marcXML =~ s/.*?\n//m;

    # Indent to fit into the record nicely
    $marcXML =~ s/^/    /gm;

    my $holdings = _makeHoldingsRecords($ihi->{holdingsRecords2}, $marc);
    my $holdingsRecords = join('\n', @$holdings);

    return _makeXMLElement(0, 'opacRecord', (
        [ 'bibliographicRecord', $marcXML, undef, 1 ],
        [ 'holdings', $holdingsRecords, undef, 1 ],
    ));
}

sub _makeHoldingsRecords {
    my($holdings, $marc) = @_;
    return [ map { _makeSingleHoldingsRecord($_, $marc) } @$holdings ];
}


# The YAZ XML format for OPAC records is a fairly close representation
# of the Z39.50 OPAC record, which is specified by the ASN.1 at
# https://www.loc.gov/z3950/agency/asn1.html#RecordSyntax-opac
#
# But this is only very lightly documented. Some of the fields are
# commented with what seem to be references to the MARC format,
# e.g. `typeOfRecord` is commented "LDR 06", which is indeed "Type of
# record" is the MARC specification: see
# https://www.loc.gov/marc/bibliographic/bdleader.html
# But why would we include information from the MARC record describing
# the bibliographic data related to the holding when we already have
# the actual MARC record in <bibliographicRecord>?
#
# Based on the document "z39.50 OPAC response examples for Cornell"
# attached to UXPROD-560, it seems like the key elements to fill in
# are:
#	format
#	localLocation
#	shelvingLocation
#	callNumber
#	enumAndChron
#	availableNow
#	availabilityDate
#	availableThru
#	itemId
#	temporaryLocation (overrides shelvingLocation)
#
# In the FOLIO data model, <enumAndChron> does not exist at the
# holdings or volume level, only at the item level.
#
sub _makeSingleHoldingsRecord {
    my($holding, $marc) = @_;

    my $nucCode;
    my $localLocation;
    my $shelvingLocation;
    my $location = $holding->{temporaryLocation} || $holding->{permanentLocation};
    if ($location) {
	$nucCode = ($location->{institution} || {})->{name};
	$localLocation = ($location->{campus} || {})->{name};
	$shelvingLocation = ($location->{library} || {})->{name};
    }

    my $items = _makeItemRecords($holding->{holdingsItems});

    return _makeXMLElement(4, 'holding', (
        [ 'typeOfRecord', substr($marc->leader(), 5, 1) ], # LDR 06
        [ 'encodingLevel', substr($marc->leader(), 16, 1) ], # LDR 017
        [ 'format', _format($holding, $marc) ],
        [ 'receiptAcqStatus', _marcFieldChars($marc, '008', '06') ],
        [ 'generalRetention', _marcFieldChars($marc, '008', '12') ],
        [ 'completeness', _marcFieldChars($marc, '008', '16') ],
        [ 'dateOfReport', _marcFieldChars($marc, '008', '26-31') ],
        [ 'nucCode', $nucCode ],
        [ 'localLocation', $localLocation ],
        [ 'shelvingLocation', $shelvingLocation ],
        # Z39.50 OPAC record has no way to express item-level callNumber
        [ 'callNumber', $holding->{callNumber} ],
        [ 'shelvingData', _makeShelvingData($holding) ],
        [ 'copyNumber', $holding->{copyNumber} ], # 852 $t
        [ 'publicNote', _noteOfType($holding->{notes}, qr/public/i) ], # 852 $z
        [ 'reproductionNote', _noteOfType($holding->{notes}, qr/reproduction/i) ], # 843
        [ 'termsUseRepro', _makeTermsUseRepro($marc) ], # 845
        [ 'circulations', join('\n', @$items), undef, 1 ],
    ));
}


sub _marcFieldChars {
    my($marc, $fieldName, $chars) = @_;
    my $field = $marc->field($fieldName);
    return undef if !$field;
    my $data = $field->data();
    return undef if !$data;

    my @pieces = split(/-/, $chars);
    my($start1, $end1) = @pieces;
    $end1 = $start1 if !$end1;
    return substr($data, $start1-1, $end1-$start1+1);
}


# I don't really know what they want of me here. The "documentation",
# found only in the OPAC record-format ASN-1, simply says "852 $j thru
# $m". But these fields mostly just duplicate the call-number:
#
#	$j - Shelving control number (NR)
#	$k - Call number prefix (R)
#	$l - Shelving form of title (NR)
#	$m - Call number suffix (R)
#
# Since the only thing we have that is _not_ part of the call-number
# is the shelving title, I guess we may as well return that.

sub _makeShelvingData {
    my($holding) = @_;
    return $holding->{shelvingTitle};
}


# In the FOLIO inventory model, instances, holdings records and items
# can all have a set of zero or more notes, each of which has a note
# type. These note types are drawn from three separate vocabularies
# (one each for instances, holdings records and items), each
# maintained in the Settings rather than hardwired like identifier
# types. Among these vocabularies, there may be (and in the sample
# data there are) types called "Reproduction" and "Public". So we can
# pick these out by referring to the note-type text rather than to
# known UUIDS -- and pull out the text of notes of the appropriate
# type.
#
# For this to work, though, we will need mod-graphql to populate the
# note-type objects.
#
sub _noteOfType {
    my($notes, $regexp) = @_;

    foreach my $note (@$notes) {
	my $type = $note->{holdingsNoteType};
	return $note->{note} if $type && $type->{name} =~ $regexp;
    }
    return undef;
}


# The ASN.1 one relates this OPAC-record field to MARC field 845,
# which is "Terms Governing Use and Reproduction Note". That field has
# 13 subfields, and there is no guidance on which might be
# relevant. The best we can do is probably just to glue them all
# together.
#
sub _makeTermsUseRepro {
    my($marc) = @_;

    my $field845 = $marc->field('845') or return undef;
    my @subfields = $field845->subfields() or return undef;
    return join('', map { '$' . $_->[0] . $_->[1] } @subfields);
}


sub _makeItemRecords {
    my($items) = @_;
    return [ map { _makeSingleItemRecord($_) } @$items ];
}


sub _makeSingleItemRecord {
    my($item) = @_;

    my @tmp;
    push @tmp, $item->{enumeration} if $item->{enumeration};
    push @tmp, $item->{chronology} if $item->{chronology};
    my $enumAndChronForItem = @tmp ? join(' ', @tmp) : undef;

    return _makeXMLElement(8, 'circulation', (
	[ 'availableNow', $item->{status} && $item->{status}->{name} eq 'Available' ? 1 : 0, 'value' ],
	[ 'availabilityDate', _makeAvailabilityDate($item) ],
        [ 'availableThru', _makeAvailableThru($item) ],
        [ 'restrictions', _makeRestrictions($item) ],
        [ 'itemId', $item->{hrid} ],
	# XXX Determining a correct value for <renewable> would be
	# very complicated, involving loan policies. But we have to
	# include _something_, because this element is mandatory in
	# YAZ's OPACXML schema -- probably accidentally
        [ 'renewable', '', 'value' ],
        [ 'onHold', _makeOnHold($item), 'value' ],
        [ 'enumAndChron', $enumAndChronForItem ],
        [ 'midspine', undef ], # XXX Will be added in UIIN-220 but doesn't exist yet
        [ 'temporaryLocation', _makeLocation($item->{temporaryLocation}) ],
    ));
}


# We _could_ make an attempt to get a holdings-level format, but to do
# that we would need to have mod-graphql expand the the
# `holdingsTypeId` field into a holdings-type object, and somehow
# interpret a field from within that structure into the MARC 007/0-1
# controlled vocabulary. That's a lot of work for little gain, so we
# just use the information from the MARC record.

sub _format {
    my($holding, $marc) = @_;

    my $field007 = $marc->field('007');
    return undef if !defined $field007;
    my $data = $field007->data();
    return substr($data, 0, 2);
}


# Availability Date is not in the FOLIO inventory data. It should be
# possible to obtain it as the Due Date in mod-circulation, if we want
# to add the necessary extra queries.
#
sub _makeAvailabilityDate {
    my($item) = @_;
    return undef; # XXX for now
}


# It's anyone's guess what the <availableThru> field even means. It's
# included in the name, without comment, in the Z39.50 ASN.1 and in
# the YAZ OPAC XML schema.
#
# * I first thought it meant "Date until which the item is guaranteed
#   to remain available".
# * Examples in the document "z39.50 OPAC response examples for
#   Cornell" attached to UXPROD-560 suggests that it's the opaque
#   identifier of a loan policy.
# * A brief note in the document "Kuali OLE Z39.50 Integration -
#   DRAFT" suggests it means "Library building location, or possibly
#   access policy".
#
# Whatever it means, it is probably not in the FOLIO inventory
# data. It may become possible to determine it in future, when the
# current item status gets broken into three item statuses
# (availability status, process status and needed-for status, but that
# will have to wait).
# See https://docs.google.com/presentation/d/11BE_G1o-yBNg1ki8HyaDTdmkrP03_cR7KGjiXQviwuQ/edit#slide=id.g8b76928899_0_0
#
sub _makeAvailableThru {
    my($item) = @_;
    return undef; # XXX for now
}


# The restrictions, if any, can be inferred from some values of
# status. Charlotte says "I would say all of them except: Available,
# and On order". She will check with out contacts at Lehigh.
#
# The list of valid statuses is wired right into the JSONN Schema at
# mod-inventory-storage/ramls/item.json
#
sub _makeRestrictions {
    my($item) = @_;

    my $status = $item->{status} || return undef;
    my $name = $status->{name} || return undef;
    return ($name ne 'Available' && $name ne 'On order') ? $name : undef;
}


# Items don't know whether they are on hold, but the requests module
# does. We can discover this by another request (or, more likely, by
# having mod-graphql include the results of another request). The
# relevant WSAPI is documented at
# https://github.com/folio-org/mod-circulation/blob/cab5ab44a3383bad938f33ad616fb0ef1244e67a/ramls/circulation.raml#L278
#
# But we have to provide a non-undef value here, because this element
# is mandatory in YAZ's OPACXML schema -- probably accidentally.
#
sub _makeOnHold {
    my($item) = @_;
    return ''; # XXX for now
}


sub _makeLocation {
    my($data) = @_;
    return undef if !defined $data;

    my @tmp;
    foreach my $key (qw(institution campus library primaryServicePointObject)) {
	push @tmp, $data->{$key}->{name} if $data->{$key};
    }
    return join('/', @tmp);
}


sub _makeXMLElement {
    my($indentLevel, $elementName, @elements) = @_;

    my $indent = ' ' x $indentLevel;
    my $xml = "$indent<$elementName>\n";
    foreach my $element (@elements) {
	my($name, $value, $attr, $isPreAssembledXML) = @$element;
	next if !defined $value;

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
