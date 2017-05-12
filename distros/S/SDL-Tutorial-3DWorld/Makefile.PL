use inc::Module::Install::DSL 1.00;

all_from       lib/SDL/Tutorial/3DWorld.pm
requires_from  lib/SDL/Tutorial/3DWorld.pm
test_requires  Test::More       0.82
test_requires  Test::Script     1.05
test_requires  Test::NoWarnings 1.00
install_script 3dworld
install_share
