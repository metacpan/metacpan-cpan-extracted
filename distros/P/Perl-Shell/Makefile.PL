use inc::Module::Install::DSL 0.91;

all_from       lib/Perl/Shell.pm
requires_from  lib/Perl/Shell.pm
build_requires Test::More           0.42
build_requires Test::Script         1.07
install_script perlcmd
