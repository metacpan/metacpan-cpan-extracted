package SVG::DOM2::Attribute::Metric;

use base "XML::DOM2::Attribute";

use strict;
use warnings;
use Carp;

sub new
{
	my ($proto, %opts) = @_;
	return $proto->SUPER::new(%opts);
}

sub serialise
{
	my ($self) = @_;
	my $result = $self->value.$self->unit;
	return $result;
}

sub deserialise
{
	my ($self, $metric) = @_;
	my ($value, $unit) = $metric =~ /^([\d\.]+)(.*)$/;
	$unit = $self->document->default_unit if not $unit;
	$self->{'value'} = $value;
	$self->{'unit'} = $unit;
	return $self;
}

sub value
{
	my ($self, %opts) = @_;
	# Output Format
	my $format  = $opts{'format'};
	# Input Value
	my $cvalue  = $self->{'value'};
	# Return plain if no formating
	return $cvalue if not defined $format;
	# Output dots per inch
	my $dpi = $opts{'dpi'} || $self->document->out_dpi;
	# Input dots per Inch
	my $cdpi    = $self->document->dpi;
	# Input Format
	my $cformat = $self->unit;
	return $cvalue if $cformat eq $format;
	# Output Value
	my $result  = $cvalue;
	warn "CURRENT: ($cvalue, $cdpi, $cformat) - ($dpi, $format)\n";
	if($cformat eq 'px') {
		if($dpi and $cdpi and $dpi != $cdpi) {
			$result /= ($cdpi / 100);
			$result *= ($dpi / 100);
		}
	}
	$result /= 100 and $cformat = 'cm' if $cformat eq 'm';
	$result *= 10 and $cformat = 'cm' if $cformat eq 'mm';
	$result /= 2.54 and $cformat = 'in' if $cformat eq 'cm';
	$result /= 12 and $cformat = 'in' if $cformat eq 'ft';
	$result *= $dpi if $cformat eq 'in';
	return $result if $format eq 'px';
#	my $in = $result / $dpi;
#	return $in if $format eq 'in';
#	return $in * 12 if $format eq 'ft';
#	my $cm = $in * 2.54;
#	return $cm if $format eq 'cm';
#	return $cm / 100 if $format eq 'm';
#	return $cm * 10 if $format eq 'mm';
}

sub unit
{
	my ($self) = @_;
	return $self->{'unit'};
}

return 1;
