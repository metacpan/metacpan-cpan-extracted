use inc::Module::Install::DSL 1.06;

all_from      lib/Padre/Plugin/SpellCheck.pm
requires_from lib/Padre/Plugin/SpellCheck.pm
requires_from lib/Padre/Plugin/SpellCheck/Checker.pm
requires_from lib/Padre/Plugin/SpellCheck/Engine.pm
requires_from lib/Padre/Plugin/SpellCheck/Preferences.pm

requires Class::Accessor 0.34
requires Encode          2.55
requires File::Which     1.09
requires Padre           0.98
requires Text::Aspell    0.09 if win32
requires Text::Hunspell  2.08 if !win32
requires Try::Tiny       0.18
requires constant        1.27
requires parent          0.227

test_requires Test::More     0.98
test_requires Test::Requires 0.07

recommends ExtUtils::MakeMaker   6.76
recommends File::Spec::Functions 3.4
recommends List::Util            1.32
recommends Test::Pod             1.48
recommends Test::Pod::Coverage   1.08

no_index directory qw{ inc share t xt }

homepage    http://padre.perlide.org/trac/wiki/PadrePluginSpellCheck
bugtracker  http://padre.perlide.org/trac
repository  http://svn.perlide.org/padre/trunk/Padre-Plugin-SpellCheck/

install_share
