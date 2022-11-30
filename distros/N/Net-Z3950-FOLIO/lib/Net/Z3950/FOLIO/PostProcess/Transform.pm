package Net::Z3950::FOLIO::PostProcess::Transform;

use strict;
use warnings;
use utf8;

use Unicode::Diacritic::Strip 'fast_strip';


sub transform {
    my($cfg, $value, $getFieldFromRecord) = @_;

    if (ref $cfg eq 'HASH') {
	# Single transformation
	return applyRule($cfg, $value, $getFieldFromRecord);
    } else {
	# List of transformations
	foreach my $rule (@$cfg) {
	    $value = applyRule($rule, $value, $getFieldFromRecord);
	}
	return $value;
    }
}


sub applyRule {
    my($rule, $value, $getFieldFromRecord) = @_;

    my $op = $rule->{op};
    if ($op eq 'stripDiacritics') {
	return applyStripDiacritics($rule, $value);
    } elsif ($op eq 'regsub') {
	return applyRegsub($rule, $value, $getFieldFromRecord);
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
    my($rule, $value, $getFieldFromRecord) = @_;

    my $pattern = $rule->{pattern};
    my $rawReplacement = $rule->{replacement};
    my $flags = $rule->{flags} || "";
    my $res = $value;

    my $replacement = substituteReplacement($rawReplacement, $getFieldFromRecord);

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
   my($raw, $getFieldFromRecord) = @_;

    my $res = '';
    while ($raw =~ /(.*?)\%\{(.*?)\}(.*)/) {
	my($pre, $fieldname, $post) = ($1, $2, $3);
	# warn "pre='$pre', fieldname='$fieldname', post='$post'";
	$res .= $pre . &$getFieldFromRecord($fieldname);
	$raw = $post;
    }
    $res .= $raw;

    return $res;
}


use Exporter qw(import);
our @EXPORT_OK = qw(transform applyRule applyStripDiacritics applyRegsub);


1;
