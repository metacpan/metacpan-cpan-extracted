#
# $Id: Build.PL,v 1cb4741af301 2015/10/01 16:57:42 gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Splunklib',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Splunklib.pm',
   requires => {
      'perl' => '5.6.1',
   },
   configure_requires => {
      'Module::Build' => 0,
      'Data::Dumper' => 0,
      'Text::CSV_XS' => 0,
      'URI::Escape' => 0,
   },
);

$builder->create_build_script;
