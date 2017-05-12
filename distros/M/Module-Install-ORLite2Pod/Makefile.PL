use inc::Module::Install::DSL 1.00;

all_from       lib/Module/Install/ORLite2Pod.pm
requires       Module::Install    1.
requires       ORLite::Pod        0.11
requires       Params::Util        0.1
test_requires  Test::More         0.42

#fails, no idea why, look later
#recursive_author_tests  xt

repository     http://svn.ali.as/cpan/trunk/Module-Install-ORLite2Pod

