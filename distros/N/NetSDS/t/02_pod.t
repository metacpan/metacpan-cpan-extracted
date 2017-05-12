#!/usr/bin/env perl
#===============================================================================
#
#         FILE:  02_pod.t
#
#  DESCRIPTION:  
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  13.07.2008 23:51:01 EEST
#     REVISION:  $Id: 02_pod.t 8 2008-07-13 21:11:35Z misha $
#===============================================================================

use strict;
use warnings;

use Test::More;                      # last test to print

# We need at least 1.14 version to check POD data
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;

all_pod_files_ok();

