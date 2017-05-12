#!/usr/bin/env perl

use strict;
use warnings;

# PODNAME: graph-stepford.pl

our $VERSION = '1.01';

use Stepford::Grapher::CommandLine;
exit Stepford::Grapher::CommandLine->run;
