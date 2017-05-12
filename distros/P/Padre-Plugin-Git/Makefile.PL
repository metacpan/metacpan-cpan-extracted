use inc::Module::Install::DSL 1.06;

all_from lib/Padre/Plugin/Git.pm
requires_from lib/Padre/Plugin/Git.pm
requires_from lib/Padre/Plugin/Git/Output.pm
requires_from lib/Padre/Plugin/Git/Message.pm

perl_version 5.010001

requires CPAN::Changes 0.23
requires Carp          1.32
requires File::Slurp   9999.19
requires File::Spec    3.4
requires File::Which   1.09
requires Padre         0.98
requires Pithub        0.0102
requires Try::Tiny     0.18
requires constant      1.27
requires parent        0.227

test_requires Test::Deep    0.11
test_requires Test::More    0.98
test_requires Test::Requires 0.07

recommends ExtUtils::MakeMaker   6.76
recommends File::Spec::Functions 3.4
recommends List::Util            1.32
recommends Test::Pod             1.48
recommends Test::Pod::Coverage   1.08

homepage    http://padre.perlide.org/trac/wiki/PadrePluginGit
bugtracker  https://github.com/PadreIDE/Padre-Plugin-Git/issues
repository  https://github.com/PadreIDE/Padre-Plugin-Git.git

install_share

no_index directory qw{ share t }

