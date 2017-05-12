#!/usr/bin/env perl
use warnings;
use strict;

use lib 'lib', '../WSSSIG/lib', '../XMLWSS/lib';

use Test::More tests => 6;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Test::More
    XML::Compile
    XML::Compile::Cache
    XML::Compile::SOAP
    XML::Compile::C14N
    XML::Compile::WSS
    XML::Compile::WSS::Signature
    Log::Report
   /;

foreach my $package (@show_versions)
{   eval "require $package";

    no strict 'refs';
    my $report
      = !$@    ? "version ". (${"$package\::VERSION"} || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

require_ok('Net::Domain::TMCH');
require_ok('Net::Domain::TMCH::CRL');
require_ok('Net::Domain::SMD');
require_ok('Net::Domain::SMD::Schema');
require_ok('Net::Domain::SMD::File');
require_ok('Net::Domain::SMD::RL');
