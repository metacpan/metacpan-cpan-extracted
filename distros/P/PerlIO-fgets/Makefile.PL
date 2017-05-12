use strict;
use inc::Module::Install;

name           'PerlIO-fgets';
perl_version   '5.008001';
all_from       'lib/PerlIO/fgets.pm';
repository     'http://github.com/chansen/p5-perlio-fgets';

test_requires  'IO::File'        => '0';
test_requires  'Test::More'      => '0.47';
test_requires  'Test::HexString' => '0';
makemaker_args INC => '-I.';

requires_external_cc;

WriteAll;

