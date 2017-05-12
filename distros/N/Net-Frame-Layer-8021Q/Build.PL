#
# $Id: Build.PL 10 2015-01-20 18:42:55Z gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Net::Frame::Layer::8021Q',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/Frame/Layer/8021Q.pm',
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
