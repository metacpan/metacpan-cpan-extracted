#
# $Id: Build.PL 20 2015-01-13 18:34:19Z gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Net::Frame::Layer::LLC',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/Frame/Layer/LLC.pm',
   requires => {
      'perl' => '5.6.1',
      'Net::Frame' => '0',
      'Bit::Vector' => '0',
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
