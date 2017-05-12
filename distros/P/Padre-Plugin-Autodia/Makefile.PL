use inc::Module::Install::DSL 1.06;

all_from lib/Padre/Plugin/Autodia.pm
requires_from lib/Padre/Plugin/Autodia.pm

perl_version 5.010001

requires Autodia       2.14
requires Carp          1.32
requires Cwd           3.4
requires Data::Printer 0.35
requires File::Spec    3.4
requires GraphViz      2.14
requires Padre         0.98
requires Try::Tiny     0.18
requires constant      1.27
requires parent        0.228

test_requires ExtUtils::MakeMaker     6.82
test_requires File::Spec::Functions   3.4
test_requires List::Util              1.35
test_requires Test::More              1.001002
test_requires Test::Pod               1.48
test_requires Test::Pod::Coverage     1.08
test_requires Test::Requires          0.07
test_requires Test::Software::License 0.002


homepage    http://padre.perlide.org/trac/wiki/PadrePluginAutodia
bugtracker  http://padre.perlide.org/trac/wiki/Tickets
repository  http://svn.perlide.org/padre/trunk/Padre-Plugin-Autodia/

install_share

no_index directory qw{ inc share t xt }
