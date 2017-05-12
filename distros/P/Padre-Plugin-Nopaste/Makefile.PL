use inc::Module::Install::DSL 1.06;

perl_version 5.010001

all_from      lib/Padre/Plugin/Nopaste.pm
requires_from lib/Padre/Plugin/Nopaste.pm

requires App::Nopaste 0.92
requires Carp         1.32
requires Moo          1.003001
requires Padre        0.98
requires Try::Tiny    0.18
requires constant     1.27
requires parent       0.228

test_requires Test::More     0.98
test_requires Test::Requires 0.07

recommends ExtUtils::MakeMaker   6.78
recommends File::Spec::Functions 3.4
recommends List::Util            1.32
recommends Test::Pod             1.48
recommends Test::Pod::Coverage   1.08

homepage    http://padre.perlide.org/trac/wiki/PadrePluginNopaste
bugtracker  http://padre.perlide.org/trac
repository  http://svn.perlide.org/padre/trunk/Padre-Plugin-Nopaste/

no_index directory qw{ inc share t xt }

install_share

