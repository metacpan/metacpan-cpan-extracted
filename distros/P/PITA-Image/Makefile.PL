use inc::Module::Install::DSL 1.04;

all_from      lib/PITA/Image.pm
requires_from lib/PITA/Image.pm
requires      Data::GUID   0.045
requires      PITA::XML    0.50
requires      PITA::Scheme 0.43
test_requires Test::More   0.47
