use inc::Module::Install;

name           'String-Fraction';
all_from       'lib/String/Fraction.pm';

requires       'HTML::Fraction'  => 0.40;

license 'perl';
githubmeta;
author_tests('xt');

WriteAll;
