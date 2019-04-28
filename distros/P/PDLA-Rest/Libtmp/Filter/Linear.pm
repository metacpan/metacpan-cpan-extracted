=head1 NAME

PDLA::Filter::Linear - linear filtering for PDLA

=head1 SYNOPSIS

	$x = new PDLA::Filter::Linear(
		{Weights => $v,
		 Point => 10});

	$y = new PDLA::Filter::Gaussian(15,2); # 15 points, 2 std devn.

	($pred,$corrslic) = $x->predict($dat);

=head1 DESCRIPTION

A wrapper for generic linear filters.
Just for convenience. This should in the future use DataPresenter.

Also, this class should at some point learn to do FFT whenever it is
useful.

=cut

package PDLA::Filter::Linear;
use PDLA;
use PDLA::Basic;
use PDLA::Slices;
use PDLA::Primitive;
use strict;

sub new($$) {
	my($type,$pars) = @_;

	my $this = bless {},$type;
        barf("Must specify weights\n") unless defined $pars->{Weights};
	$this->{Weights} = delete $pars->{Weights};
	$this->{Point} = defined $pars->{Point} ? $pars->{Point} : 0;
	$this;
}

sub predict($$) {
	my($this,$data) = @_;
	my $ldata = $data->lags(0,1,$this->{Weights}->getdim(0));
	inner($ldata->xchg(0,1),$this->{Weights},
		(my $pred = PDLA->null));
	return wantarray ?  ($pred,$ldata->slice(":,($this->{Point})")) :
		$pred ;
}

package PDLA::Filter::Gaussian;
use PDLA; use PDLA::Basic; use PDLA::Slices; use PDLA::Primitive;
use strict;

@PDLA::Filter::Gaussian::ISA = qw/PDLA::Filter::Linear/;

sub new($$) {
	my($type,$npoints,$sigma) = @_;
	my $cent = int($npoints/2);
	my $x = ((PDLA->zeroes($npoints )->xvals) - $cent)->float;
	my $y = exp(-($x**2)/(2*$sigma**2));
# Normalize to unit total
	$y /= sum($y);
	return PDLA::Filter::Linear::new($type,{Weights => $y,
			Point => $cent});
}

# Savitzky-Golay (see Numerical Recipes)
package PDLA::Filter::SavGol;
use PDLA; use PDLA::Basic; use PDLA::Slices; use PDLA::Primitive;
use strict;

@PDLA::Filter::Gaussian::ISA = qw/PDLA::Filter::Linear/;

# XXX Doesn't work
sub new($$) {
	my($type,$deg,$nleft,$nright) = @_;
	my $npoints = $nright + $nleft + 1;
	my $x = ((PDLA->zeroes($npoints )->xvals) - $nleft)->float;
	my $mat1 = ((PDLA->zeroes($npoints,$deg+1)->xvals))->float;
	for(0..$deg-1) {
		(my $tmp = $mat1->slice(":,($_)")) .= ($x ** $_);
	}
	my $y;
# Normalize to unit total
	return PDLA::Filter::Linear::new($type,{Weights => $y,
			Point => $nleft});
}


