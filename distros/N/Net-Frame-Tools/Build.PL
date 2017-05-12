#
# $Id: Build.PL 349 2015-01-23 06:44:44Z gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Net::Frame::Tools',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/Frame/Tools.pm',
   requires => {
      'perl' => '5.6.1',
      'Net::Write' => '1.00',
      'Net::Frame' => 0,
      'Net::Frame::Simple' => 0,
      'Net::Frame::Dump' => 0,
      'Net::Frame::Device' => 0,
      'Net::Netmask' => 0,
      'Term::ReadLine' => 0,
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
