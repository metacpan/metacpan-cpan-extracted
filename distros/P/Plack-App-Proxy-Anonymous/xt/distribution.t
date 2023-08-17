#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = '0.999_001';

require Test::Distribution;
Test::Distribution->import(distversion => 1, only => ['description', 'manifest']);
