use strict;
use warnings;

use inc::Module::Install;

name				'RDF-EARL';
all_from			'lib/RDF/EARL.pm';
author				'Gregory Todd Williams <gwilliams@cpan.org>';
license				'perl';

build_requires		'Test::More'				=> 0.88;
build_requires		'Test::Exception'			=> 0;

perl_version		'5.008003';

requires			'Scalar::Util'				=> 0;
requires			'RDF::Trine'				=> 1.0;

resources(
	'homepage'   => "http://search.cpan.org/dist/RDF-EARL/",
	'repository' => "http://github.com/kasei/perlrdf/",
	'bugtracker' => "https://github.com/kasei/perlrdf/issues"
);

author_tests('xt');

sign;

WriteAll;
