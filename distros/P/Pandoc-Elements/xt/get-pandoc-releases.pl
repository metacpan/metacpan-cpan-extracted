#!/usr/bin/env perl
use v5.10;
use strict;

use lib 'xt/lib';
use Pandoc::Releases;

Pandoc::Releases::download_debian();
