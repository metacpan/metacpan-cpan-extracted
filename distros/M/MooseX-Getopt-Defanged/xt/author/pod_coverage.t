#!/usr/bin/env perl

use 5.008004;
use utf8;

use strict;
use warnings;

use version; our $VERSION = qv('v1.18.0');

use Test::More;
use Test::Pod::Coverage;

my @modules = grep { not m/ :_ /xms } all_modules('lib');

plan tests => scalar @modules;

foreach my $module (@modules) {
    pod_coverage_ok(
        $module,
        {
            also_private => [ qw< init_meta register_implementation >, ],
            trustme      => [ qr< \A description | Fields \z >xms ],
        }
    );
} # end foreach

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
