# -*-Perl-*-

use strict;
use warnings;
use Test::More;

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::DSP::Fir::Simple qw( filter testdata);

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-10;
  my $diff = abs($a-$b);
  # use at to make it perl scalar
  ref $diff eq 'PDL' and $diff = $diff->at(0);
  return $diff < $eps;
}

my $L = 1001;
my $x = testdata($L, [.01, .1, .4], [1, ,.1, .05]);

# 1
ok( tapprox( $x->sum, 0 ) );

my $fc = .05;

my $fclo = .05;
my $fchi = .15;

my $xlo = filter($x, { fc => $fc } );
my $xhi = filter($x, { fc => $fc , type => 'highpass' } );
ok( tapprox(max($x - $xlo - $xhi),0), 'sum of lowpass and highpass is original signal');

my $xbp = filter($x, { fclo => $fclo, fchi => $fchi, type => 'bandpass' } );
my $xbs = filter($x, { fclo => $fclo , fchi => $fchi,  type => 'bandstop' } );

ok( tapprox(max($x - $xbp - $xbs),0), 'sum of bandpass and bandreject is original signal');

# Check interface for determining number of samples in kernel
my ($dat,$kern);
($dat,$kern) = filter($x, { fc => $fc } );
ok($kern->nelem == $x->nelem);

($dat,$kern) = filter($x, { fc => $fc , N => -1 } );
ok($kern->nelem == $x->nelem);

($dat,$kern) = filter($x, { fc => $fc , N => 100 } );
ok($kern->nelem == 100);


#my $fclo = .07;
#my $fchi = .15;
#my $xbp = filter($x, { fclo => $fclo, fchi => $fchi , type => 'bandpass' , win => 'blackman' , L => $L,
#              boundary => 'truncated'  } );

done_testing();
