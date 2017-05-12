use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Physics::Particles',
   dist_author => 'Steffen Mueller <physpart-module at steffen-mueller dot net>',
   license => 'perl',
   requires => {
                'Data::Dumper' => '0',
               },
   recommends => {
                  'Test::Pod' => '1.0',
                  'Test::Pod::Coverage' => '1.0',
				  'Math::Project3D' => '0',
				  'Math::Project3D::Plot' => '0',
                 },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
   sign => 1,
   conflicts => {
	   'Physics::Springs' => '<1.0',
	   'Physics::Springs::Friction' => '<1.0',
	   },
#   script_files => [],
  );

$b->create_build_script;

