use inc::Module::Install::DSL 0.99;

all_from      lib/Module/Manifest.pm
requires      File::Spec      0.80
requires      File::Basename  0
requires      Params::Util    0.10
test_requires Cwd             0
test_requires Test::More      0.42
test_requires Test::Warn      0.11
test_requires Test::Exception 0.27
no_index      directory       examples
