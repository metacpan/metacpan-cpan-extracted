#!/usr/bin/env perl

use strict;
use warnings;

use PDL;
use PDL::DSP::Windows;

PDL::DSP::Windows->new( 50, 'hamming' )->plot_freq;
