# Auxiliary program for target 'remotetest' (see Makefile.PL).
# This code is executed in the local machine

# Redefine them if needed
#our $makebuilder = 'Makefile:PL';
#our $build = 'touch lib/Parse/Eyapp/*; make';
#our $makebuilder_arg = ''; # s.t. like INSTALL_BASE=~/personalmodules
our $build_arg = '-i';       # arguments for "make"/"Build"

#our $build_test_arg = 'TEST_VERBOSE=1';

# This code will be executed in the remote servers
our %preamble = (
  beowulf => q{ $ENV{GRID_REMOTE_MACHINE} = "orion"; },
  orion   => q{ 
    $ENV{GRID_REMOTE_MACHINE} = "beowulf.pcg.ull.es"; 
  },
);

