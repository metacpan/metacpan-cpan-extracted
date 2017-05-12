#
# $Id: Build.PL 363 2014-11-30 11:23:39Z gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Net::Frame::Dump',
   license => 'artistic',
   dist_author => 'GomoR <gomor-cpan_at_gomor.org>',
   dist_version_from => 'lib/Net/Frame/Dump.pm',
   requires => {
      'perl' => '5.6.1',
      'Class::Gomor' => '1.00',
      'Net::Pcap' => '0.12',
      'Net::Frame' => 0,
      'Time::HiRes' => 0,
      'IO::Select' => 0,
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
