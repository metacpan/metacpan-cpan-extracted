use Module::Build;
# See perldoc Module::Build for details of how this works
Module::Build->new ( 
  create_makefile_pl        => 1,
  module_name               => 'SDL::OpenGL::Cg',
  pm_files                  => {
    'lib/SDL/OpenGL/Cg.pm'  => 'lib/SDL/OpenGL/Cg.pm',
  },
  license                   => 'perl',
  extra_linker_flags        => '-lc -lGL -lGLU -lCg -lCgGL -lm',
  requires                  => {
    perl                    => '5.6.1',
    SDL                     => '1.20.3',
  },
  build_requires            => {
    Test::More              => '0.45',
  },
)->create_build_script;
