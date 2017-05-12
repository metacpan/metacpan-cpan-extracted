use inc::Module::Install::DSL 1.06;

all_from      lib/ORLite.pm
requires_from lib/ORLite.pm
requires      File::Temp   0.20
requires      File::Spec   3.2701 if winlike
requires      File::Remove 1.40
test_requires Test::More   0.47
test_requires Test::Script 1.06
