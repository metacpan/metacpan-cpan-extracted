use lib '.';
use inc::Module::Install::DSL 0.86;

all_from      lib/PPI/XS.pm
requires      PPI        1.000
test_requires File::Spec 0.82
test_requires Test::More 0.47
ppport
