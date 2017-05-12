use inc::Module::Install::DSL 1.01;

all_from              lib/Oz.pm
requires_from         lib/Oz/Script.pm
requires_from         lib/Oz/Compiler.pm
test_requires         File::Spec 0.80
test_requires         Test::More 0.42
requires_external_bin ozc
requires_external_bin ozengine
