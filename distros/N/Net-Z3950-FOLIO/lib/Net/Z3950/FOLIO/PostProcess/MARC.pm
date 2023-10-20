package Net::Z3950::FOLIO::PostProcess::MARC;

use strict;
use warnings;
use utf8;

use MARC::Record;
use Net::Z3950::FOLIO::PostProcess::Transform qw(transform);


sub postProcessMARCRecord {
    my($cfg, $marc) = @_;

    return $marc if !$cfg;
    my $newMarc = new MARC::Record();
    $newMarc->leader($marc->leader());

    my @fields = gatherMarcFields($marc, $cfg);
    my %fieldCountByTag = ();
    foreach my $field (@fields) {
	my $tag = $field->tag();
	my $fieldCount = $fieldCountByTag{$tag} || 0;
	$fieldCountByTag{$tag} = $fieldCount+1;

	my $getFieldFromRecord = sub {
	    my($fieldname) = @_;

	    # Use the $fieldCount'th instance of field $tag only if substituting from the same field
	    return (marcFieldOrSubfield($newMarc, $fieldname, $fieldCount, $tag) ||
		    marcFieldOrSubfield($marc, $fieldname, $fieldCount, $tag) ||
		    '');
	};

	my $newField;
	if ($field->is_control_field())	{
	    my $value = $field->data();
	    my $rules = $cfg->{$tag};
	    $value = transform($rules, $value, $getFieldFromRecord) if $rules;
	    $newField = new MARC::Field($tag, $field->indicator(1), $field->indicator(2), $value) if $value ne '';
	} else {
	    foreach my $subfield ($field->subfields()) {
		my($key, $value) = @$subfield;
		my $rules = $cfg->{"$tag\$$key"};
		$value = transform($rules, $value, $getFieldFromRecord) if $rules;
		next if $value eq '';
		if (!$newField) {
		    $newField = new MARC::Field($tag, $field->indicator(1), $field->indicator(2), $key, $value);
		} else {
		    $newField->add_subfields($key, $value);
		}
	    }
	}

	$newMarc->append_fields($newField) if $newField;
    }

    return $newMarc;
}


# For the new record we're creating, we need all the fields (with
# their subfields) from the old record $marc, but also any that are
# created by the rules in $cfg. It's infuriating how we have to go all
# about the houses to make this happen.
#
sub gatherMarcFields {
    my($marc, $cfg) = @_;

    my %register;
    foreach my $field ($marc->fields()) {
	my $tag = $field->tag();
	$register{$tag} = $field;
    }

    my @fields = $marc->fields();
    foreach my $fieldname (sort keys %$cfg) {
	my($tag, $subtag) = ($fieldname =~ /(\d+)\$?(.*)/);
	if (!$subtag) {
	    if (!$register{$tag}) {
		push @fields, new MARC::Field($tag, '');
		#warn "added control-field $tag";
	    }
	} else {
	    my $field = $register{$tag};
	    if (!$field) {
		$register{$tag} = new MARC::Field($tag, ' ', ' ', $subtag, '');
		push @fields, $register{$tag};
		#warn "added regular field $tag with empty $subtag";
	    } else {
		if (!$field->subfield($subtag)) {
		    $field->add_subfields($subtag, '');
		    #warn "added empty $subtag to regular field $tag";
		}
	    }
	}
    }

    return @fields;
}


sub marcFieldOrSubfield {
    my($marc, $fieldname, $index, $useIndexIfmatchTag) = @_;

    my($tag, $subtag) = ($fieldname =~ /(\d+)\$?(.*)/);
    $index = 0 if defined $useIndexIfmatchTag && $tag ne $useIndexIfmatchTag;
    my @fields = $marc->field($tag);
    my $field = $fields[$index || 0];
    return undef if !$field;
    return $subtag ? $field->subfield($subtag) : $field->data();
}


use Exporter qw(import);
our @EXPORT_OK = qw(postProcessMARCRecord marcFieldOrSubfield);


1;
