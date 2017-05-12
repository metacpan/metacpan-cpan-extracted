use inc::Module::Install::DSL 1.04;

all_from      lib/SMS/Send.pm
requires_from lib/SMS/Send.pm
requires      Params::Util      1.00
requires      Class::Adapter    1.05
requires      Module::Pluggable 3.7
test_requires File::Spec        0.80
test_requires Test::More        0.47
