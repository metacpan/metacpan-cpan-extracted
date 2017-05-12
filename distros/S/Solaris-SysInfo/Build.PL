use strict;
use warnings;

use Module::Build;

die "OS unsupported" unless $^O eq "solaris";

my $build = Module::Build->new
  (
   module_name => 'Solaris::SysInfo',
   PL_files    => {
                     'lib/Solaris/SysInfo/Constants.pm.PL' => 'lib/Solaris/SysInfo/Constants.pm',
                  },
   build_requires => {
                        'Test::More' => 0,
                     },
   license => 'perl',
   create_makefile_pl => 'passthrough',
   create_license => 1,
   create_readme  => 1,
  );
  
$build->create_build_script;
