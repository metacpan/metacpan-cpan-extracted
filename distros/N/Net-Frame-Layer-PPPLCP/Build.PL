#
# $Id: Build.PL 5 2015-01-14 06:47:16Z gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Net::Frame::Layer::PPPLCP',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/Frame/Layer/PPPLCP.pm',
   requires => {
      'perl' => '5.6.1',
      'Net::Frame' => '0',
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
