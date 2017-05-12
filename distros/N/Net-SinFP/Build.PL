#
# $Id: Build.PL 2236 2015-02-15 17:03:25Z gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Net::SinFP',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Net/SinFP.pm',
   requires => {
      'perl' => '5.6.1',
      'Net::Packet' => '3.20',
      'Net::Packet::Target' => 0,
      'Class::Gomor' => 0,
      'DBIx::SQLite::Simple' => '0.33',
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
