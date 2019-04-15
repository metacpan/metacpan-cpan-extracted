
use strict;
use warnings;

use PDLA;
use PDLA::Image2D;
use PDLA::FFT;
use PDLA::IO::FITS;

use Test::More tests => 17;
use Test::Exception;

sub tapprox {
        my($pa,$pb) = @_;
	all approx $pa, $pb, 0.01;
}

my ( $pa, $pb, $pc, $pi, $pk, $kk );

foreach my $type(double,float){
  $pa = pdl($type,1,-1,1,-1);
  $pb = zeroes($type,$pa->dims);
  fft($pa,$pb);
  ok(all($pa==pdl($type,0,0,4,0))); #1,3
  ifft($pa,$pb);
  ok(all($pa==pdl($type,1,-1,1,-1))); #2,4
}

$pk = ones(5,5);
$pa = rfits("m51.fits");

$pb = $pa->copy;
$pc = $pb->zeroes;
fft($pb,$pc);
ifft($pb,$pc);
ok (tapprox($pc,0)); #5

#print "\n",$pc->info("Type: %T Dim: %-15D State: %S"),"\n";
#print "Max: ",$pc->max,"\n";
#print "Min: ",$pc->min,"\n";
   
ok (tapprox($pa,$pb)); #6

$pb = $pa->copy;
$pc = $pb->zeroes; fftnd($pb,$pc); ifftnd($pb,$pc);
ok ( tapprox($pc,0) ); #7
ok ( tapprox($pa,$pb) );#8

$pb = $pa->slice("1:35,1:69");
$pc = $pb->copy; fftnd($pb,$pc); ifftnd($pb,$pc);
ok ( tapprox($pc,$pb) );#9
ok ( tapprox($pa->slice("1:35,1:69"),$pb) );#10

# Now compare fft convolutions with direct method

$pb = conv2d($pa,$pk);
$kk = kernctr($pa,$pk);
fftconvolve( $pi=$pa->copy, $kk );

ok ( tapprox($kk,0) );#11
ok ( tapprox($pi,$pb) );#12

$pk = pdl[
 [ 0.51385498,  0.17572021,  0.30862427],
 [ 0.53451538,  0.94760132,  0.17172241],
 [ 0.70220947,  0.22640991,  0.49475098],
 [ 0.12469482, 0.083892822,  0.38961792],
 [ 0.27722168,  0.36804199,  0.98342896],
 [ 0.53536987,  0.76565552,  0.64645386],
 [ 0.76712036,   0.7802124,  0.82293701]
];
$pb = conv2d($pa,$pk);

$kk = kernctr($pa,$pk);
fftconvolve( $pi=$pa->copy, $kk );

ok ( tapprox($kk,0) );#13
ok ( tapprox($pi,$pb) );#14

$pb = $pa->copy;

# Test real ffts
realfft($pb);
realifft($pb);
ok( tapprox($pa,$pb) );#15

# Test that errors are properly caught
throws_ok {fft(sequence(10))}
qr/Did you forget/, 'fft offers helpful message when only one argument is supplied'; #16


throws_ok {ifft(sequence(10))}
qr/Did you forget/, 'ifft offers helpful message when only one argument is supplied'; #17

# End
