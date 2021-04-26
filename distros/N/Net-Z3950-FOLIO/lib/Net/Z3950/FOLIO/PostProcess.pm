package Net::Z3950::FOLIO::PostProcess;

use strict;
use warnings;
use utf8;

use Data::Dumper;
use Unicode::Diacritic::Strip 'fast_strip';


sub postProcessMARCRecord {
    my($cfg, $marc) = @_;

    return $marc if !$cfg;
    my $newMarc = new MARC::Record();
    $newMarc->leader($marc->leader());

    foreach my $field ($marc->fields()) {
	my $tag = $field->tag();

	my $newField;
	if ($field->is_control_field())	{
	    my $value = $field->data();
	    my $rules = $cfg->{$tag};
	    $value = transform($rules, $value) if $rules;
	    $newField = new MARC::Field($tag, $field->indicator(1), $field->indicator(2), $value);
	} else {
	    foreach my $subfield ($field->subfields()) {
		my($key, $value) = @$subfield;
		my $rules = $cfg->{"$tag\$$key"};
		$value = transform($rules, $value) if $rules;
		if (!$newField) {
		    $newField = new MARC::Field($tag, $field->indicator(1), $field->indicator(2), $key, $value);
		} else {
		    $newField->add_subfields($key, $value);
		}
	    }

	    die "can't transform empty field", $field if !$newField;
	}

	$newMarc->append_fields($newField);
    }

    return $newMarc;
}


sub transform {
    my($cfg, $value) = @_;

    if (ref $cfg eq 'HASH') {
	# Single transformation
	return applyRule($cfg, $value);
    } else {
	# List of transformations
	foreach my $rule (@$cfg) {
	    $value = applyRule($rule, $value);
	}
	return $value;
    }
}


sub applyRule {
    my($rule, $value) = @_;

    my $op = $rule->{op};
    if ($op eq 'stripDiacritics') {
	return applyStripDiacritics($rule, $value);
    } elsif ($op eq 'regsub') {
	return applyRegsub($rule, $value);
    } else {
	die "unknown post-processing op '$op'";
    }
}


sub applyStripDiacritics {
    my($_rule, $value) = @_;

    my $result = $value;

    # Extra special case: needs handling first, as fast_strip converts ipper-case thorn to "th"
    $result =~ s/Þ/TH/g;

    # It seems that the regular strip_diacritics function just plain no-ops, hence fast_strip instead
    $result = fast_strip($result);

    # Special cases required in ZF-31, but apparently not implemented by fast_strip
    $result =~ s/ß/ss/g;
    $result =~ s/ẞ/SS/g;
    $result =~ s/Đ/D/g;
    $result =~ s/ð/d/g;
    $result =~ s/Æ/AE/g;
    $result =~ s/æ/ae/g;
    $result =~ s/Œ/OE/g; # For some reason, fast_strip handle the lower-case version but not the upper-case

    # warn "stripping diacritics: '$value' -> '$result'";
    return $result;
}


sub applyRegsub {
    my($rule, $value) = @_;

    my $pattern = $rule->{pattern};
    my $replacement = $rule->{replacement};
    my $flags = $rule->{flags} || "";
    my $res = $value;

    # See advice on this next part at https://perlmonks.org/?node_id=11124218
    # In this approach, we construct some Perl code and evaluate it.
    # This may leave some security holes, but we trust the people who write config files
    $pattern =~ s;/;\\/;g;
    $replacement =~ s;/;\\/;g;
    eval "\$res =~ s/$pattern/$replacement/$flags";
    # warn "regsub '$value' by s/$pattern/$replacement/$flags -> '$res'";
    return $res;
}


use Exporter qw(import);
our @EXPORT_OK = qw(postProcess postProcessMARCRecord transform applyRule applyStripDiacritics applyRegsub);


1;
