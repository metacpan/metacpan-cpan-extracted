#!perl

use strict;
use warnings;

use Test::More;
use Test::Pod::Coverage;

my $standard_policy_methods =
    join
        ' | ',
        qw{
            new
            violates
            applies_to
            default_themes
            default_severity
            supported_parameters
        };
my $exemption_regex = qr/ \A (?: $standard_policy_methods ) \z /xms;

all_pod_coverage_ok( { trustme => [ $exemption_regex ] } );

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
