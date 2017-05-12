# Makefile.PL -- Makefile for tt2site	-*-perl-*-
# Author          : Johan Vromans
# Created On      : Tue Nov 30 18:37:07 2004
# Last Modified By: Johan Vromans
# Last Modified On: Wed Jan  5 21:20:58 2005
# Update Count    : 104
# Status          : Experimental

use strict;
use Module::Build 0.2606;
use File::Find;

our $data = {};
require "build_common.pl";

# Warn on non-standard install locations.
checkbin(<<EOD);
Please consult section "How Installation Paths are Determined"
of the Module::Build documentation section if you want to change
this location.
EOD

# 'ttree' should be in path.
checkexec("ttree");

my $build = Module::Build->new
  (
   dist_name	 => $data->{distname},
   dist_version	 => $data->{version},
   license	 => 'perl',
   requires	 => $data->{prereq_pm},
   recommends	 => $data->{recomm_pm},
   script_files	 => $data->{scripts},
   pm_files      => filelist("lib"),
  );

$build->create_build_script;
