use inc::Module::Install::DSL 1.04;

all_from      lib/ORDB/CPANUploads.pm
requires_from lib/ORDB/CPANUploads.pm
test_requires Test::More  0.42
test_requires LWP::Online 1.07
