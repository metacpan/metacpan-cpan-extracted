use inc::Module::Install;

license			'perl';

name                    'RDF-Trine-Node-Literal-XML';
author	                'Kjetil Kjernsmo <kjetilk@cpan.org>';
version_from        	'lib/RDF/Trine/Node/Literal/XML.pm';
abstract_from       	'lib/RDF/Trine/Node/Literal/XML.pm';
readme_from       	'lib/RDF/Trine/Node/Literal/XML.pm';

test_requires		'Test::More'				=> '0.88';
test_requires		'Test::Exception'			=> 0;
test_requires		'Test::NoWarnings'			=> 0;

configure_requires     	'XML::LibXML'				=> 0;
configure_requires     	'Carp'				        => 0;

requires 		'RDF::Trine'				=> 0.111;
requires		'Scalar::Util'				=> 0;
requires		'XML::LibXML'				=> 0;
requires		'Error'					=> 0;

author_tests('xt');

use XML::LibXML;
use Carp;
croak "You need libxml2 of at least 2.6.27 for canonicalisation to work properly" unless (XML::LibXML::LIBXML_VERSION >= 20627);

auto_set_repository;
auto_set_bugtracker;


write_doap_changes;

sign;

WriteAll;
