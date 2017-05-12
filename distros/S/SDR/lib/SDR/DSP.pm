package SDR::DSP;

use common::sense;
use PDL::DSP::Fir::Simple;


sub upsample {
  my ($signal, $n) = @_;

  return $signal->reshape($signal->getdim(0), $n)->transpose->flat;
}

sub downsample {
  my ($signal, $n) = @_;

  return $signal->slice([0, -1, $n]);
}


sub interpolate {
  my ($signal, $n, $fir_args) = @_;

  $signal = upsample($signal, $n);

  $signal = PDL::DSP::Fir::Simple::filter($signal, $fir_args);

  return $signal;
}

sub decimate {
  my ($signal, $n, $fir_args) = @_;

  $signal = PDL::DSP::Fir::Simple::filter($signal, $fir_args);

  $signal = downsample($signal, $n);

  return $signal;
}


1;
