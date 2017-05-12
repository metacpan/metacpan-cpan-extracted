use inc::Module::Install::DSL 1.04;

all_from      lib/ORLite/Migrate.pm
requires_from lib/ORLite/Migrate.pm
requires      File::pushd  1.00
requires      IPC::Run3    0.042
requires      Probe::Perl  0.01
requires      File::Which  1.07
requires      Params::Util 0.37
test_requires Test::More   0.47
