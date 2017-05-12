#
# $Id: Build.PL,v fbb958f84d2f 2015/01/23 06:36:05 gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Net::Frame::Simple',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/Frame/Simple.pm',
   requires => {
      'perl' => '5.6.1',
      'Class::Gomor' => '1.00',
      'Net::Frame' => '0',
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
