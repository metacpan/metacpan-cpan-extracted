package PDL::Demos::DSPWindows;

use PDL::Graphics::Simple;
use PDL::DSP::Windows;

sub info {('dsp_windows', 'DSP windowing (Req.: PDL::Graphics::Simple)')}

sub init {'
use PDL::Graphics::Simple;
'}

my @demo = (
[act => q|
# This demo illustrates the PDL::DSP::Windows module,
# which provides many window functions for digital signal processing

use PDL::DSP::Windows;
$w = pgswin(multi=>[1,2]); # PDL::Graphics::Simple window
|],

[act => q|
# The Hamming window
$dspw = PDL::DSP::Windows->new(50, 'hamming');
$dspw->plot($w); $dspw->plot_freq($w);
|],

[act => q|
# The "exact" Hamming window
$dspw = PDL::DSP::Windows->new(50, 'hamming_ex');
$dspw->plot($w); $dspw->plot_freq($w);
|],

[act => q|
# The Hann window
$dspw = PDL::DSP::Windows->new(50, 'hann');
$dspw->plot($w); $dspw->plot_freq($w);
|],

[act => q|
# The Welch window
$dspw = PDL::DSP::Windows->new(50, 'welch');
$dspw->plot($w); $dspw->plot_freq($w);
|],

[act => q|
# The Bartlett window
$dspw = PDL::DSP::Windows->new(50, 'bartlett');
$dspw->plot($w); $dspw->plot_freq($w);
|],

[comment => q|
This concludes the demo.

Be sure to check the documentation for PDL::DSP::Windows, to see further
possibilities.
|],
);

sub demo { @demo }
sub done {'
undef $w;
'}

1;
