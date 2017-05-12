use inc::Module::Install::DSL 0.87;

all_from       lib/PPI/PowerToys.pm
requires_from  lib/PPI/App/ppi_version.pm
test_requires  Test::More   0.47
test_requires  Test::Script 1.03
test_requires  Probe::Perl  0.01
test_requires  IPC::Run3    0.034
install_script ppi_version
install_script ppi_copyright
