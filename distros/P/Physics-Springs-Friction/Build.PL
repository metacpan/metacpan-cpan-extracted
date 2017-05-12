use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Physics::Springs::Friction',
   dist_author => 'Steffen Mueller <friction-module at steffen-mueller dot net>',
   license => 'perl',
   requires => {
                'Physics::Particles' => '1.00',
                'Physics::Springs' => '1.00',
                'Data::Dumper' => '0',
				'Sub::Assert' => '0',
               },
   recommends => {
                  'Test::Pod' => '1.0',
                  'Test::Pod::Coverage' => '1.0',
                 },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
   sign => 1,
   conflicts => {
	   'Physics::Springs' => '<1.00',
	   'Physics::Particles' => '<1.00',
	   },
#   script_files => [],
  );

$b->create_build_script;

