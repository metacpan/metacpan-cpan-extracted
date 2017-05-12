use inc::Module::Install::DSL 1.00;

all_from      lib/PITA/Scheme.pm
requires      File::Temp       0
requires      File::Spec       0.80
requires      File::pushd      0.99
requires      File::Which      0.05
requires      IPC::Run3        0.036
requires      Data::GUID       0.045
requires      Params::Util     0.23
requires      Archive::Extract 0.18
requires      Process          0.16
requires      PITA::XML        0.43
test_requires Module::Build    0.28
test_requires Cwd              0
test_requires Test::More       0.47
test_requires File::Remove     1.42
