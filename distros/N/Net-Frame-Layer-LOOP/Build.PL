#
# $Id: Build.PL 4 2015-01-14 06:34:44Z gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Net::Frame::Layer::LOOP',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/Frame/Layer/LOOP.pm',
   requires => {
      'perl' => '5.6.1',
      'Net::Frame' => '0',
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
