use inc::Module::Install;

name 'Scalar-Random-PP';
all_from 'lib/Scalar/Random/PP.pm';
readme_from;
manifest_skip;
ack_xxx;

use_mousse 'Scalar::Random::PP::OO';

WriteAll;
