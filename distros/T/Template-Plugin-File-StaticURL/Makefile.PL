use inc::Module::Install::DSL;

all_from lib/Template/Plugin/File/StaticURL.pm
requires Template
requires File::Spec::Functions
test_requires Test::More

