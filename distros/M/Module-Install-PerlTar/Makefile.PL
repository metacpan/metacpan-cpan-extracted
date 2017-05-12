use inc::Module::Install::DSL 1.00;

all_from       lib/Module/Install/PerlTar.pm
requires       Archive::Tar       1.66
requires       IO::Compress::Gzip 2.005
requires       Module::Install    1.00
test_requires  Test::More         0.42

repository     http://svn.ali.as/cpan/trunk/Module-Install-PerlTar

recursive_author_tests xt

use_ptar
