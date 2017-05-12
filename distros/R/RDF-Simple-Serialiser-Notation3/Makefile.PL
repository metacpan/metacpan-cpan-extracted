
# $Id: Makefile.PL,v 1.18 2009-07-04 14:50:07 Martin Exp $

use inc::Module::Install;

name('RDF-Simple-Serialiser-Notation3');
all_from('lib/RDF/Simple/Serialiser/N3.pm');
version(1.017);
license('perl');
abstract('Output RDF triples in Notation3 format');

requires(perl => 5);
requires('Data::Dumper');
test_recommends('Pod::Coverage');
test_requires('Test::Deep');
test_requires('Test::More');
test_recommends('Test::Pod');
test_recommends('Test::Pod::Coverage');
requires('RDF::Simple::Serialiser');
requires('Regexp::Common');

WriteAll;

__END__
