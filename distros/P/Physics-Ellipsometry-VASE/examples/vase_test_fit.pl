use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Math;
use Physics::Ellipsometry::VASE;
use PDL::Constants qw(PI);
use FindBin;

# Create VASE object with 1 layer
my $vase = Physics::Ellipsometry::VASE->new(layers => 1);

# Load sample data
my $data_file = "$FindBin::Bin/../data/Metal_Oxides/tantalum oxide/Cap_11012006/w1_11012006.dat";
$vase->load_data($data_file);

# Define model function (linear model example)
sub model {
    my ($params, $x) = @_;
    
    # Unpack parameters
    my $a = $params->(0);
    my $b = $params->(1);
    my $c = $params->(2);
    my $d = $params->(3);
    
    # Compute linear model (using only wavelength)
    my $wavelength = $x->(:,0);   # first column: wavelength
    # Note: $x->(:,1) contains angle (available for more complex models)

    my $psi = $a - $b * $wavelength;
    my $delta = $c + $d * $wavelength;
    
    return cat($psi, $delta)->flat;
}

sub cauchy_model {
	my ($params, $x) = @_;
	
	# Fit parameters: [A, B_scaled, n2, d]
	# B_scaled = B / 1e4 so all params are order ~1
	my $a  = $params->(0);
	my $b  = $params->(1) * 1e4;  # rescale B back to nm^2
	my $n2 = $params->(2);        # substrate index
	my $d  = $params->(3);        # thickness [nm]
	
	# Fixed values
	my $n0 = 1.0;    # ambient (air)
	my $c  = 0.0;    # Cauchy C-term (negligible for most films)
	
	# 
	# Unpack independent vars
	#
	my $lambda = $x->(:,0); # wavelength [nm]
	my $theta0 = $x->(:,1) * (PI / 180.0); # incident angle [radians]
	
	#
	# Film refractive index from Cauchy
	#
	my $n1 = $a + $b / ($lambda**2) + $c / ($lambda**4);
	
	#
	# Snell's law (clamp to avoid NaN from asin during fitting)
	#
	my $sin_theta1 = $n0 * sin($theta0) / $n1;
	$sin_theta1 = $sin_theta1->clip(-0.999, 0.999);
	my $theta1 = asin($sin_theta1);
	
	my $sin_theta2 = $n0 * sin($theta0) / $n2;
	$sin_theta2 = $sin_theta2->clip(-0.999, 0.999);
	my $theta2 = asin($sin_theta2);
	
	#
	# Phase thickness beta
	# beta = (2*PI / lambda) n1 d cos theata1
	#
	my $beta = (2 * PI / $lambda) * $n1 * $d * cos($theta1);
	
	# 
	# Fresnel coefficients
	#
	
	# Air/film
	my $r01s = ($n0*cos($theta0) - $n1*cos($theta1))
             / ($n0*cos($theta0) + $n1*cos($theta1));
             
	my $r01p = ($n1*cos($theta0) - $n0*cos($theta1))
		     / ($n1*cos($theta0) + $n0*cos($theta1));
		     
	# Film/substrate
	my $r12s = ($n1*cos($theta1) - $n2*cos($theta2))
			 / ($n1*cos($theta1) + $n2*cos($theta2));
			 
	my $r12p = ($n2*cos($theta1) - $n1*cos($theta2))
	         / ($n2*cos($theta1) + $n1*cos($theta2));
	         
	# 
	# Thin-film Fresnel reflectances
	# r = (r01 + r12 exp(-2 i beta)) / (1 + r01 r12 exp(-2 i beta))
	#

	my $phase = exp(-2*i()*$beta);
	my $rs = ($r01s + $r12s*$phase) / (1 + $r01s*$r12s*$phase);
	my $rp = ($r01p + $r12p*$phase) / (1 + $r01p*$r12p*$phase);

	#
	# Ellipsometric ratio
	#
	my $rho = $rp / $rs;

	# 
	# Psi and Delta
	#

	my $psi = atan( abs($rho) ) * (180.0 / PI); # tan(psi) = |rp/rs|, convert to degrees
	my $delta = carg($rho) * (180.0 / PI);       # delta = phase(rp/rs), convert to degrees

	return cat($psi->re, $delta->re)->flat->double;
	
}

# $vase->set_model(\&model);
$vase->set_model(\&cauchy_model);

# Initial parameters: [a, b, c, d] for linear model (exact solution for sample data)
# my $initial_params = pdl [65, 0.05, 80, 0.1];
# Cauchy params: [A, B_scaled, n_substrate, thickness(nm)]
# B_scaled = B/1e4 so all params are similar magnitude
# Ta2O5 typical: A~2.06, B~10000-20000 nm^2
my $initial_params = pdl [2.06, 1.5, 3.87, 100.0];

# Perform fit
my $fit_params = $vase->fit($initial_params);

# Extract results
my ($a, $b_scaled, $n2, $d) = list $fit_params;
my $b = $b_scaled * 1e4;
print "Fit results:\n";
printf "  Cauchy A:       %.6f\n", $a;
printf "  Cauchy B:       %.2f nm^2\n", $b;
printf "  n_substrate:    %.4f\n", $n2;
printf "  Thickness:      %.2f nm\n", $d;
printf "  Iterations:     %d\n", $vase->{iters};
print "\n  n(lambda) = $a + $b / lambda^2\n";

# Plot fit vs data — save to PNG
$vase->plot($fit_params,
    output => "$FindBin::Bin/cauchy_fit.png",
    title  => 'Ta_2O_5 Cauchy Fit — w1\_11012006',
);
