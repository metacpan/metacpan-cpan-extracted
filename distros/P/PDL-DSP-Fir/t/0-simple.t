# -*-Perl-*-

use strict;
use warnings;
use Test::More;
use Test::PDL;

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::DSP::Fir::Simple qw( filter testdata);

my $L = 1001;
my $x = testdata($L, [.01, .1, .4], [1, ,.1, .05]);

# 1
is_pdl $x->sum, pdl(0);

my $fc = .05;

my $fclo = .05;
my $fchi = .15;

my $xlo = filter($x, { fc => $fc } );
my $xhi = filter($x, { fc => $fc , type => 'highpass' } );
is_pdl max($x - $xlo - $xhi),pdl(0), 'sum of lowpass and highpass is original signal';

my $xbp = filter($x, { fclo => $fclo, fchi => $fchi, type => 'bandpass' } );
my $xbs = filter($x, { fclo => $fclo , fchi => $fchi,  type => 'bandstop' } );

is_pdl max($x - $xbp - $xbs),pdl(0), 'sum of bandpass and bandreject is original signal';

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
