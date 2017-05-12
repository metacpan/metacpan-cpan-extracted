use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Physics::Springs',
   dist_author => 'Steffen Mueller <springs-module at steffen-mueller dot net>',
   license => 'perl',
   requires => {
                'Physics::Particles' => '1.00',
				'Sub::Assert' => '0',
				'Data::Dumper' => '0',
				  'perl' => '5.006',
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
	   'Physics::Particles' => '<1.0',
	   'Physics::Springs::Friction' => '<1.0',
	},
#   script_files => [],
  );

$b->create_build_script;

