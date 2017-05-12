use inc::Module::Install::DSL 0.86;

all_from       lib/PPI/Tester.pm
requires       Devel::Dumpvar 0.04
requires       PPI            1.201
requires       Wx             0.54
test_requires  File::Spec     0.80
test_requires  Test::More     0.47
test_requires  Test::Script   1.02
install_script ppitester
