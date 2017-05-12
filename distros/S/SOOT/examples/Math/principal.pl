use strict;
use warnings;
use SOOT ':all';

#  Principal Components Analysis (PCA) example
#  
#  Example of using TPrincipal as a stand alone class. 
#  
#  We create n-dimensional data points, where c = trunc(n / 5) + 1
#  are  correlated with the rest n - c randomly distributed variables. 
# 
my $n = shift || 10;
my $m = shift || 10000;

my $c = $n / 5 + 1;

printf "*************************************************\n";
printf "*         Principal Component Analysis          *\n";
printf "*                                               *\n";
printf "*  Number of variables:           %8d      *\n", $n;
printf "*  Number of data points:         %8d      *\n", $m;
printf "*  Number of dependent variables: %4d          *\n", $c;
printf "*                                               *\n";
printf "*************************************************\n"; 

# Initilase the TPrincipal object. Use the empty string for the
# final argument, if you don't wan't the covariance
# matrix. Normalising the covariance matrix is a good idea if your
# variables have different orders of magnitude. 

my $principal = TPrincipal->new($n,"N");

# Use a pseudo-random number generator
my $random = TRandom->new;

# Make the m data-points
# Make a variable to hold our data
# Allocate memory for the data point
my $data = [];
for my $i (0..$m-1) {

  # First we create the un-correlated, random variables, according
  # to one of three distributions 
  for my $j (0..($n-$c-1)) {
    if ($j % 3 == 0) {
      $data->[$j] = $random->Gaus(5,1);
    }
    elsif ($j % 3 == 1) {
      $data->[$j] = $random->Poisson(8);
    }
    else {
      $data->[$j] = $random->Exp(2);
    }
  }

  # Then we create the correlated variables
  for my $j (0..$c-1) {
    $data->[$n - $c + $j] = 0;
    for my $k (0..($n-$c-$j-1)) {
      $data->[$n - $c + $j] += $data->[$k];
    }
  }
  
  # Finally we're ready to add this datapoint to the PCA
  $principal->AddRow($data);
}
  
# Do the actual analysis
$principal->MakePrincipals();

# Print out the result on
$principal->Print();

# Test the PCA 
$principal->Test();

# Make some histograms of the orginal, principal, residue, etc data 
$principal->MakeHistograms();

# Make two functions to map between feature and pattern space 
$principal->MakeCode();

# Start a browser, so that we may browse the histograms generated
# above 
my $b = TBrowser->new("principalBrowser", $principal);

$gApplication->Run;

