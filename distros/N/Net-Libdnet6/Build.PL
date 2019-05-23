#
# $Id: Build.PL,v 5d2ddfcb5b90 2015/01/28 18:59:42 gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Net::Libdnet6',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/Libdnet6.pm',
   requires => {
      'perl' => '5.6.1',
      'Net::Libdnet' => '0',
      'Net::IPv6Addr' => '0',
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
