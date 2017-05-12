use inc::Module::Install::DSL 1.04;

all_from      lib/Process.pm
requires      IO::Handle   0
requires      IO::File     0
requires      IO::String   0
requires      File::Temp   0
requires      Storable     2.14
requires      YAML::Tiny   1.36
requires      List::Util   1.17
requires      Scalar::Util 1.17
requires      Params::Util 0.10
requires      IPC::Run3    0.034
requires      Probe::Perl  0.01
test_requires File::Spec   0.80
test_requires File::Remove 1.51
test_requires Test::More   0.47
