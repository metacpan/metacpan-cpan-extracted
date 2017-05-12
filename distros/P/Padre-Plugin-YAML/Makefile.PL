use inc::Module::Install::DSL 1.06;

all_from lib/Padre/Plugin/YAML.pm
requires_from lib/Padre/Plugin/YAML.pm

perl_version 5.010001

requires Padre     0.98
requires Try::Tiny 0.18
requires YAML      0.84 if win32
requires YAML::XS  0.41 if !win32
requires constant  1.27
requires if        0.04
requires parent    0.228

test_requires Test::More     0.98
test_requires Test::Requires 0.07

recommends ExtUtils::MakeMaker   6.78
recommends File::Spec::Functions 3.4
recommends List::Util            1.32
recommends Test::Pod             1.48
recommends Test::Pod::Coverage   1.08

no_index directory qw{ inc share t xt }

homepage   http://padre.perlide.org/trac/wiki/PadrePluginYAML
bugtracker http://padre.perlide.org
repository http://svn.perlide.org/padre/trunk/Padre-Plugin-YAML

install_share

