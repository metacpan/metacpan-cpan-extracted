use inc::Module::Install::DSL 1.01;

all_from       lib/ORLite/Pod.pm
requires_from  lib/ORLite/Pod.pm
test_requires  Test::More          0.47
test_requires  Test::Script        1.07
test_requires  Test::XT            0.02
test_requires  Test::Pod           1.42
test_requires  Test::Pod::Coverage 1.08
test_requires  File::Remove        1.42
test_requires  File::pushd         1.00
test_requires  autodie             2.10
install_script orlite2pod
