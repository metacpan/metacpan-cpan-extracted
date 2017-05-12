#
# $Id: Build.PL 23 2015-01-20 18:48:56Z gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Net::Frame::Layer::GRE',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/Frame/Layer/GRE.pm',
   requires => {
      'perl' => '5.6.1',
      'Net::Frame' => '0',
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
