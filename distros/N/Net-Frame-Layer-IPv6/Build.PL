#
# $Id: Build.PL,v ee9a7f696b4d 2017/05/07 12:55:21 gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Net::Frame::Layer::IPv6',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/Frame/Layer/IPv6.pm',
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
