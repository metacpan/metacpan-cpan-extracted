use inc::Module::Install::DSL 0.88;

all_from      lib/ORDB/CPANTesters.pm
requires_from lib/ORDB/CPANTesters.pm
test_requires Test::More  0.42
test_requires LWP::Online 1.07
