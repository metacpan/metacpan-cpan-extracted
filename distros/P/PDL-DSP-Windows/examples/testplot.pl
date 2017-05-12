#!/usr/bin/env perl
use strict;
use warnings;
use PDL;
use PDL::DSP::Windows;

new PDL::DSP::Windows(50,'hamming')->plot->plot_freq;
