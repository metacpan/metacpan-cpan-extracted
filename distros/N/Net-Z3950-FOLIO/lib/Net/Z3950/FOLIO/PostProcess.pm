package Net::Z3950::FOLIO::PostProcess;

use strict;
use warnings;
use utf8;

use Data::Dumper;
use MARC::Record;
use Unicode::Diacritic::Strip 'fast_strip';


sub postProcessMARCRecord {
    my($cfg, $marc) = @_;

    return $marc if !$cfg;
    my $newMarc = new MARC::Record();
    $newMarc->leader($marc->leader());

    my @fields = gatherFields($marc, $cfg);
    foreach my $field (@fields) {
	my $tag = $field->tag();

	my $newField;
	if ($field->is_control_field())	{
	    my $value = $field->data();
	    my $rules = $cfg->{$tag};
	    $value = transform($rules, $value, $marc, $newMarc) if $rules;
	    $newField = new MARC::Field($tag, $field->indicator(1), $field->indicator(2), $value) if $value ne '';
	} else {
	    foreach my $subfield ($field->subfields()) {
		my($key, $value) = @$subfield;
		my $rules = $cfg->{"$tag\$$key"};
		$value = transform($rules, $value, $marc, $newMarc) if $rules;
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
# creates by the rules in $cfg. It's infuriating how we have to go all
# about the houses to make this happen.
#
sub gatherFields {
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


sub transform {
    my($cfg, $value, $marc, $newMarc) = @_;

    if (ref $cfg eq 'HASH') {
	# Single transformation
	return applyRule($cfg, $value, $marc, $newMarc);
    } else {
	# List of transformations
	foreach my $rule (@$cfg) {
	    $value = applyRule($rule, $value, $marc, $newMarc);
	}
	return $value;
    }
}


sub applyRule {
    my($rule, $value, $marc, $newMarc) = @_;

    my $op = $rule->{op};
    if ($op eq 'stripDiacritics') {
	return applyStripDiacritics($rule, $value);
    } elsif ($op eq 'regsub') {
	return applyRegsub($rule, $value, $marc, $newMarc);
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
    my($rule, $value, $marc, $newMarc) = @_;

    my $pattern = $rule->{pattern};
    my $rawReplacement = $rule->{replacement};
    my $flags = $rule->{flags} || "";
    my $res = $value;

    my $replacement = substituteReplacement($rawReplacement, $marc, $newMarc);

    # See advice on this next part at https://perlmonks.org/?node_id=11124218
    # In this approach, we construct some Perl code and evaluate it.
    # This may leave some security holes, but we trust the people who write config files
    $pattern =~ s;/;\\/;g;
    $replacement =~ s;/;\\/;g;
    eval "\$res =~ s/$pattern/$replacement/$flags";
    # warn "regsub '$value' by s/$pattern/$replacement/$flags -> '$res'";
    return $res;
}


sub substituteReplacement {
    my($raw, $marc, $newMarc) = @_;

    my $res = '';
    while ($raw =~ /(.*?)\%\{(.*?)\}(.*)/) {
	my($pre, $fieldname, $post) = ($1, $2, $3);
	# warn "pre='$pre', fieldname='$fieldname', post='$post'";
	$res .= $pre . insertField($fieldname, $marc, $newMarc);
	$raw = $post;
    }
    $res .= $raw;

    return $res;
}


# As usual, we have to deal with the complication that $fieldname
# might be simply of the form /\d\d\d/ for a control-field or
# /\d\d\d\$./ for a subfield of a regular field. To make things more
# complex still, we want the value of field-or-subfield from $newMarc
# if it already exists there, and from the old $marc otherwise.
sub insertField {
    my($fieldname, $marc, $newMarc) = @_;

    return (fieldOrSubfield($newMarc, $fieldname) ||
	    fieldOrSubfield($marc, $fieldname) ||
	    '');
}


sub fieldOrSubfield {
    my($marc, $fieldname) = @_;

    my($tag, $subtag) = ($fieldname =~ /(\d+)\$?(.*)/);
    if ($subtag) {
	return $marc->subfield($tag, $subtag);
    } else {
	my $field = $marc->field($tag);
	return $field ? $field->data() : undef;
    }
}


use Exporter qw(import);
our @EXPORT_OK = qw(postProcess postProcessMARCRecord transform applyRule applyStripDiacritics applyRegsub fieldOrSubfield);


1;
