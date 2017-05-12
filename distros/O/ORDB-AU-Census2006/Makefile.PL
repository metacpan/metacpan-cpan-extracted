use inc::Module::Install::DSL 0.90;

all_from      lib/ORDB/AU/Census2006.pm
requires_from lib/ORDB/AU/Census2006.pm
test_requires Test::More  0.42
test_requires LWP::Online 1.07
