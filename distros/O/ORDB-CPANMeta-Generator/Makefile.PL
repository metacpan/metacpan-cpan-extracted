use inc::Module::Install::DSL 1.06;

all_from       lib/ORDB/CPANMeta/Generator.pm
requires_from  lib/ORDB/CPANMeta/Generator.pm
test_requires  Test::More 0.42
install_script cpan-metadb
