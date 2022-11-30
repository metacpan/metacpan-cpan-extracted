package Net::Z3950::FOLIO::PostProcess::OPAC;

use strict;
use warnings;
use utf8;

use Data::Dumper; $Data::Dumper::INDENT = 2;
use Net::Z3950::FOLIO::PostProcess::Transform qw(transform);


sub postProcessHoldings {
    my($cfg, $holdings) = @_;

    foreach my $holding (@$holdings) {
	processListOfFields($cfg, $holding, 0);
    }

    return $holdings;
}


sub processListOfFields {
    my($cfg, $list, $isItem) = @_;
    my $thisCfg = $cfg->{$isItem ? 'circulation' : 'holding' };

    my $getFieldFromRecord = sub {
	my($fieldname) = @_;

	# XXX maybe we should make a hash the first time we need to do this
	foreach (my $i = 0; $i < @$list; $i++) {
	    my $field = $list->[$i];
	    my($name, $value) = @$field;
	    if ($name eq $fieldname) {
		return $value;
	    }
	}

	return undef;
    };

    foreach (my $i = 0; $i < @$list; $i++) {
	my $field = $list->[$i];
	my($name, $value) = @$field;
	if (!$isItem && $name eq 'circulations') {
	    processListOfFields($cfg, $value->[0], 1) if @$value > 0;
	} else {
	    my $rule = $thisCfg->{$name};
	    if ($rule) {
		$field->[1] = transform($rule, $value, $getFieldFromRecord);
	    }
	}
    }
}


use Exporter qw(import);
our @EXPORT_OK = qw(postProcessHoldings);


1;
