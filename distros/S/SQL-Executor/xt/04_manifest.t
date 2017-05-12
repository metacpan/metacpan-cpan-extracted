#!/usr/bin/perl
use strict;
use warnings;

use Test::CheckManifest;

ok_manifest({ filter => [qr/\AMYMETA\./ms] });
