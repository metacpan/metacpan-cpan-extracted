use inc::Module::Install::DSL 0.91;

all_from      lib/ORLite/Array.pm
requires_from lib/ORLite/Array.pm
requires      File::Spec   3.2701 if winlike
requires      File::Remove 1.40
test_requires Test::More   0.47
test_requires Test::Script 1.06
repository http://github.com/pmakholm/orlite-unsliced-perl
