use inc::Module::Install;

name           'Number-WithError-LaTeX';
all_from       'lib/Number/WithError/LaTeX.pm';
requires       'Params::Util'            => '0.10';
requires       'prefork'                 => '1.00';
requires       'Math::BigFloat'          => '0';
requires       'Number::WithError'       => '0.08';
requires       'TeX::Encode'             => '0.4';

build_requires 'Test::More'              => '0.47';
build_requires 'Test::LectroTest'        => '0';

WriteAll();
