#!/usr/bin/env perl
use strict;
use warnings;
use inc::latest;

#                        Module::Build
#                        ExtUtils::ParseXS
#                        ExtUtils::Typemap
#                        Alien::ROOT
#                        ExtUtils::XSpp
#                        ExtUtils::CBuilder
foreach my $module (qw(
                        Module::Build
                    ))
{
  inc::latest->bundle_module($module, 'inc');
}

