use inc::Module::Install::DSL 1.04;

all_from      lib/Padre/Plugin/FormBuilder.pm
requires_from lib/Padre/Plugin/FormBuilder.pm
requires_from lib/Padre/Plugin/FormBuilder/Perl.pm
requires      Padre              0.93
test_requires Test::More         0.47
test_requires Test::NoWarnings   0.084
test_requires Test::LongString   0.10
install_share
