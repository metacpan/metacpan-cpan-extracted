#!/usr/bin/env perl

#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic-Compatibility/xt/author/pod_coverage.t $
#     $Date: 2008-05-09 10:51:28 -0500 (Fri, 09 May 2008) $
#   $Author: clonezone $
# $Revision: 2333 $

use 5.006;

use strict;
use warnings;

use version; our $VERSION = qv('v1.1');

use Test::More;
use Test::Pod::Coverage;

my @trusted_methods = qw<
    initialize_if_enabled
    violates
    applies_to
    default_themes
    default_severity
    supported_parameters
>;

my $method_string = join q< | >, @trusted_methods;
my $regex = qr< \A (?: $method_string ) \z >xms;
all_pod_coverage_ok( { trustme => [$regex] } );

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
